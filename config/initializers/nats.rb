#!/usr/bin/env ruby

require "nats/client"

# TODO: There should be a better integration pattern, I think?
module RailsNats
  Client = ::NATS.connect(ENV.fetch("NATS_URL"))
  JetStream = Client.jetstream
end
