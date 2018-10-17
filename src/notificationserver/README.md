# Notification Server

Sends various push notifications out using [OneSignal](https://onesignal.com/)
and via webhooks to the [website](../website).

Clients [register](routes/register.rb) with the notification server.
The notification server maintains a mapping between device id and one signal
id and sendbird id. Clients are responsible for updating this mapping when
they register with sendbird or one signal.

Device Ids are the primary key for these mappings and clients can update
any or all of their details using that.

Also this provides an [endpoint](routes/sendbird.rb) for Sendbird callbacks
when messages are sent to a group chat. So that other members of the chat
are informed of new messages.

## Testing

Best bet is to start the database server and redis server via docker
and then run rake test

    eval $(cat .env) ; docker-compose -f docker-compose/notificationserver.yml up

Then in a second window

    DATABASE_URL=postgres://postgres:somepassword@localhost:5432/notserver rake test

And the tests should be run.
