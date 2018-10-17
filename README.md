# Pushtech Backend

Push provides a platform for matching searchers with offers, not unlike
google, amazon, ebay and co. What makes Push different is that it is
geo-location based. Meaning that searches and offers have a region defined
in which that can match. Meaning matches won't be international, national only
local.

Secondly matches at bi-directional: a user can search for all "searches" in
their area, in addition to searching for all offers in their area. This means
that someone looking to offer a product in their neighbourhood, can first
search for everything that users are looking for.

Another feature is search persistence: a "search" (which can either be for an
offer or a search) are continually done with changes in location of the user.
Meaning, "searches" move with the searcher. In the same way, offers can also
move with the offerer.

This backend code was designed for this product idea. It is based on
Kafka to provide an event bus so that components are decoupled. Mongo
for doing geo-matching and redis for caching of events.

## Architecture

*Insert Image Here*

Main parts of the infrastructure:

1. [Storage](src/storage) is a mongo-based datastore for searches and
   offers. Mongo is good at doing geo matching, hence it was chosen as
   the datastore.

2. [Website](src/website) providing a simple home page and web-based
   Push service.

3. [Tracker](src/tracker) that ingests tracking events
   and pushes these to an redis instance. The intention is to have
   one redis per tracker instance, however this is not set in stone.
   Requests are considered fire-and-forget, meaning the client does not
   need to handle the response.

4. [Image server](src/imageserver) providing a store for images for offers
   and searches. Basically the same as a amazon bucket but with
   [image processing](src/imageserver/models/image_uploader.rb).

5. [Kafkastore](src/kafkastore) then takes those tracking calls from redis,
   does some magic ([geoIP lookup](src/kafkastore/lib/helpers.js#L25),
   [device detection](src/kafkastore/lib/helpers.js#L27) and reformatting of the
   message). It then does a batch insert into kafka. The tracker does not
   store directly into kafka because of the extra geoIP lookup and also
   because we want to batch tracking calls together before handing them off
   to kafka.

6. [Notification Server](src/notificationserver) for sending push notifications
   to the mobile application and also to the website. Notifications are sent
   via [OneSignal](https://onesignal.com/).

7. [Offer Server](src/offerserver) for generating seed offers of
   various things on the internet. All offer generators are
   [here](src/offerserver/lib/importers).

8. [Kafidx](src/kafidx) which is a simple web-socket based consumer
   which shows live tracking events as they come in. It is useful for debugging
   consumers and generally ensuring that events are going through the
   system.

9. [Nodejs consumers](src/consumers.nodejs) which just provide some
   statistical data.

10. [Ruby consumers](src/consumers.ruby) which trigger various actions
   when various events happen.

11. [NFS Server](src/imageserver.nfs) for providing data storage for the
   the imageserver. This was not possible using a persistent volume since
   these are bound to a single node in kubernetes. Instead the imageserver
   now connects to the NFS server that has the persistent volume.

12. [Kafka and Zookeeper](docker-compose/kafka-zookeeper.yml) - just that!

Design decisions:

1. Independent scaling of each component of the infrastructure.
2. Decoupling of recieving events, storing and handling those events.
3. Maximum flexibility in sending and creating new tracking events.
4. No assumption about what gets tracked and how many tracking calls come in.
5. Each tracking event is independent and there is no assumption about
   ordering of tracking events.

What's missing?

1. Optimisation and configuration of the kafka and zookeeper instances.
   At the moment, there is a single kafka broker and a single instance
   of zookeeper running in the cluster.
2. Batch interface for the tracker for handling batched tracking calls
   from the client.
3. Logging and monitoring.


## Prerequistes for local testing

### rake

The [Rakefile](Rakefile) provides some helper tasks to make life that
much easier. But to use it, you'll need ruby. Specifically, you will
need [ruby 2.4.3](.ruby-version) which you can install using
[rvm](https://en.wikipedia.org/wiki/Ruby_Version_Manager) or
[rbenv](https://github.com/rbenv/rbenv). After that, it's a matter
of installing bundler and all required gems:

    gem install bundler
    bundle

Then have a look at all available tasks

    rake -T

Done.

### Environment

Some things are secret and therefore there is an ```.env``` file for
storing those secrets. But these secrets are checked in, so you will have
to find these from existing heroku installations (or elsewhere).

The [template](.env.template) gives an overview of what needs to be defined,
and is the basis for a generated ```.env```:

    rake dotenv:generate

### Docker


[Docker](https://www.docker.com/docker-mac) needs to be installed.

### Kompose

To convert docker compose files to kubernetes, [kompose](https://kompose.io)
was used. This could also be [installed](http://kompose.io/setup/) but
is not required since the conversion was a one-off. Any changes to the
kubernetes files should be done directly in the [kubernetes](kubernetes)
directory.

## Deployment


Currently the project can be deployed via docker and kubernetes. Docker
is great for local testing, kubernetes for production.

[Kubernetes](https://kubernetes.io/) was tested locally using
[minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/),
whether this is respresentable for the production platform is to be seen.

### Using Docker Compose

Set up the network and volumes:

    rake docker:compose:create_periphery

Compile all the images

    rake docker:images:build

Start up the images (best results when docker has 6 cpus and 8 GB ram):

    rake docker:compose:spin_up

Open relevant URLs:

    rake docker:compose:open_urls

To shut things down:

    rake docker:compose:spin_down

### Using MiniKube and Kubectl


Begin by starting minikube and buiding all the docker containers:

    rake minikube:start

Point the docker environment to the minikube docker

    eval $(minikube docker-env)

Build the container images to minikube

    rake docker:images:build

Create the kubernetes namespace:

    rake kubernetes:namespace:create

Load the secrets from ```.env``` file into minikube:

    rake kubernetes:secrets:load

Update minikube with the kubernetes yamls:

    rake kubernetes:spin:up

Then after a few moments (to let things start up), test it:

    open -a Firefox $(minikube service tracker -n pushtech --url)/t/w?wor=king
    open -a Firefox $(minikube service kafidx -n pushtech --url)/kafidx
    open -a Firefox $(minikube service storage -n pushtech --url)/store/offers
    open -a Firefox $(minikube service notificationserver -n pushtech --url)/mappings
    open -a Firefox $(minikube service imageserver -n pushtech --url)/assets
    open -a Firefox $(minikube service website -n pushtech --url)
    open -a Firefox $(minikube service offerserver -n pushtech --url)/sidekiq
    open -a Firefox $(minikube service consumers-ruby -n pushtech --url)/sidekiq

After, tear everything down again:

    rake kubernetes:spin:down

That will maintain the persistent storage, if you want to get rid of
absolutely everthing, then do the following:

    rake kubernetes:secrets:delete
    rake kubernetes:namespace:delete

After that, shut down minikube

    minikube stop


### Local Development

This is described in more details [separately](docs/development.md).

### Deployment to Stackpoint

Can be [read about here](docs/deployment.md)
