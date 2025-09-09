package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	badger "github.com/dgraph-io/badger/v4"
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

func CreateJetstream() (*jetstream.Consumer, error) {
	// connect to nats server
	nc, err := nats.Connect(nats.DefaultURL)
	if err != nil {
		return nil, err
	}

	// create jetstream context from nats connection
	js, err := jetstream.New(nc)
	if err != nil {
		return nil, err
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// get existing stream handle
	stream, err := js.Stream(ctx, "ShortenedUrl_create")
	if err != nil {
		return nil, err
	}

	// create consumer
	cons, err := stream.CreateConsumer(ctx, jetstream.ConsumerConfig{
		AckPolicy: jetstream.AckExplicitPolicy,
	})
	if err != nil {
		return nil, err
	}
	return &cons, nil
}

func CreateCache() (*badger.DB, error) {
	opt := badger.DefaultOptions("").WithInMemory(true)
	return badger.Open(opt)
}

func main() {
	cons, err := CreateJetstream()
	if err != nil {
		panic(err)
	}

	db, err := CreateCache()
	if err != nil {
		panic(err)
	}
	defer db.Close()

	cc, err := (*cons).Consume(func(msg jetstream.Msg) {
		var link Link
		err := json.Unmarshal(msg.Data(), &link)
		if err != nil {
			fmt.Printf("Error parsing message: %v\n", err)
			msg.Nak()
			return
		}

		fmt.Printf("Received link: %+v\n", link)

		err = db.Update(func(txn *badger.Txn) error {
			return txn.Set([]byte(link.Slug), []byte(link.Target))
		})
		if err != nil {
			fmt.Printf("Error saving message (%+v): %v\n", link, err)
			msg.Nak()
		} else {
			msg.Ack()
		}
	})
	if err != nil {
		panic(err)
	}
	defer cc.Stop()

	mux := http.NewServeMux()
	mux.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		err := db.View(func(txn *badger.Txn) error {
			item, err := txn.Get([]byte(r.URL.Path))
			if err != nil {
				return err
			}
			return item.Value(func(value []byte) error {
				http.Redirect(w, r, string(value), http.StatusMovedPermanently)
				return nil
			})
		})
		if err == badger.ErrKeyNotFound {
			http.NotFound(w, r)
		} else if err != nil {
			http.Error(w, "500 Internal Server Error", http.StatusInternalServerError)
		}
	})

	log.Fatal(http.ListenAndServe("127.0.0.1:3001", mux))

}
