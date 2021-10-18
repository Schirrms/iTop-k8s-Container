# iTop-k8s-Container
This is my attempt to build a k8s compatible template for iTop (with an acceptable persistent storage support)

## Goal
Build a Container image with all 'writeable datas' in a specific directory, to be able to use persistent storage.

## Constraints
iTop has (IMHO) a little flaw in the design : in some stages of the setup, itop move directories at the top level.
But a container image is read-only. It would be easier if all 'modifiables files and dirs could be in the same subdir (that could then be the path to the persistent storage).

More informations here (Link at 2021-10-18) : https://www.itophub.io/wiki/page?id=latest%3Ainstall%3Asecurity

One 'easy' solution is to copy the whole itop content in the persisten volume. But in that case, updates will be hard (much harder than simply deploy a new version of the container anyway).

My image, with the help of a lot of cross referenced symbolic links is able to do the work. Probably not the nicest Dockerfile in the world :)

You'll also find one of the kubernetes deployment file I use with these images. 

With images built with this Dockerfile and those kind of deployment, upgrading iTop is a matter of 'kubectl edit deployment itop-deployment', and updating the imagefile. Of course, that is the first step, you'll also have to run an iTop setup after the deployment. And no, my k8s knowledges are not that good that I'm able to build a side-car container able to run the setup for me.

## Choices
In our context, we considers that extensions is part of the original package. So, the 'extensions' folder is in RO mode. Adding or updating an extension means that a new container image is build and delivered.
