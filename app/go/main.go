package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	bigcache "github.com/allegro/bigcache/v3"
	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
)

// {"id":"06615b2b-5a67-4711-8695-9db08861ef39","target":"https://google.com","slug":"asdasd","created_at":"2025-09-09T14:18:40.817Z","updated_at":"2025-09-09T14:18:40.817Z"}
type Link struct {
	ID        string    `json:"id"`
	Target    string    `json:"target"`
	Slug      string    `json:"slug"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

func main() {
	// connect to nats server
	nc, err := nats.Connect(nats.DefaultURL)
	if err != nil {
		panic(err)
	}

	// create jetstream context from nats connection
	js, err := jetstream.New(nc)
	if err != nil {
		panic(err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// get existing stream handle
	stream, err := js.Stream(ctx, "ShortenedUrl_create")
	if err != nil {
		panic(err)
	}

	// create consumer
	cons, err := stream.CreateConsumer(ctx, jetstream.ConsumerConfig{
		AckPolicy: jetstream.AckExplicitPolicy,
	})
	if err != nil {
		panic(err)
	}

	cache, err := bigcache.New(context.Background(), bigcache.DefaultConfig(10*time.Minute))
	if err != nil {
		panic(err)
	}

	cc, err := cons.Consume(func(msg jetstream.Msg) {
		var link Link
		err := json.Unmarshal(msg.Data(), &link)
		if err != nil {
			fmt.Printf("Error parsing message: %v\n", err)
			msg.Nak()
			return
		}

		fmt.Printf("Received link: %+v\n", link)

		cache.Set(link.Slug, []byte(link.Target))
		msg.Ack()
	})
	if err != nil {
		panic(err)
	}
	defer cc.Stop()

	http.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		entry, err := cache.Get(r.URL.Path)
		if err == bigcache.ErrEntryNotFound {
			http.NotFound(w, r)
		} else if err != nil {
			panic(err)
		} else {
			// The HTTP 301 Moved Permanently redirection response status code indicates that the requested resource has been permanently moved to the URL in the Location header.

			// A browser receiving this status will automatically request the resource at the URL in the Location header, redirecting the user to the new page.
			// Search engines receiving this response will attribute links to the original URL to the redirected resource, passing the SEO ranking to the new URL.
			http.Redirect(w, r, string(entry), http.StatusMovedPermanently)
		}
	})

	log.Fatal(http.ListenAndServe(":8080", nil))

}
