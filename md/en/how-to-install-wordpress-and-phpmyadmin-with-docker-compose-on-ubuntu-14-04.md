---
author: Nik van der Ploeg
date: 2015-11-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-wordpress-and-phpmyadmin-with-docker-compose-on-ubuntu-14-04
---

# How To Install Wordpress and PhpMyAdmin with Docker Compose on Ubuntu 14.04

## Introduction

[Docker Compose](how-to-install-and-use-docker-compose-on-ubuntu-14-04) makes dealing with the orchestration processes of Docker containers (such as starting up, shutting down, and setting up intra-container linking and volumes) really easy.

This article provides a real-world example of using Docker Compose to install an application, in this case WordPress with PHPMyAdmin as an extra. WordPress normally runs on a LAMP stack, which means Linux, Apache, MySQL/MariaDB, and PHP. The official WordPress Docker image includes Apache and PHP for us, so the only part we have to worry about is MariaDB.

## Prerequisites

To follow this article, you will need the following:

- Ubuntu 14.04 Droplet
- A non-root user with sudo privileges ([Initial Server Setup with Ubuntu 14.04](initial-server-setup-with-ubuntu-14-04) explains how to set this up.)
- Docker and Docker Compose installed from the instructions in [How To Install and Use Docker Compose on Ubuntu 14.04](how-to-install-and-use-docker-compose-on-ubuntu-14-04)

## Step 1 — Installing WordPress

We’ll be using the official [WordPress](https://hub.docker.com/_/wordpress/) and [MariaDB](https://hub.docker.com/_/mariadb/) Docker images. If you’re curious, there’s lots more info about these images and their configuration options on their respective GitHub and Docker Hub pages.

Let’s start by making a folder where our data will live and creating a minimal `docker-compose.yml` file to run our WordPress container:

    mkdir ~/wordpress && cd $_

Then create a `~/wordpress/docker-compose.yml` with your favorite text editor (nano is easy if you don’t have a preference):

    nano ~/wordpress/docker-compose.yml

and paste in the following:

~/wordpress/docker-compose.yml

    wordpress:
      image: wordpress

This just tells Docker Compose to start a new container called `wordpress` and download the `wordpress` image from the Docker Hub.

We can bring the image up like so:

    docker-compose up

You’ll see Docker download and extract the WordPress image from the Docker Hub, and after some time you’ll get some error messages similar to the below:

    Outputwordpress_1 | error: missing WORDPRESS_DB_HOST and MYSQL_PORT_3306_TCP environment variables
    wordpress_1 | Did you forget to --link some_mysql_container:mysql or set an external db
    wordpress_1 | with -e WORDPRESS_DB_HOST=hostname:port?
    dockercompose_wordpress_1 exited with code 1

This is WordPress complaining that it can’t find a database. Let’s add a MariaDB image to the mix and link it up to fix that.

## Step 2 — Installing MariaDB

To add the MariaDB image to the group, re-open `docker-compose.yml` with your text editor:

    nano ~/wordpress/docker-compose.yml

Change `docker-compose.yml` to match the below (be careful with the indentation, YAML files are white-space sensitive)

docker-compose.yml

    wordpress:
      image: wordpress
      links:
        - wordpress_db:mysql
    wordpress_db:
      image: mariadb

What we’ve done here is define a new container called `wordpress_db` and told it to use the `mariadb` image from the Docker Hub. We also told the our `wordpress` container to link our `wordpress_db` container into the `wordpress` container and call it `mysql` (inside the `wordpress` container the hostname `mysql` will be forwarded to our `wordpress_db` container).

If you run `docker-compose up` again, you will see it download the MariaDB image, and you’ll also see that we’re not quite there yet though:

    Outputwordpress_db_1 | error: database is uninitialized and MYSQL_ROOT_PASSWORD not set
    wordpress_db_1 | Did you forget to add -e MYSQL_ROOT_PASSWORD=... ?
    wordpress_1 | error: missing required WORDPRESS_DB_PASSWORD environment variable
    wordpress_1 | Did you forget to -e WORDPRESS_DB_PASSWORD=... ?
    wordpress_1 | 
    wordpress_1 | (Also of interest might be WORDPRESS_DB_USER and WORDPRESS_DB_NAME.)
    wordpress_wordpress_db_1 exited with code 1
    wordpress_wordpress_1 exited with code 1
    Gracefully stopping... (press Ctrl+C again to force)

WordPress is still complaining about being unable to find a database, and now we have a new complaint from MariaDB saying that no root password is set.

It appears that just linking the two containers isn’t quite enough. Let’s go ahead and set the `MYSQL_ROOT_PASSWORD` variable so that we can actually fire this thing up.

Edit the Docker Compose file yet again:

    nano ~/wordpress/docker-compose.yml

Add these two lines to the _end_ of the `wordpress_db` section, but **make sure to change `examplepass` to a more secure password!**

docker-compose.yml

    wordpress_db:
    ...
      environment:
        MYSQL_ROOT_PASSWORD: examplepass
    ...

This will set an environment variable inside the `wordpress_db` container called `MYSQL_ROOT_PASSWORD` with your desired password. The MariaDB Docker image is configured to check for this environment variable when it starts up and will take care of setting up the DB with a root account with the password defined as `MYSQL_ROOT_PASSWORD`.

While we’re at it, let’s also set up a port forward so that we can connect to our WordPress install once it actually loads up. Under the `wordpress` section add these two lines:

docker-compose.yml

    wordpress:
    ...
      ports:
        - 8080:80
    ...

The first port number is the port number on the host, and the second port number is the port inside the container. So, this configuration forwards requests on port 8080 of the host to the default web server port 80 inside the container.

**Note:** If you would like Wordpress to run on the default web server port 80 on the host, change the previous line to `80:80` so that requests to port 80 on the host are forwarded to port 80 inside the Wordpress container.

Your complete `docker-compose.yml` file should now look like this:

docker-compose.yml

    wordpress:
      image: wordpress
      links:
        - wordpress_db:mysql
      ports:
        - 8080:80
    wordpress_db:
      image: mariadb
      environment:
        MYSQL_ROOT_PASSWORD: examplepass

With this configuration we can actually go ahead and fire up WordPress. This time, let’s run it with the `-d` option, which will tell `docker-compose` to run the containers in the background so that you can keep using your terminal:

    docker-compose up -d

You’ll see a whole bunch of text fly by your screen. Once it’s calmed down, open up a web browser and browse to the IP  
of your DigitalOcean box on port 8080 (for example, if the IP address of your server is 123.456.789.123 you should type [http://123.456.789.123:8080](http://123.456.789.123:8080) into your browser.)

You should see a fresh WordPress installation page and be able to complete the install and blog as usual.

Because these are both official Docker images and are following all of Docker’s best practices, each of these images have pre-defined, persistent volumes for you — meaning that if you restart the container, your blog posts will still be there. You can learn more about working with Docker volumes in the [Docker data volumes tutorial](how-to-work-with-docker-data-volumes-on-ubuntu-14-04).

## Step 3 — Adding a PhpMyAdmin Container

Great, that was relatively painless. Let’s try getting a little fancy.

So far we’ve only been using official images, which the Docker team takes great pains to ensure are accurate. You may have noticed that we didn’t have to give the WordPress container any environment variables to configure it. As soon as we linked it up to a properly configured MariaDB container everything just worked.

This is because there’s a script inside the WordPress Docker container that actually grabs the `MYSQL_ROOT_PASSWORD` variable from our `wordpress_db` container and uses that to connect to WordPress.

Let’s venture out of the official image area a little bit and use a [community contributed PhpMyAdmin image](https://hub.docker.com/r/corbinu/docker-phpmyadmin/). Go ahead and edit `docker-compose.yml` one more time:

    nano docker-compose.yml

Paste the following at the end of the file:

docker-compose.yml

    phpmyadmin:
      image: corbinu/docker-phpmyadmin
      links:
        - wordpress_db:mysql
      ports:
        - 8181:80
      environment:
        MYSQL_USERNAME: root
        MYSQL_ROOT_PASSWORD: examplepass

Be sure to replace examplepass with the exact same root password from the `wordpress_db` container you setup earlier.

This grabs `docker-phpmyadmin` by community member `corbinu`, links it to our `wordpress_db` container with the name `mysql` (meaning from inside the `phpmyadmin` container references to the hostname `mysql` will be forwarded to our `wordpress_db` container), exposes its port 80 on port 8181 of the host system, and finally sets a couple of environment variables with our MariaDB username and password. This image does not automatically grab the `MYSQL_ROOT_PASSWORD` environment variable from the `wordpress_db` container’s environment the way the `wordpress` image does. We actually have to copy the `MYSQL_ROOT_PASSWORD: examplepass` line from the `wordpress_db` container, and set the username to `root`.

The complete `docker-compose.yml` file should now look like this:

docker-compose.yml

    wordpress:
      image: wordpress
      links:
        - wordpress_db:mysql
      ports:
        - 8080:80
    wordpress_db:
      image: mariadb
      environment:
        MYSQL_ROOT_PASSWORD: examplepass
    phpmyadmin:
      image: corbinu/docker-phpmyadmin
      links:
        - wordpress_db:mysql
      ports:
        - 8181:80
      environment:
        MYSQL_USERNAME: root
        MYSQL_ROOT_PASSWORD: examplepass

Now start up the application group again:

    docker-compose up -d

You will see PhpMyAdmin being installed. Once it is finished, visit your server’s IP address again (this time using port 8181, e.g. [http://123.456.789.123:8181](http://123.456.789.123:8181)). You’ll be greeted by the PhpMyAdmin login screen.

Go ahead and login using username `root` and password you set in the YAML file, and you’ll be able to browse your database. You’ll notice that the server includes a `wordpress` database, which contains all the data from your WordPress install.

You can add as many containers as you like this way and link them all up in any way you please. As you can see, the approach is quite powerful —instead of dealing with the configuration and prerequisites for each individual components and setting them all up on the same server, you get to plug the pieces together like Lego blocks and add components piecemeal. Using tools like [Docker Swarm](https://docs.docker.com/swarm/install-w-machine/) you can even transparently run these containers over multiple servers! That’s a bitoutside the scope of this tutorial though. Docker provides some [documentation](([https://docs.docker.com/swarm/install-w-machine/)](https://docs.docker.com/swarm/install-w-machine/))) on it if you are interested.

## Step 4 — Creating the WordPress Site

Since all the files for your new WordPress site are stored inside your Docker container, what happens to your files when you stop the container and start it again?

By default, the document root for the WordPress container is persistent. This is because the WordPress image from the Docker Hub is configured this way. If you make a change to your WordPress site, stop the application group, and start it again, your website will still have the changes you made.

Let’s try it.

Go to your WordPress from a web browser (e.g. [http://123.456.789.123:8080](http://123.456.789.123:8080)). Edit the **Hello World!** post that already exists. Then, stop all the Docker containers with the following command:

    docker-compose stop

Try loading the WordPress site again. You will see that the website is down. Start the Docker containers again:

    docker-compose up -d

Again, load the WordPress site. You should see your blog site and the change you made earlier. This shows that the changes you make are saved even when the containers are stopped.

## Step 5 — Storing the Document Root on the Host Filesystem (Optional)

It is possible to store the document root for WordPress on the host filesystem using a Docker data volume to share files between the host and the container.

**Note:** For more details on working with Docker data volumes, take a look at the [Docker data volumes tutorial](how-to-work-with-docker-data-volumes-on-ubuntu-14-04).

Let’s give it a try. Open up your `docker-compose.yml` file one more time:

    nano ~/wordpress/docker-compose.yml

in the `wordpress:` section add the following lines:

~/wordpress/docker-compose.yml

    wordpress:
    ...
      volumes:
        - ~/wordpress/wp_html:/var/www/html
        ...

Stop your currently running `docker-compose` session:

    docker-compose stop

Remove the existing container so we can map the volume to the host filesystem:

    docker-compose rm wordpress

Start WordPress again:

    docker-compose -d

Once the prompt returns, WordPress should be up and running again&nbsp;—&nbsp;this time using the host filesystem to store the document root.

If you look in your `~/wordpress` directory, you’ll see that there is now a `wp_html` directory in it:

    ls ~/wordpress

All of the WordPress source files are inside it. Changes you make will be picked up by the WordPress container in real time.

This experience was a little smoother than it normally would be —&nbsp;the WordPress Docker container is configured to check if `/var/www/html` is empty or not when it starts and copies files there appropriately. Usually you will have to do this step yourself.

## Conclusion

You should have a full WordPress deploy up and running. You should be able to use the same method to deploy quite a wide variety of systems using the images available on the Docker Hub. Be sure to figure out which volumes are persistent and which are not for each container you  
create.

Happy Dockering!
