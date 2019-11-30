---
author: Mark Drake
date: 2018-02-15
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/manage-backups-cloud-duplicacy
---

# How To Manage Backups to the Cloud with Duplicacy

## Introduction

[Duplicacy](https://duplicacy.com/) is a cross-platform backup tool that offers a number of functionalities — including incremental backups, concurrent backup, and client-side encryption — which aim to streamline the process of backing up data to the cloud. The CLI (command-line interface) Linux version is free for personal use but requires a paid license for commercial users. Additionally, Duplicacy is available for MacOS and Windows with a graphical interface, and this version requires both personal and commercial users to pay for a license.

Built on the idea of [lock-free deduplication](https://github.com/gilbertchen/duplicacy/wiki/Lock-Free-Deduplication), Duplicacy was designed to safely manage backups to a wide range of cloud storage services. When a Duplicacy client creates and stores a new chunk, other clients using the same storage bucket can see that the chunk already exists and therefore won’t upload it again. This allows separate clients to share and back up identical data without involving any additional effort to track backups.

This tutorial provides a high-level overview of how to install the CLI version of Duplicacy and use it to manage a typical data backup process with a DigitalOcean Space. We’ll also demonstrate how to back up a shared repository from multiple Droplets to the same Space, as well as how to back up snapshots to multiple Spaces for greater data security.

## Prerequisites

To follow along with this tutorial, you will need:

- **Two Ubuntu 16.04 Droplets** configured using our [initial server setup guide](initial-server-setup-with-ubuntu-16-04). You can name your servers whatever you’d like, but to keep things clear they will be referred to as **server-01** and **server-02** throughout this tutorial.
- **Two DigitalOcean Spaces**. See our [Introduction to DigitalOcean Spaces](an-introduction-to-digitalocean-spaces) for instructions on how to get these up and running.
- **An Access key and a Secret key for your Spaces.** To generate these, visit the [API page](https://cloud.digitalocean.com/settings/api/tokens) in the DigitalOcean Control Panel.

With these prerequisites in place, you are ready to install Duplicacy.

## Installing Duplicacy

The latest Duplicacy CLI version can be downloaded (with no license required for personal users) from the [Duplicacy GitHub repository](https://github.com/gilbertchen/duplicacy/releases) using `wget`.

Run the following commands on **both server-01 and server-02** to download Duplicacy onto each of them (substituting the download link for that of the latest release):

    sudo wget -O /opt/duplicacy https://github.com/gilbertchen/duplicacy/releases/download/v2.0.10/duplicacy_linux_x64_2.0.10

Next, create a symbolic link between the download location and a new directory within `/usr/local/bin`:

    sudo ln -s /opt/duplicacy /usr/local/bin/duplicacy

Finally, make `duplicacy` executable:

    sudo chmod 0755 /opt/duplicacy

Duplicacy should now be installed on each of your Droplets and you are now ready to configure it to use your Space.

## Initializing Your Repository and Configuring Duplicacy

Duplicacy backs up data from the directory level, so before you can begin uploading files to your Space it must be associated with a specific directory or repository on both of your Droplets. To do this, you will need to create a project repository and initialize it using Duplicacy’s `init` command.

The `init` command accepts the following syntax:

    duplicacy init repository_id s3://region@endpoint/space_name

- `repository_id`: This is the label used by Duplicacy to distinguish between different repositories. If you plan to back up the same repository from multiple sources (as we will in the next step of this tutorial), the repository ID should be the same on both Droplets.
- `region`: The `region` is the name of the region in which your Droplet is located. 
- `endpoint`: An endpoint is a static location used by server-side web APIs to specify where certain resources are found. For DigitalOcean Spaces, the endpoint will be the region followed by `.digitaloceanspaces.com`, as in `nyc3.digitaloceanspaces.com`. Your Space’s endpoint name can also be copied directly from the Spaces Control Panel under the “Settings” tab.
- `space_name`: This is the name of your Space which was specified during its creation. Be aware that this is not your Space’s URL. If your Space’s URL is `https://example_space.nyc3.digitaloceanspaces.com`, its name would just be `example_space`. 

If you’d like your backups to go to a specific folder within your Space, add the name of the folder after the name of your space when you run the `init` command. When doing so, remember to follow the folder’s name with a trailing slash:

    duplicacy init repository_id s3://region@endpoint/space_name/folder_name/

Once you have those details on hand, you are ready to create a repository directory **on each of your Droplets** using the `mkdir` command. After that, navigate into your new repositories with `cd`:

    mkdir project-repository
    cd project-repository/

With `project-repository/` as your working directory, run the following `init` command on **server-01**. Be sure to replace the highlighted values with your own details:

    duplicacy init project_01 s3://nyc3@nyc3.digitaloceanspaces.com/example_space

It is worth noting that you can choose to enable encryption with Duplicacy by using the `-e` option with the `init` command, as follows:

    duplicacy init -e project_01 s3://nyc3@nyc3.digitaloceanspaces.com/example_space

When encryption is enabled, Duplicacy will prompt you to enter your encryption password each time you use it to interact with your Space.

Once the `init` command runs, Duplicacy will prompt you for your Access and Secret keys, which can be copied over from the Control Panel’s [API page](https://cloud.digitalocean.com/settings/api/tokens).

    OutputEnter S3 Access Key ID:ExampleAccessKeyGBBI
    Enter S3 Secret Access Key:ExampleSecretKeyEC1wnP2YiHobVcSBaZvLoFXXlnA

And it will output the following:

    Output/home/sammy/project-repository will be backed up to s3://nyc3@nyc3.digitaloceanspaces.com/example_space with id project_01

When you run the `init` command, it creates a directory within your repository called `.duplicacy/` which holds a file named `preferences`. This file contains information about your Space as well as any encryption or storage options you’ve specified. If at a later point you decide to make changes to your Duplicacy configuration, you can either edit the `preferences` file directly or delete it. The file will be recreated the next time you run the `init` command in that repository.

Now repeat the `init` command **on your second Droplet** :

    duplicacy init project_01 s3://nyc3@nyc3.digitaloceanspaces.com/example_space

After adding your Access keys again, you will see a slightly different output than on your first Droplet:

    OutputThe storage 's3://nyc3@nyc3.digitaloceanspaces.com/example_space' has already been initialized
    Compression level: 100
    Average chunk size: 4194304
    Maximum chunk size: 16777216
    Minimum chunk size: 1048576
    Chunk seed: 6475706c6963616379
    /home/sammy/project-repository will be backed up to s3://nyc3@nyc3.digitaloceanspaces.com/example_space with id project_01

Both your servers’ repositories are now initialized, but there’s one more step you may want to take to configure Duplicacy. As it stands, Duplicacy will prompt you for your Access and Secret keys every time you back up your data, which would become tedious rather quickly. To avoid this, you can use Duplicacy’s `set` command to write your Space’s credentials to Duplicacy’s `preferences` file. Run the following commands **on each of your servers** to have Duplicacy save your Access and Secret keys, respectively:

    duplicacy set -key s3_id -value ExampleAccessKeyGBBI
    duplicacy set -key s3_secret -value ExampleSecretKeyEC1wnP2YiHobVcSBaZvLoFXXlnA

You are now ready to use Duplicacy to back up each of your Droplets’ repositories to one of your Spaces!

## Backing Up One Repository from Multiple Sources

Distributed teams can benefit from unobtrusive cloud backup solutions that prevent file conflicts and data loss. By taking a snapshot of an entire repository and uploading it to a Space with a single command, Duplicacy streamlines backups while avoiding file conflicts across multiple machines.

To test out Duplicacy’s backup functionality, use `touch` to populate the `project-repository` **on each of your Droplets** with a couple dummy files:

    touch /project-repository/file-1.txt
    touch /project-repository/file-2.txt

Next, on **server-01** , use Duplicacy’s `backup` command to create a snapshot of your repository and upload it to your Space. Because you’ve initiated your repository with only one storage location, you won’t need to specify any other options to back up your files:

    duplicacy backup

The resulting output should look something like this:

    OutputNo previous backup found
    Indexing /home/mark/project-repository
    Listing all chunks
    Packed file-1.txt (0)
    Packed file-2.txt (0)
    Backup for /home/sammy/project-repository at revision 1 completed

Now try backing up your repository from **server-02** :

    duplicacy backup

    OutputLast backup at revision 1 found
    Indexing /home/sammy/project-repository
    Backup for /home/sammy/project-repository at revision 2 completed

You’ll notice that because the repositories on **server-01** and **server-02** were identical, Duplicacy didn’t pack any files like it did when you ran the `backup` command on your first Droplet. To see what will happen when you back up a slightly different snapshot, open up one of the dummy files on **server-02** and add some text to it:

    nano file-1.txt

project-repository/file-1.txt

    The quick brown fox jumped over the lazy dogs.

Save and close the file by entering `CTRL - X`, `Y`, then `ENTER`, and then run the `backup` command once again:

    duplicacy backup

    OutputStorage set to s3://nyc3@nyc3.digitaloceanspaces.com/example_space
    Last backup at revision 2 found
    Indexing /home/sammy/project-repository
    Packed file-1.txt (45)
    Backup for /home/sammy/project-repository at revision 3 completed

Because there were new changes to one of the files in your repository, Duplicacy packed that file and uploaded it as part of revision 3.

You can use the `restore` command to revert your repository back to a previous revision by using the `-r` option and specifying the revision number. Note that it will not overwrite existing files unless the `-overwrite` option is specified, like this:

    duplicacy restore -overwrite -r 2

After running the `restore` command, you can confirm that Duplicacy did indeed rewrite `file-1.txt` by checking whether it has any contents:

    cat file-1.txt

If this command doesn’t produce any output, then `file-1.txt` is back to being an empty file and you have successfully rolled back your repository to the previous revision.

## Backing up to Multiple Storage Locations

Storing backups at mulitple offsite locations has been [a common data security practice for many years](importance-off-site-backups). However, the process of backing up files to multiple destinations can prove tedious and cause a drop in productivity. There are a number of third-party backup tools, though, that can provide a quick solution to back up data to multiple locations in the cloud.

To demonstrate this functionality in Duplicacy, add your second Space to the repository on **server-01**. You will not be able to do this by running the `init` command again because that repository has already been initiated by Duplicacy and associated with your first Space. For these scenarios, you will need to use the `add` command which connects an already-initialized repository to another storage bucket.

Duplicacy’s `add` command uses the following syntax:

    duplicacy add storage_id repository_id s3://region@endpoint/example_space_02

This looks mostly similar to the `init` command used earlier, with the main difference being that it requires you to specify an ID for the new storage location. When you ran the `init` command above, Duplicacy assigned the `default` ID to your first storage bucket, since that is the default location where it will send backups. The storage name you provide for your second Space can be whatever you’d like, but it may be helpful for it to be something descriptive so you remember which Space it represents.

With that information in mind, add your second Space to the repository:

    duplicacy add space_02 project_01 s3://nyc3@nyc3.digitaloceanspaces.com/example_space_02

You are now all set to back up your repository to your second Space. It’s recommended that you do this by first backing up your repository to your default storage location, and then using Duplicacy’s `copy` command to copy an identical backup over to your second storage location:

    duplicacy backup
    duplicacy copy -from default -to space_02

This will copy over each chunk and snapshot from your first Space over to your second. It’s important to note that the `copy` command is non-destructive, and it will not write over any existing files.

## Conclusion

When combined with DigitalOcean Spaces, Duplicacy allows users to manage cloud backups with flexibility. If you need to back up the same repository from multiple computers or you need to back up one repository to multiple places in the cloud, Duplicacy could become an integral part of your backups solution.

If you’re interested in learning more about how to use Duplicacy, you can check out the [project wiki on GitHub](https://github.com/gilbertchen/duplicacy/wiki). Alternatively, if you’d like to learn more about backup strategies in general, see our guide on [How To Choose an Effective Backup Strategy for your VPS](how-to-choose-an-effective-backup-strategy-for-your-vps) or our comparison between [Object Storage vs. Block Storage Services](object-storage-vs-block-storage-services).
