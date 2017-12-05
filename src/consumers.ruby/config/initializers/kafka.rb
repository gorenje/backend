require 'kafka'
require_relative './host_handler'

opts = {
  :logger              => Logger.new($stderr),
  :seed_brokers        => ENV['CLOUDKARAFKA_BROKERS'].split(','),
  :ssl_ca_cert         => ENV['CLOUDKARAFKA_CA'],
  :ssl_client_cert     => ENV['CLOUDKARAFKA_CERT'],
  :ssl_client_cert_key => ENV['CLOUDKARAFKA_PRIVATE_KEY'],
}
opts[:logger].level = Logger::WARN if ENV['RACK_ENV'] == 'production'

$kafka = OpenStruct.new.tap do |os|
  ["geo", "kafidx", "chatbot", "bulkdata", "ebay", "notifier"].
    each do |client_id|
    os[client_id] = Kafka.new(opts.merge({:client_id => client_id}))
  end
end
