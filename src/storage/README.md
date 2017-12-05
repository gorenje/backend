Push Backend
----

Store for Offers and Searches.

Local Testing
---

    while [ 1 ] ; do NOTIFY_HOST=https://notify.pushtech.de MONGOHQ_URL=mongodb://heroku:....<get from heroku config> foreman start ; done

Done.

Testing with Mocha
---

First install mocha globally:

    npm install -g mocha

then run

    mocha

and things should be tested.

For bonus points, setup mongo:

    MONGOHQ_URL=mongodb://heroku:....<get from heroku config> mocha

This should not change the live database, just use it.
