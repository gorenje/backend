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

## Components

All components are found in [src](src) and interact together to provide
the complete backend for the Push application.

Design decisions:

1. Independent scaling of each component of the infrastructure.
2. Decoupling of components by providing an event bus.
3. Maximum flexibility in sending and creating new events.
4. No assumption about what gets tracked and how many tracking calls come in.
5. Each tracking event is independent and there is no assumption about
   ordering of tracking events. Each event is complete and non-depended
   on other events.

What's missing?

1. Optimisation and configuration of the kafka and zookeeper instances.
   At the moment, there is a single kafka broker and a single instance
   of zookeeper running in the cluster.
2. Batch interface for the tracker for handling batched tracking calls
   from the client.
3. Logging and monitoring.

[Kafka](https://kafka.apache.org/) provides the event bus and is the only
common denomiator between components. Although, components do communicate
directly with one another. Communication is via APIs, thus providing a
clear interface how components can communicate.

Each component has limited scope of responsibility and care should be taken
in dividing up what needs doing amongs components. An example of this
is the [notification server](src/notificationserver) which is solely
responsible for sending push notifications to mobile devices. All other
components communicate via an API with the notification server when
a notification should be sent.

This allows for a central point of notification rate limiting, for example.
Also, if the service provider (in this case OneSignal) for push notifications
should be changed, then only the notification server needs to be modified.

Also having separate components allows different coding languages to be
used. There is no requirement to code all components on the same language.
At the moment, NodeJS and Ruby have been used.

## Prerequistes

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

## Starting Backend locally

Project can be started locally by either using docker compose or
minikube with kubectl.

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
