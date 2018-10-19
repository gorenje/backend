# Network File System (NFS) server for imageserver

This provides a NFS Server for the [imageserver](../imageserver).

When scaling the image server on Kubernetes, each image server gets a new
persistent storage and the not the same one. Persistent storages are linked
to a single instance.

So this NFS server provides a single storage point for all imageservers.
