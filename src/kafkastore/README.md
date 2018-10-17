# Kafka Store

The link between the [trackers](../tracker) that store incoming events
into their local redis instances and [kafka](../../docker-compose/kafka-zookeeper.yml).

Intention is that a single kafkastore retrieves the events from multiple
redis instances, i.e. trackers, and bulk-stores these into kafka. This way
the trackers are not pushing single events into kafka and can respond
faster.

In addition, the kafkastore does geo lookups for IPs and handles device
detections from user agent strings. It also reformats message stored
into kafka into a simple space-separated string, i.e. no JSON parsing
required for messages.
