# Storage for Searches and Offers

MongoDB-based storage for offers and searches.

Also provides API endpoints for triggering match-notifications. That is, if
a search or offer is updated, then a search is done for matches, which in
turn trigger notifications.

Various external services trigger these:
- [consumers](../consumers.ruby/lib/kafka_consumers/geo.rb#L33) for geo
  location updates from users
- [consumers](../consumers.ruby/lib/kafka_consumers/bulkdata.rb#L35-L36)
  because of bulk updates of [offers](../offerserver/lib/base_importer.rb#L127)
- [website](../website/lib/store_helper.rb) by updating searches or offers.

All notifications go via the [notification server](../notificationserver),
it has the responsibility of using the right notification channel for the
user.

## Testing with Mocha

First install mocha globally:

    npm install -g mocha

then run

    mocha

and things should be tested.

For bonus points, setup mongo:

    MONGOHQ_URL=mongodb://heroku:....<use docker to start mongo> mocha

This should not change the live database, just use it.
