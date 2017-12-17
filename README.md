Pushtech Backend
===

Complete backend for Push.

Architecture
===

*Insert Image Here*

Ten main parts to the infrastructure:

1. Front-facing [tracker](src/tracker) that takes in tracking requests
   and pushes these to redis instance. The intention is to have
   one redis per tracker instance, however this is not set in stone.
   Requests are considered fire-and-forget, meaning the client does not
   need to handle the response.
2. [Kafkastore](src/kafkastore) then takes those tracking calls from redis,
   does some magic ([geoIP lookup](src/kafkastore/lib/helpers.js#L46),
   [device detection](src/kafkastore/lib/helpers.js#L48) and reformatting of the
   message). It then does a batch insert into kafka. The tracker does not
   store directly into kafka because of the extra geoIP lookup and also
   because we want to batch tracking calls together before handing them off
   to kafka.
3. [Consumers](src/consumers) ingest events from kafka, doing whatever work
   they are intended to do. At the moment, there are two consumers to
   demostrate how consumers generally work.
4. [Kafidx](src/kafidx) which is a simple web-socket based application
   which shows live tracking events as they come in. It is useful for debugging
   consumers and generally ensuring that events are going through the
   system.
5. [Nodejs consumsers](src/consumers.nodejs)
6. [Ruby consumsers](src/consumers.ruby)
7. [Website](src/website)
8. [Image server](src/imageserver)
9. [Offer Server](src/offerserver)
10. [Kafka and Zookeeper](docker-compose/kafka-zookeeper.yml)

Design decisions:

1. Independent scaling of each component of the infrastructure.
2. Decoupling of recieving events and handling those events.
3. Maximum flexibility in the sending and creating new tracking events.
4. No assumption about what gets tracked and how many tracking calls come in.
5. Each tracking event is independent and there is no assumption about
   ordering of tracking events.

What's missing?

1. SSL-Termination done by a haproxy or nginx in front of the tracker
   instances.
2. Optimisation and configuration of the kafka and zookeeper instances.
   At the moment, there is a single kafka broker and a single instance
   of zookeeper running in the cluster.
3. Batch interface for the tracker for handling batched tracking calls
   from the client.
4. Logging and monitoring.


Prerequistes for local testing
===

rake
---

The [Rakefile](Rakefile) provides some helper tasks to make life that
much easier. But to use it, you'll need ruby. Specifically, you will
need [ruby 2.4.2](.ruby-version) which you can install using
[rvm](https://en.wikipedia.org/wiki/Ruby_Version_Manager) or
[rbenv](https://github.com/rbenv/rbenv). After that, it's a matter
of installing bundler and all required gems:

    gem install bundler
    bundle

Then have a look at all available tasks

    rake -T

Done.

Environment
---

Some things are secret and therefore there is an ```.env``` file for
storing those secrets. But these secrets are checked in, so you will have
to find these from existing heroku installations (or elsewhere).

The [template](.env.template) gives an overview of what needs to be defined,
so copy that to ```.env``` and add the missing secrets.

Docker
---

[Docker](https://www.docker.com/docker-mac) needs to be installed.

Kompose
---

To convert docker compose files to kubernetes, [kompose](https://kompose.io)
was used. This could also be [installed](http://kompose.io/setup/).
Deployment
===

Currently the project can be deployed via docker and kubernetes. Docker
is great for local testing, kubernetes for production.

[Kubernetes](https://kubernetes.io/) was tested locally using
[minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/),
whether this is respresentable for the production platform is to be seen.

Using Docker Compose
---

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

Using MiniKube and Kubectl
---

*WIP* This isn't complete yet .....

Begin with starting minikube and buiding all the docker containers:

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

    open -a Firefox $(minikube service trackersrv -n pushtech --url)/t/w?wor=king
    open -a Firefox $(minikube service kafidx -n pushtech --url)/kafidx

After, tear everything down again:

    rake kubernetes:secrets:delete
    rake kubernetes:spin:down
    rake kubernetes:namespace:delete

    minikube stop

As alternative and for quicker local testing, you can always use docker
compose.
