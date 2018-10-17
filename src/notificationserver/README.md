# Notification Server

Sends various push notifications out using [OneSignal](https://onesignal.com/).

Also does callbacks via webhooks.

## Testing

Best bet is to start the database server and redis server via docker
and then run rake test

    eval $(cat .env) ; docker-compose -f docker-compose/notificationserver.yml up

Then in a second window

    DATABASE_URL=postgres://postgres:somepassword@localhost:5432/notserver rake test

And the tests should be run.
