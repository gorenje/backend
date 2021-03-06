# Fixing Live Issues

When things break, first panic. Once that is done, relax and fix it.

This is a WIP and lists some of things that have been encountered while
using Stackpoint (SPC) and DigitalOcean (DO).

## Prerequisties

Install the ssh credentials from SPC and configure your ssh
client using ```~/.ssh/confg```:

    Host <kubernetes worker ip>
    User core
    IdentityFile ~/.ssh/id_rsa_spc

User is always core and the identity file should be the name that your
using and not that of the authors naming schema. The ```kubernetes worker ip```
can be found at DO.

The SSH credentials are found on the control panel @ SPC.

## 1. Services aren't reachable

The first thing you think is that servers have gone done. But this is probably
not the case, instead probably the load balancer @ DO is dead again.

Of course the first thing you can do is access the kubernetes dashboard
via SPC. But if that is also down, then it's a pretty certain that the
load balancer @ DO is down.

Check that kubernetes is running:

    kubectl get nodes

You should get something like:

    NAME                        STATUS    ROLES     AGE       VERSION
    spcga6eyx6-master-1         Ready     master    6d        v1.8.5
    spcga6eyx6-worker-1         Ready     <none>    6d        v1.8.5
    spcga6eyx6-worker-2         Ready     <none>    6d        v1.8.5
    spcga6eyx6-worker-4472004   Ready     <none>    4d        v1.8.5

Notice that the status says all are ready, good. If one is ```NotReady```,
then that's a good candidate for login into and restarting kubelet (see
below).

Check the load balancer @ DO --> from the top tab "Networking", click on
"Load Balancers" on the navigation tabs on the networking page.

That should clearly state that the load balancer is up but it can't
connect to the droplets. If it does, then continue reading.

What you can do is try restarting kubelet on one of the works, this might
wakeup the master and get it do something:

    ssh <worker ip>

the worker ip comes from DO. Each droplet is named with the worker name,
so the association is clear.

Once you've logged in, restart kubelet:

    sudo -i
    systemctl restart kubelet.service

that should have fixed it.

If you want more work, then you can restart the entire server:

    sudo -i
    reboot

But be aware, all the pods that were running here, will be restarted on the
remaining workers. Which will then be overloaded and also fall down.

If however, for some reason you've managed to reboot the worker and you can
access the kubernetes dashboard, start killing pods on other workers so that
they get restarted on the worker that has nothing to do.

Kubernetes does not do this for you. Kubernetes just ensures that all pods
are running on the available resources. Once that is reached, kubernetes
will only balance pods once they die.

## 2. Pods don't want to be deleted

If this happens to you, try the following:

    kubectl delete pods -n pushtech <podid> --force --grace-period=0

But as the warning says, this could imply that the process still keeps
running. On the other hand, if the logs reply with:

    prompt> kubectl logs <podid> -n pushtech
    failed to get container status {"" ""}: rpc error: code = OutOfRange desc = EOF

Then things are pretty much over for the pod.

## 3. Nginx pod dies

Since nginx is the central point of entry into the backend, if everything
seems to be done (i.e. not reachable), then nginx might have crashed.

To check, do

    kubectl get pods --all-namespaces | grep nginx

If indeed nginx has died or is terminating, get rid of it permanently
by doing:

    kubectl delete pods <pod id of nginx> --force -n nginx-ingress

That will cause Nginx to be restarted.

The cause for this is sometimes a worker dies.

## 4. Kubernetes Worker Dies.

You can check this by checking all the deployments:

    kubectl get deployments --all-namespaces

If available is less than desired, then you know you have an issue.

## 5. Resources: Finding what is being used by the pods

Show all the resources available:

    kubectl describe nodes

and

    kubectl top nodes

To analyse the resource usage, start collecting datapoints:

    touch last.test.txt
    while [ 1 ] ; do rake kubernetes:resources:measure >> last.test.txt ; done

Leave that running and perform any loadtesting required.

In a second window, analyse the data points:

    watch -c rake kubernetes:resources:analyse

From there, redefine the resources in the k8s yamls.

## 6. Expanding Volumes

First expand the volume at Digital Ocean and then login into the
server which has the mount:

    resize2fs /dev/<device>

to get the name of the device:

    lsblk

that should be it. You might have to install the ext4 tools using:

    apt-get install e2fsprogs ### debian and co.
    yum install e2fsprogs ### CoreOS and RedHat
