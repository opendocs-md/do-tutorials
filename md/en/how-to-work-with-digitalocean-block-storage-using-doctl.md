---
author: Sebastian Canevari
date: 2018-01-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-work-with-digitalocean-block-storage-using-doctl
---

# How To Work with DigitalOcean Block Storage Using Doctl

## Introduction

Block Storage allows you to manage additional storage for your DigitalOcean Droplets in a way similar to using hard drives. Adding block storage to our Droplets can be done with a few clicks from DigitalOcean’s streamlined GUI or graphical user interface. However, this is not a practical way of operating in larger and more complex environments, so DigitalOcean offers an API to work at scale. We can interact directly with the API through `doctl`, DigitalOcean’s official command-line tool.

In this tutorial, we’ll learn how to use `doctl` to create, list, attach, detach, and delete block storage volumes from our Droplets.

## Prerequisites

Before starting this tutorial, you should familiarize yourself with `doctl` and DigitalOcean’s block storage. The following articles will be helpful:

- [How To Use Doctl, the Official DigitalOcean Command-Line Client](https://blog.digitalocean.com/introducing-doctl)
- [Getting Started with DigitalOcean Block Storage](https://www.digitalocean.com/community/tutorial_series/getting-started-with-digitalocean-block-storage)

You should make sure you have the latest version of `doctl` (at the time of this writing it’s 1.7.1) installed and authenticated before continuing. Check your `doctl` version by running `doctl version`. You will also need to have an [SSH key added to your DigitalOcean account](how-to-use-ssh-keys-with-digitalocean-droplets).

Last but not least, to follow this tutorial you will need a Droplet created on one of the regions that allow the use of block storage (at the time of this writing, the following regions offer block storage: **BLR1** , **FRA1** , **LON1** , **NYC1** , **NYC3** , **SFO2** , **SGP1** , and **TOR1** ).

**Note:** While the regions mentioned above support block storage, this feature is not currently available for all Droplets in the noted regions. To ensure that the Droplet you are working on supports block storage, you will have to attach a volume to it at the time of creation.

## Creating Volumes

In order to create a volume with `doctl`, you need to provide the following parameters to the command:

- **volume name** : in our example it will be **firstvolume**
- **region** : for our tutorial we’ll create the volume in **NYC3**
- **size** (defaults to 4TB): in this example we’ll set it to **100 GiB**

You can also provide a description with the **desc** flag but that’s entirely optional. The full command will look like this:

    doctl compute volume create firstvolume --region nyc3 --size 100GiB

You should see an output similar to this:

    OutputID Name Size Region Droplet IDs
    ______your_volume_ID1_______ firstvolume 100 GiB nyc3    

At this point, you know the `doctl` command and what information is required to create a new volume. Next, you will learn how to print a complete list of existing volumes.

## Listing Volumes

`doctl` provides us with the ability to show existing volumes in a formatted list. There are a few reasons why you would want to list your volumes. The two most common ones being to display the ID of each volume to be used in later commands, and to display which Droplets have volumes assigned to them.

To list all current block storage volumes, you can run the following command.

    doctl compute volume list

This is the output of the `list` command run in our example.:

    OutputID Name Size Region Droplet IDs
    ______your_volume_ID1______ firstvolume 100 GiB nyc3      
    ______your_volume_ID1______ secondvolume 4096 GiB nyc3      
    ______your_volume_ID1_______ thirdvolume 100 GiB nyc3 [ID]

In this section, you have learned the `doctl` command to see a list of volumes you have created. In the next section, we’ll go over how to attach a volume to a Droplet.

## Attaching Volumes

Sometimes your Droplet may need extra space to handle assets such as application data and configuration files. Adding a volume is a great way to add this space without disrupting service.

To attach volumes you will need two pieces of information:

- the volume ID
- the Droplet ID

In the previous section, we’ve seen how to obtain the **volume ID** by using the `doctl compute volume list` command.

We can get our **Droplet ID** by running the following command to display information about our account’s Droplets:

    doctl compute droplet list

Once we have both the volume and Droplet IDs, we can proceed with the following command to attach a volume to a Droplet:

    doctl compute volume-action attach your_volume_ID your_droplet_ID

This will produce an output similar to this:

    OutputID Status Type Started At Completed At Resource ID Resource Type Region
    346253669 in-progress attach_volume 2017-12-28 19:53:28 +0000 UTC <nil> 0 backend nyc3

Earlier in this tutorial, it was recommended that you attach a volume to the Droplet at creation time, in order to ensure that the Droplet is using infrastructure that supports block storage. If you created a Droplet without attaching a volume at that time, you might see the following error when trying to attach a volume to it:

    OutputError: POST https://api.digitalocean.com/v2/volumes/your_volume_ID/actions: 422 Droplet can't attach volumes due to a region restriction

If you encounter this error, you will not be able to attach the volume to the specified Droplet and will need to try again.

Once you have a volume successfully attached to a Droplet that accepts the volume, you can go on to the next section to learn how you can detach the volume in the case that you no longer need the extra space.

## Detaching Volumes

There may be times in which you may need to attach a volume only temporarily to a Droplet, like when you are debugging an issue that requires a large amount of logs, or creating a backup of certain time-bound data. In these cases, we’ll need to be able to detach a volume once we are done using it.

Detaching a volume is similar to attaching a volume and uses the same pieces of information. The command and the output vary slightly.

    doctl compute volume-action detach your_volume_ID your_droplet_ID

    OutputID Status Type Started At Completed At Resource ID Resource Type Region
    346254931 in-progress detach_volume 2017-12-28 19:57:51 +0000 UTC <nil> 0 backend nyc3

At this point, you know how you can detach a volume with `doctl`. In the next section, you will learn how to delete a volume that you no longer need.

## Deleting Volumes

When you no longer need a certain block storage volume, you can detach it and then remove it from your account through deletion. Once you have detached a volume, to delete it you will need its ID.

    doctl compute volume delete your_volume_id

Running this command will prompt for a confirmation:

    OutputWarning: Are you sure you want to delete volume (y/N) ?

If you are satisfied that you would like to delete the volume, press `y` to confirm.

Once the volume is deleted you will be returned to the command prompt. You can verify that the volume has been deleted by using the `list` command.

## Getting Information About a Volume

If you need information about a specific volume, you can request it by invoking the following command

    doctl compute volume get your_volume_id

You will find the output of this command familiar because it is automatically run when creating a volume.

    OutputID Name Size Region Droplet IDs
    ______your_volume_ID1_______ firstvolume 100 GiB nyc3

In this section you have learned how you can delete a volume that is no longer needed.

You now have all the information you need to successfully use `doctl` to work with DigitalOcean block storage volumes.

## Conclusion

In this tutorial, we’ve learned how to use `doctl` to add, attach, detach, list, and delete volumes from our Droplets.

Now that you know how to do this, you may want to explore creating scripts and adding these scripts to your favorite automation tool, such as [Jenkins](how-to-set-up-jenkins-for-continuous-development-integration-on-centos-7) or [Drone](how-to-install-and-configure-drone-on-ubuntu-16-04).
