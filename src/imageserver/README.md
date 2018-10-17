# Push Image Server

This is the image store for offers and searches.

Primitive CDN for storing, updating and retrieving images linked to
searches and offers.

This is uses an [NFS Server](../imageserver.nfs) as storage for all images.

Images are stored in various [sizes](models/image_uploader.rb) and can also
be retrieved in those sizes.
