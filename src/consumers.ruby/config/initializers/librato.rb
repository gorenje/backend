require 'librato/metrics'
require 'librato-rack'

Librato::Metrics.authenticate(ENV['LIBRATO_USER'], ENV['LIBRATO_TOKEN'])

$librato_queue      ||= Librato::Metrics::Queue.new(
  :prefix              => (ENV['LIBRATO_PREFIX']||"consumers"),
  :autosubmit_interval => 60,
  :clear_failures      => true)

$librato_aggregator ||= Librato::Metrics::Aggregator.new(
  :prefix              => (ENV['LIBRATO_PREFIX']||"consumers"),
  :autosubmit_interval => 120,
  :clear_failures      => true)
