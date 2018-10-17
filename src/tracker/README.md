# Tracker

Endpoint for tracking events.

Very simple collector of events. These are stored in redis databases and
moved from there to kafka via the [kafkastore](../kafkastore).

HTTP requests are taken and stored verbatim in redis. Included is the user
agent of the request and IP. The kafkastore then does device detection
and geo location lookups, before pushing the events off to kafka.
