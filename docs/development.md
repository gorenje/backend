# How to do local development

This will cover how to run the backend locally to test changes and
make changes. It is definitely not a trival task with the combination
of technologies (ruby & node) and orchestration technologies (kubernetes,
docker and rake).

Always the intention is to have a fast turnaround time in debugging,
feature development, testing and deployment. Ideally this entire process
should take minutes, not hours.

To make this happen, [rake](https://en.wikipedia.org/wiki/Rake_(software))
is utilised so that the steps remain the same and don't have to be remembered.

[Docker](https://en.wikipedia.org/wiki/Docker_%28software%29) is also
essential for local development. So that needs to be installed locally.

[minikube](https://kubernetes.io/docs/tutorials/kubernetes-basics/cluster-intro/)
can be installed but isn't that essential for local testing, unless the
orchestration is to be tested. But that's not covered here.

## In the beginning....

So to start with, we need an environment for connecting the parts together.
Since there are a lot of [parts](../src), there is a lot to be set up.
Luckily there is a rake task for the that:

    rake dotenv:generate

this takes the [.env.template](../.env.template) file and interactively
generates a local ```.env``` file. This stores basic things like API
keys and port numbers but also various other things. *Important* to remember
is that the local .env file will be used to define the production (and
staging) environments. But that is not important ... just yet.

Having installed docker, ensure that you're using the local docker:

    docker ps

This can get confusing if you're using minikube, because it comes with
another docker instance and sometimes you setup your minikube environment
to use that docker. This is
[described](../README.md#using-minikube-and-kubectl) in the readme. Also
using minikube and kubectl can become confusing if you're deploying
to a remote kubernetes system ... your environment can get very confusing
and if not sure, open a new terminal window :-)

Once docker is up, build all the backend images:

    rake docker:images:build

What this [does](../../0ce53dee908ede1e6583cb23c09b0aa1b2a3824d/lib/tasks/docker.rake#L5-L16)
is to take each part and build a docker image using the corresponding
Dockerfile of the respective project. That is, each directory in [src](../src)
becomes a docker image with the name ```pushtech.<directory>:v1```
which then can be referenced in the [docker-compose](../docker-compose)
files. (The namespace ```pushtech``` can also be defined in the .env
file, but we'll assumme pushtech.)

This is a naming convention allows easy definition of new components
and makes it easy to switch between kubernetes and docker-compose.

Now go ahead and spin up the entire backend, how that is done is described in the [readme](../../0ce53dee908ede1e6583cb23c09b0aa1b2a3824d/README.md#using-docker-compose).

Once the backend is running, we know we're good to go to make local changes.

## Now the part with rinse and repeat comes...

So local development can be done in one of two ways:

1. either run the corresponding source code directly using ```node``` or
   ```foreman```,
2. make changes, rebuild the docker image and restart the docker image
   using ```docker-compose```.

Take your pick which one you would like to do, both have their pros and cons.

### 1. Running code locally

To best illustrate this, let's make a change to the [website](../src/website)
code base.

The first thing to notice is that the website requires a postgres database.
Ok, for that we don't need to install postgres, instead we just start the
corresponding docker-compose file *but* first we need to open the postgres
port to localhost. This is done by changing this
[line](../../0ce53dee908ede1e6583cb23c09b0aa1b2a3824d/docker-compose/website.yml#L9)
to ```- 5432:5432``` which tells docker-compose to connect port 5432 of the
container to the localhost port 5432.

(BTW don't check this in since there is no reason to expose the database
port on localhost in normal operation and secondly there are multiple
postgres databases and only one port!)

So power up postgres:

    eval $(cat .env) ; docker-compose -f docker-compose/website.yaml up

This will also spin up a container with the website running (it will
also migrate the database for you!).

Now comes the stuff that is a bit painful but only needs to be done once.
Setup the ```.env``` file for the website codebase. This is done locally
in the [src/website](../src/website) directory. What needs defining can
be found in the [website.yml](../../0ce53dee908ede1e6583cb23c09b0aa1b2a3824d/docker-compose/website.yml#L23-L50),
i.e. it's non-trival!

But remember the database url will be
```postgres://user:pass@localhost:5432/dbname```!

Of course, there are bunch of other references to the other services
in the backend, whether they also need to be started via docker-compose, is
depended on the change to be made. But it's the same principle: open their
ports on localhost, change their URL to localhost plus port and the website
code will be able to connect to the respective service.

But now the code can be run using

    foreman start web

and you can make the necessary changes and test locally. Once everything
works, you can rebuild the docker image ```rake docker:images:build```
and test everything together.

#### Take aways

So what we done here is starting parts of the architecture using docker
compose and running the code locally.

Ddownside is having to setup a .env file locally for doing that. But that
only has to be done once.

Advantage is that changes can be tested directly and quickly.

### 2. Cowboy coding ....

This is more rough-and-ready since what we're doing here is making local
changes, building a docker image and restarting the service directly using
docker-compose.

Turnaround time for checking changes is slightly longer than running code
directly but advantage is that you are testing changes with the complete
environment.

First start by spinning up the entire architecture

    rake docker:compose:spin_up

Now say you want to make a change to the website, first thing to do
is to take it out of the architecture:

    eval $(cat .env) ; docker-compose -f docker-compose/website.yaml down

Now make the necessary changes. Afterwards, rebuild the docker image and
spin up the website:

    rake docker:images:build
    eval $(cat .env) ; docker-compose -f docker-compose/website.yaml up

Don't worry about the docker rebuild, it only rebuilds what has changed,
i.e. is super quick. Also starting up the service is also quick.

#### Take aways

Advantage here is that you're testing everything combined together and
don't have a extra overhead generating another .env file.

Disadvantage is that it takes a little longer to test changes.
