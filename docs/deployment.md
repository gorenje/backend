# How to deploy

The key to deployment is having docker images privately hosted somewhere
so that they can be installed remotely.

Of course a better solution would be to run a docker repository as part
of the kubernetes cluster but that's still something to be done.

Having done some [local development](./development.md), it's time to
deploy the code base.

For the purposes of this description, we'll deploy to
[Stackpoint](https://stackpoint.io) using a
[DigitalOcean](https://cloud.digitalocean.com) cluster. As hoster,
Stackpoint also supports AWS, Google Cloud and Microsoft Azure but
DigitalOcean has been found to be easier and quickest.

*Caveat*: I know of [Helm](https://helm.sh/) but prefer using scripts since,
for me, it seems more flexible but I would be happy to be proven wrong!

## Setup Stackpoint

Setting up stackpoint is a matter of getting an account there, getting
another account at DigitalOcean and then defining the DO API key at
Stackpoint. After that you can setup a kubernetes cluster. (Best has
been found to be three workers, each with 4GB of memory.)

You can keep the default settings at stackpoint, creating a cluster
with [RBAC](https://kubernetes.io/docs/admin/authorization/rbac/) is fine,
the YAMLs generated support RBAC.

Once the kubernetes cluster is up and running at Stackpoint, download
the kubeconfig file and make kubectl use it:

    export KUBECONFIG=/path/to/kubeconfig_from_stackpoint

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
    spc0hu6dl8-worker-3   Ready     <none>    57s       v1.8.5


Great! Now it's time to generate the docker image and push them off
to a private repository.

## Building and Pushing Docker Images.

This assumes that you have docker hub account. The nice thing about
docker hub is that you get one repo that is private. Now, if you think
about version tags, you can actually host all images in one private
repo with lots of version tags! That's the workaround we'll be using.

Once you have your docker account,
[login on the cli](https://docs.docker.com/engine/reference/commandline/login/).
This setups up the ```~/.docker/config.json``` and you can push to your
private repo. We'll assume you happen to have ```gorenje``` as your
docker-hub account!

So first build (of course a local docker instance is running) then push
the docker images:

    rake docker:images:build
    DOCKER_ACCOUNT=gorenje rake docker:images:push

This could take awhile, depending on your uplink.

## Build Kubernetes YAMLs for Stackpoint

We already have a [bunch of kubernetes](../kubernetes) files however
this are designed to run in minikube. So they don't handle load balancing,
SSL Certificate generation and external IPs.

For the rest of the description, we'll assume that our Image Namespace
is ```pushtech```.

Hence, there is a rake task for turning them into stackpoint kubernetes
files. Build the stackpoint specific YAMLs for orchestration, also including
the subdomain (or top-level domain) to be used for the later access.
Do not create this domain yet (if it hasn't yet been created), the IP for
the domain comes later:

    DOMAIN=staging.pushtech.de DOCKER_ACCOUNT=gorenje \
       IMAGE_PULL_POLICY=Always rake stackpoint:generate:yaml

Some things to note here:

- ```DOMAIN``` should be whatever domain you want to use as base, i.e. the
  subdomains will be created automagically off that.
- ```DOCKER_ACCOUNT``` is the same as above, but doesn't have to be. You
  can have multiple but .... *remember*: the docker-hub credentials pushed to
  stackpoint will be of the ```~/.docker/config.json```, i.e. your local
  user.
- ```IMAGE_PULL_POLICY``` should be ```Always``` but defaults to
  ```IfNotPresent```, i.e. for staging, it's useful to have images
  pulled always (to test new things), for production it's better to
  not automagically update the images hosted in the kubernetes cluster.

Also note, that the ```.env``` and your ```~/.docker/config.json``` will
be pushed to kubernetes (in the form of [secrets](https://kubernetes.io/docs/concepts/configuration/secret/))
however if anything (i.e. API Keys) aren't production or staging ready,
then change them before generating the YAMLs.

Continue if the docker image from above have all been pushed to docker
hub. Otherwise stay here and do a busy-loop.

You should have a number of YAMLs, we're going to deploy them in turn.
First the basic infrastructure:

    for n in namespace configmap secret clusterrole clusterrolebinding \
             service persistentvolumeclaim ; do
      kubectl create -f stackpoint.${n}.yaml
    done

This creates the basic configuration landscape, you'll need to wait until the
persistentvolumes have been created (this might take a few minutes). Ensure
that they get created, if they don't: rinse and repeat the provisioning.

## Setup Domain with Load Balancer IP

In the meantime, create the domain you want to use by getting the load balancer
IP and setting for your domain:

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

Once the persistentvolumes have been create (i.e. Bound), do the rest of
the orchestration.

## Create services

Now we'll create the deployments, these will create the pods and get
everything up and running.

    kubectl create -f stackpoint.deployment.yaml

To check whether stuff is up and running:

    kubectl get deployments --all-namespaces=true

## Create LoadBalancer configuration and SSL Certificates

While waiting for all the servers to spin up, you can have a quick look at
the ingress that are going to be created:

    $EDITOR stackpoint.ingress.yaml

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

## Mongo Indicies

As an absolute final step, log on into the mongo pod and create the geo-spatial
indicies. Before doing this, create at least one search, else the searches
collection won't be there (offers are created automagically by the
offerserver):

    kubectl exec -n pushtech -it `kubectl get pods -n pushtech | grep storage-db | awk '// { print $1; }'` -- /bin/bash
    prompt> mongo
    mongo> use store
    mongo> db.offers.createIndex({"location": "2dsphere"})
    mongo> db.searches.createIndex({"location": "2dsphere"})

That should make things a little faster.

## Known Issues with Stackpoint

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

## Testing the stackpoint rake task

Helpful little trick I use to test the generation of the stackpoint yamls
is to diff them. Easiest way I've found to do this is:

     rake stackpoint:generate:yaml
     mkdir tmp
     mv stackpoint.*.yaml tmp

     ### make some changes to something
     rake stackpoint:generate:yaml
     mkdir tmp2
     cp stackpoint.*.yaml tmp

     diff -r tmp tmp2

That shows everything that changed.

## Updating docker images in production and staging environments

This is related to the ImagePullPolicy defined when the setup was deployed.

If you set ```Always```, then updating a service with new code is just a
matter of deleting the corresponding Pods. Once they're recreated, the
images are pulled automagically by kubernetes.

The default value of ```IfNotPresent``` is a litte more difficult since
it requires removing the image from the node running the container. So even
if you delete the deployment and the recreate the deployment, if the
corresponding pods are created on nodes that already had the image, you'll
end with the same old image.

My workaround has been to delete the deployment from the kubernetes
cluster, updated the ```*.deployment.yaml```, adding the imagePullPolicy
of ```Always``` and redeploying the deployment description.

Hence for a staging environment, always use Always!
