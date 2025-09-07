desc "Create NATS jetstream"
task :create_jetstream do
  require_relative "../../config/initializers/nats.rb"
  RailsNats::JetStream.add_stream(name: "mystream", subjects: ["foo"])
end
