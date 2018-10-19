# Components

Backend is made of these components:

1. [Storage](storage) is a mongo-based datastore for searches and
   offers. Mongo is good at doing geo matching, hence it was chosen as
   the datastore.

2. [Website](website) providing a simple home page and web-based
   Push service.

3. [Tracker](tracker) that ingests tracking events
   and pushes these to an redis instance. The intention is to have
   one redis per tracker instance, however this is not set in stone.
   Requests are considered fire-and-forget, meaning the client does not
   need to handle the response.

4. [Image server](imageserver) providing a store for images for offers
   and searches. Basically the same as a amazon bucket but with
   [image processing](imageserver/models/image_uploader.rb).

5. [Kafkastore](kafkastore) then takes those tracking calls from redis,
   does some magic ([geoIP lookup](kafkastore/lib/helpers.js#L25),
   [device detection](kafkastore/lib/helpers.js#L27) and reformatting of the
   message). It then does a batch insert into kafka. The tracker does not
   store directly into kafka because of the extra geoIP lookup and also
   because we want to batch tracking calls together before handing them off
   to kafka.

6. [Notification Server](notificationserver) for sending push notifications
   to the mobile application and also to the website. Notifications are sent
   via [OneSignal](https://onesignal.com/).

7. [Offer Server](offerserver) for generating seed offers of
   various things on the internet. All offer generators are
   [here](offerserver/lib/importers).

8. [Kafidx](kafidx) which is a simple web-socket based consumer
   which shows live tracking events as they come in. It is useful for debugging
   consumers and generally ensuring that events are going through the
   system.

9. [Nodejs consumers](consumers.nodejs) which just provide some
   statistical data.

10. [Ruby consumers](consumers.ruby) which trigger various actions
   when various events happen.

11. [NFS Server](imageserver.nfs) for providing data storage for the
   the imageserver. This was not possible using a persistent volume since
   these are bound to a single node in kubernetes. Instead the imageserver
   now connects to the NFS server that has the persistent volume.

12. [Kafka and Zookeeper](../docker-compose/kafka-zookeeper.yml) - just that!
