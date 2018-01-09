# Pushtech Backend

Complete backend for Push.

## Architecture

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
5. [Nodejs consumers](src/consumers.nodejs) which just provide some
   statistical data.
6. [Ruby consumers](src/consumers.ruby) which trigger various actions
   when various events happen.
7. [Website](src/website) providing a simple home page.
8. [Image server](src/imageserver) providing a store for images for offers
   and searches. Basically the same as a amazon bucket but with
   [image processing](src/imageserver/models/image_uploader.rb).
9. [Offer Server](src/offerserver) for generating offers of various places
   are the internet. All offer generators are
   [here](src/offerserver/lib/importers).
10. [Kafka and Zookeeper](docker-compose/kafka-zookeeper.yml) - just that!
11. [NFS Server](src/imageserver.nfs) for providing data storage for the
   the imageserver. This was not possible using a persistent volume since
   these are bound to a single node in kubernetes. Instead the imageserver
   now connects to the NFS server that has the persistent volume.

Design decisions:

1. Independent scaling of each component of the infrastructure.
2. Decoupling of recieving events and handling those events.
3. Maximum flexibility in the sending and creating new tracking events.
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
need [ruby 2.4.2](.ruby-version) which you can install using
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


1. Start services (e.g. redis or postgres) locally with with docker-compose

2. Run service locally against the resources started via docker-compose

3. Once happy, build docker images to minikube

4. Test in minikube

5. Rebuild images locally against the local docker and then push them to
   docker hub. ```rake docker:image:build && rake docker:image:push```

6. Redeploy production. For redeploying, you will have to set the image
   pull policy to always. ```ImagePullPolicy: Always``` which is set in
   the deployment.yaml file for the corresponding container.

   ```kubectl create -f *.deployment.yaml```

   where ```*``` probably stackpoint is (see below).


### Working with StackPoint.io

Provision and then download the kubeconfig from stackpoint and do:

    export KUBECONFIG=/some/directory/kubeconfig

test that it worked

    kubectl get nodes

That should respond with the provisioned nodes at the respect cloud provider.
Once all nodes are ready, continue. I.e. something like this:

    NAME                  STATUS    ROLES     AGE       VERSION
    spc0hu6dl8-master-1   Ready     master    7m        v1.8.5
    spc0hu6dl8-worker-1   Ready     <none>    57s       v1.8.5
    spc0hu6dl8-worker-2   Ready     <none>    57s       v1.8.5

Then build the stackpoint specific YAMLs for orchestration, also including
the subdomain to be used for the later access. Do not create this domain
yet, the IP for the domain comes later:

    DOMAIN=staging.pushtech.de rake stackpoint:generate:yaml

And then deploy it:

    for n in namespace configmap secret clusterrole clusterrolebinding \
             service persistentvolumeclaim ; do
      kubectl create -f stackpoint.${n}.yaml
    done

This creates the basic configuration landscape, you'll need to wait until the
persistentvolumes have been created (this might take a few minutes). Ensure
that they get created, if they don't: rinse and repeat the provisioning.

In the meantime, create the domain you want to use by getting the load balancer
IP and setting that your domain:

    kubectl describe svc nginx --namespace nginx-ingress | grep "LoadBalancer Ingress"

    ...
    LoadBalancer Ingress:     1.2.3.4
    ...

Take the IP and set that to whatever domain you want to use (as an example,
we'll take ```staging.pushtech.de```):

    staging.pushtech.de   --> 1.2.3.4
    *.staging.pushtech.de --> 1.2.3.4

Include the wildcard since we are going to create a number subdomains.

Check on the persistent volumes, once all are live then continue:

    kubectl get pvc -n pushtech

Once the persistentvolumes have been create, do the rest of the orchestration:

    kubectl create -f stackpoint.deployment.yaml

To check whether stuff is up and running:

    kubectl get deployments --all-namespaces=true

While waiting for all the servers to spin up, you can have a quick look at
the ingress that are going to be created:

    emacs stackpoint.ingress.yaml

The services that we currently have (at time of writing):

    store.staging.pushtech.de  --> service: storage
    trk.staging.pushtech.de    --> service: tracker
    notify.staging.pushtech.de --> service: notificationserver
    www.staging.pushtech.de    --> service: website
    www1.staging.pushtech.de   --> service: website
    www2.staging.pushtech.de   --> service: website
    www3.staging.pushtech.de   --> service: website
    assets.staging.pushtech.de --> service: imageserver

And administration services, not required to be accessible from the outside
world:

    kafidx.staging.pushtech.de    --> service: kafidx
    offers.staging.pushtech.de    --> service: offerserver
    consumers.staging.pushtech.de --> service: consumers-ruby

The subdomain is set in the annotations field of the service, so there
is no need to do this by hand.

Ideally, you'll not have to change anything in the ingress can just deploy
them as is:

    kubectl create -f stackpoint.ingress.yaml

And that should be it. Now the entire cluster should be up and running with
SSL certificates being automagically generated.

SSL certificates are available when the following matches the number of ingress
hosts created:

    kubectl get secrets -n pushtech | grep tls

As an absolute final step, log on into the mongo pod and create the geo-spatial
indicies:

    kubectl exec -n pushtech -it `kubectl get pods -n pushtech | grep storage-db | awk '// { print $1; }'` -- /bin/bash
    prompt> mongo
    mongo> use store
    mongo> db.offers.createIndex({"location": "2dsphere"})
    mongo> db.searches.createIndex({"location": "2dsphere"})

That should make things a little faster.

#### Known Issues with Stackpoint

1. Notification server does not start

   This happens when waiting for all deployments to come up. If the notification
   server (or another server) does not seem to come, delete the associated
   pod (not deployment) and let kubernetes restart the pod. That should fix it.

2. Mongo and Storage seem too slow

   Sympton is basically that store is not responding and you get a bad gateway
   when acessing the storage.

   Here the best thing to do is scale up the storage deployment (say to 3)
   and wait until the new pods are up and running. Then delete the old pod
   (it will get restarted).
