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
