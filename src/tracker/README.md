# Tracker

Endpoint for tracking events.

Very simple collector of events. These are stored in redis databases and
moved from there to kafka via the [kafkastore](../kafkastore).

HTTP requests are taken and stored verbatim in redis. Included is the user
agent of the request and IP. The kafkastore then does device detection
and geo location lookups, before pushing the events off to kafka.

The endpoint is very simple and takes [every request](routes/tracking.js#L8)
and converts it into an event. Only get calls are supported, no post
endpoints are provided.

Example:

    https://tracker-endpoint/path/fubar/event_type?param=1

any path is accepted, the last part of the path is assumed to be the
event type. All parameters are stored along with the user agent, request
IP and time of request.

All this is stored as a [space separated string](routes/tracking.js#L25-L32) in
redis. From there, the [kafkastore](../kafkastore) will retrieve events
and push them off to kafka.
