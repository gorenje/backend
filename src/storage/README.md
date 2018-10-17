# Storage for Searches and Offers

MongoDB-based storage for offers and searches. Provides API calls for
triggering notifications of matches.

## Testing with Mocha


First install mocha globally:

    npm install -g mocha

then run

    mocha

and things should be tested.

For bonus points, setup mongo:

    MONGOHQ_URL=mongodb://heroku:....<use docker to start mongo> mocha

This should not change the live database, just use it.
