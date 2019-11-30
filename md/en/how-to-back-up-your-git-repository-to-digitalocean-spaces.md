---
author: Sebastian Canevari
date: 2017-12-26
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-back-up-your-git-repository-to-digitalocean-spaces
---

# How To Back Up Your Git Repository To DigitalOcean Spaces

## Introduction

Relying on a source code repository for versioning is a best practice that can get us back up and running when a code change causes our application to crash or to behave erratically. However, in case of a catastrophic event like a full branch getting accidentally deleted or losing access to a repository, we should leverage additional disaster recovery strategies.

Backing up our code repository into an object storage infrastructure provides us with an off-site copy of our data that we can recover when needed. [Spaces](https://www.digitalocean.com/products/object-storage) is DigitalOcean’s object storage solution that offers a destination for users to store backups of digital assets, documents, and code.

Compatible with the S3 API, Spaces allows us to use S3 tools like S3cmd to interface with it. [S3cmd](http://s3tools.org/s3cmd) is a client tool that we can use for uploading, retrieving, and managing data from object storage through the command line or through scripting.

In this tutorial we will demonstrate how to back up a remote Git repository into a DigitalOcean Space using S3cmd. To achieve this goal, we will install and configure Git, install S3cmd, and create scripts to back up the Git repository into our Space.

## Prerequisites

In order to work with Spaces, you’ll need a DigitalOcean account. If you don’t already have one, you can register on the [signup page](https://cloud.digitalocean.com/registrations/new).

From there, you’ll need to set up your DigitalOcean Space and create an API key, which you can achieve by following our tutorial [How To Create a DigitalOcean Space and API Key](how-to-create-a-digitalocean-space-and-api-key).

Once created, you’ll need to keep the following details about your Space handy:

- Access Key
- Secret Key (also called token)

Additionally, you should have an Ubuntu 16.04 server set up with a sudo non-root user. You can get guidance for setting this up by following [this Ubuntu 16.04 initial server setup tutorial](initial-server-setup-with-ubuntu-16-04).

Once you have your Spaces information and server set up, proceed to the next section to install Git.

## Install Git

In this tutorial, we’ll be working with a remote Git repository that we’ll clone to our server. Ubuntu has Git installed and ready to use in its default repositories, but this version may be older than the most recent available release.

We can use the `apt` package management tools to update the local package index and to download and install the most recent available version of Git.

    sudo apt-get update
    sudo apt-get install git

For a more flexible way to install Git and to ensure that you have the latest release, you can consider [installing Git from Source](how-to-install-git-on-ubuntu-16-04#how-to-install-git-from-source).

We’ll be backing up from a Git repository’s URL, so we will not need to configure Git in this tutorial. For guidance on configuring Git, read this section on [How To Set Up Git](how-to-install-git-on-ubuntu-16-04#how-to-set-up-git).

Now we’ll move on to cloning our remote Git repository.

## Clone a Remote Git Repository

In order to clone our Git repository, we’ll create a script to perform the task. Creating a script allows us to use variables and helps ensure that we do not make errors on the command line.

To write our executable script, we’ll create a new shell script file called `cloneremote.sh` with the text editor nano.

    nano cloneremote.sh

Within this blank file, let’s write the following script.

cloneremote.sh

    #!/bin/bash
    
    remoterepo=your_remote_repository_url
    localclonedir=repos
    clonefilename=demoprojectlocal.git
    
    git clone --mirror $remoterepo $localclonedir/$clonefilename

Let’s walk through each element of this script.

The first line — `#!/bin/bash` — indicates that the script will be run by the Bash shell. From there, we define the variables that will be used in the command, which will run once we execute the script. These variables define the following pieces of configuration:

- `remoterepo` is being assigned the remote Git repository URL that we will be backing up from
- `localclonedir` refers to the server directory or folder that we will be cloning the remote repository into, in this case we have called it `repos`
- `clonefilename` refers to the filename we will provide to the local cloned repository, in this case we have called it `demoprojectlocal.git`

Each of these variables are then called directly in the command at the end of the script.

The last line of the script uses the Git command line client beginning with the `git` command. From there, we are requesting to clone a repository with `clone`, and executing it as a mirror version of the repository with the `--mirror` tag. This means that the cloned repository will be exactly the same as the original one. The three variables that we defined above are called with `$`.

When you are satisfied that the script you have written is accurate, you can exit nano by typing the `CTRL` + `x` keys, and when prompted to save the file press `y`.

At this point we can run the shell script with the following command.

    sh cloneremote.sh

Once you run the command, you’ll receive output similar to the following.

    OutputCloning into bare repository './repos/demoprojectlocal.git'...
    remote: Counting objects: 3, done.
    remote: Total 3 (delta 0), reused 0 (delta 0)
    Receiving objects: 100% (3/3), done.
    Checking connectivity... done.

At this point, if you list the items in your current directory, you should see your backup directory there, and if you move into that directory you’ll see the sub-folder with the filename that you provided in the script. That subdirectory is the clone of the Git repository.

With our remote Git repository cloned, we can now move on to installing S3cmd, which we can use to back up the repository into object storage.

## Install S3cmd

The S3cmd tool allows us to connect to the Spaces environment from the command line. We’ll download the latest version of S3cmd from its [public GitHub repository](https://github.com/s3tools/s3cmd) and follow the recommended guidelines for installing it.

Before installing S3cmd, we need to install Python’s Setuptools, as it will help with our installation (S3cmd is written in Python).

    sudo apt-get install python-setuptools

Press `y` to continue.

With this downloaded, we can now download the S3cmd `tar.gz` file with `curl`.

    cd /tmp
    curl -LO https://github.com/s3tools/s3cmd/releases/download/v2.0.1/s3cmd-2.0.1.tar.gz

Note that we are downloading the file into our `tmp` directory. This a common practice when downloading files onto our server.

You can check to see if there is a newer version of S3cmd available by visiting the [Releases page](https://github.com/s3tools/s3cmd/releases) of the tool’s GitHub repository. If you find a newer version, you can copy the `tar.gz` URL and substitute it into the `curl` command above.

When the download has completed, unzip and unpack the file using the tar utility:

    cd ~
    tar xf /tmp/s3cmd-*.tar.gz

In the commands above, we changed back to our home directory then executed the `tar` command. We used two flags with the command, the `x` indicates that we want to e **x** tract from a tar file and, and the `f` indicates that the immediately adjacent string will be the full path name of the file that we want to expand from. In the file path of the tar file, we also indicate that it is in the `tmp` directory.

Once the file is extracted, change into the resulting directory and install the software using sudo:

    cd s3cmd-*
    sudo python setup.py install

For the above command to run, we need to use `sudo`. The `python` command is a call to the Python interpreter to install the `setup.py` Python script.

Test the install by asking S3cmd for its version information:

    s3cmd --version

    Outputs3cmd version 2.0.1

If you see similar output, S3cmd has been successfully installed. Next, we’ll configure S3cmd to connect to our object storage service.

## Configure S3cmd

S3cmd has an interactive configuration process that can create the configuration file we need to connect to our object storage server. During the configuration process, you will be asked for your Access Key and Secret Key, so have them readily available.

Let’s start the configuration process by typing the following command:

    s3cmd --configure

We are prompted to enter our keys, so let’s paste them in and then accept `US` for the **Default Region**. It is worth noting that being able to modify the Default Region is relevant for the AWS infrastructure that the S3cmd tool was originally created to work with. Because DigitalOcean requires fewer pieces of information for configuration, this is not relevant so we accept the default.

    Enter new values or accept defaults in brackets with Enter.
    Refer to user manual for detailed description of all options.
    Access key and Secret key are your identifiers for Amazon S3. Leave them empty for using the env variables.
    Access Key []: EXAMPLE7UQOTHDTF3GK4
    Secret Key []: b8e1ec97b97bff326955375c5example
    Default Region [US]:

Next, we’ll enter the DigitalOcean endpoint, `nyc3.digitaloceanspaces.com`.

    Use "s3.amazonaws.com" for S3 Endpoint and not modify it to the target Amazon S3.
    S3 Endpoint [s3.amazonaws.com]: nyc3.digitaloceanspaces.com

Because Spaces supports DNS-based buckets, at the next prompt we’ll supply the bucket value in the required format:

    %(bucket)s.nyc3.digitaloceanspaces.com

    Use "%(bucket)s.s3.amazonaws.com" to the target Amazon S3. "%(bucket)s" and "%(location)s" vars c
    an be used if the target S3 system supports dns based buckets.
    DNS-style bucket+hostname:port template for accessing a bucket []: %(bucket)s.nyc3.digitaloceanspaces.com

At this point, we’re asked to supply an encryption password. We’ll enter a password so it will be available in the event we want to use encryption.

    Encryption password is used to protect your files from reading
    by unauthorized persons while in transfer to S3
    Encryption password: secure_password
    Path to GPG program [/usr/bin/gpg]:

We’re next prompted to connect via HTTPS, but DigitalOcean Spaces does not support unencrypted transfer, so we’ll press `ENTER` to accept the default, `Yes`.

    When using secure HTTPS protocol all communication with Amazon S3
    servers is protected from 3rd party eavesdropping. This method is
    slower than plain HTTP, and can only be proxied with Python 2.7 or newer
    Use HTTPS protocol [Yes]: 

Since we aren’t using an HTTP Proxy server, we’ll leave the next prompt blank and press `ENTER`.

    On some networks all internet access must go through a HTTP proxy.
    Try setting it here if you can't connect to S3 directly
    HTTP Proxy server name:

After the prompt for the HTTP Proxy server name, the configuration script presents a summary of the values it will use, followed by the opportunity to test them. When the test completes successfully, enter `Y` to save the settings.

Once you save the configuration, you’ll receive confirmation of its location.

When you have completed all the installation steps, you can double-check that your setup is correct by running the following command.

    s3cmd ls

This command should output a list of Spaces that you have available under the credentials you provided.

    Output2017-12-15 02:52 s3://demospace

This confirms that we have successfully connected to our DigitalOcean Spaces. We can now move on to backing up our Git repository into object storage.

## Back Up Git Repository into Object Storage

With all of our tools installed and configured, we are now going to create a script that will zip the local repository and push it into our DigitalOcean Space.

From our home directory, let’s call our script `movetospaces.sh` and open it in nano.

    cd ~
    nano movetospaces.sh

We’ll write our script as follows.

movetospaces.sh

    #!/bin/sh
    
    tar -zcvf archivedemoproject.tar.gz /repos/demoprojectlocal.git
    ./s3cmd-2.0.1/s3cmd put archivedemoproject.tar.gz s3://demospace

Earlier in this tutorial, we’ve used `tar` to unzip `s3cmd`, we are now using `tar` to zip the Git repository before sending it to Spaces. In the `tar` command, we specify four flags:

- `z` compresses using the gzip method
- `c` creates a new file instead of using an existing one
- `v` indicates that we are being verbose about the files being included in the compressed file
- `f` names the resulting file with the name defined in the next string 

After the flags, we are providing a file name for the compressed file, in this case `archivedemoproject.tar.gz`. We are also providing the name of the directory that we want to zip `/repos/demoprojectlocal.git`.

The script then executes `s3cmd put` to send `archivedemoproject.tar.gz` to our destination Space `s3://demospace`.

Among the commands you may commonly use with S3cmd, the `put` command sends files to Spaces. Other commands that may be useful include the `get` command to download files from the Space, and the `delete` command to delete files. You can obtain a list of all commands accepted by S3cmd by executing `s3cmd` with no options.

To copy your backup into your Space, we’ll execute the script.

    sh movetospaces.sh

You will see the following output:

    Outputdemoprojectlocal.git/
    ...
    demoprojectlocal.git/packed-refs
    upload: 'archivedemoproject.tar.gz' -> 's3://demobucket/archivedemoproject.tar.gz' [1 of 1]
     6866 of 6866 100% in 0s 89.77 kB/s done

You can check that the process worked correctly by running the following command:

    s3cmd ls s3://demospace

You’ll see the following output, indicating that the file is in your Space.

    Output2017-12-18 20:31 6866 s3://demospace/archivedemoproject.tar.gz

We now have successfully backed up our Git repository into our DigitalOcean Space.

## Conclusion

To ensure that code can be quickly recovered if needed, it is important to maintain backups. In this tutorial, we covered how to back up a remote Git repository into a DigitalOcean Space through using Git, the S3cmd client, and shell scripts. This is just one method of dozens of possible scenarios in which you can use Spaces to help with your disaster recovery and data consistency strategies.

You can learn more about what we can store in object storage by reading the following tutorials:

- [How To Use Logrotate and S3cmd to Archive Logs to Object Storage on Ubuntu 16.04](how-to-use-logrotate-and-s3cmd-to-archive-logs-to-object-storage-on-ubuntu-16-04)
- [How To Back Up Data to an Object Storage Service with the Restic Backup Client](how-to-back-up-data-to-an-object-storage-service-with-the-restic-backup-client)
- [How To Back Up a Synology NAS to DigitalOcean Spaces](how-to-back-up-a-synology-nas-to-digitalocean-spaces)
