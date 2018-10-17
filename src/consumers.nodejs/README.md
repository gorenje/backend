# Consumers - NodeJS

Kafka consumers for collecting statistical data. Data is persisted to a
Redis store and displyed by the [kafidx](../kafidx) server.

Data collected:

- [event types](lib/event_counter.js) - count the variuos event types.
- [metadata counter](lib/metadata_consumer.js) - count the IPs and countries
- [search counter](lib/search_counter.js) - show and count what users are searching for
- [timing stats](lib/stats_consumer.js) - display information on how long events are taking to go through kafka

This has no frontend, only a single running process consuming events.
