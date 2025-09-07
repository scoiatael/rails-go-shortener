package main

import (
	"context"
	"fmt"
	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/jetstream"
	"time"
)

func main() {
	fmt.Println("hello world")
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

	// consume messages from the consumer in callback
	cc, err := cons.Consume(func(msg jetstream.Msg) {
		fmt.Println("Received jetstream message: ", string(msg.Data()))
		msg.Ack()
	})
	if err != nil {
		panic(err)
	}
	defer cc.Stop()

	// Start HTTP server here
	time.Sleep(time.Minute)
}
