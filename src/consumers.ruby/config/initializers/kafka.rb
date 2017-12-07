require 'kafka'
require_relative './host_handler'
require_relative './zookeeper'

opts = {
  :logger       => Logger.new($stderr),
  :seed_brokers => ZkClient.broker_list
}
opts[:logger].level = Logger::WARN if ENV['RACK_ENV'] == 'production'

$kafka = begin
           OpenStruct.new.tap do |os|
             ["geo", "kafidx", "chatbot", "bulkdata", "notifier"].
               each do |client_id|
               os[client_id] = Kafka.new(opts.merge({:client_id => client_id}))
             end
           end
         rescue Exception => e
           puts("Unable to configure Kafka Client: #{e}")
           OpenStruct.new
         end
