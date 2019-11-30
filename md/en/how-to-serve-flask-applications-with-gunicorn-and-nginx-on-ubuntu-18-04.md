---
author: Justin Ellingwood, Kathleen Juell
date: 2018-07-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-serve-flask-applications-with-gunicorn-and-nginx-on-ubuntu-18-04
---

# How To Serve Flask Applications with Gunicorn and Nginx on Ubuntu 18.04

## Introduction

In this guide, you will build a Python application using the Flask microframework on Ubuntu 18.04. The bulk of this article will be about how to set up the [Gunicorn application server](http://gunicorn.org/) and how to launch the application and configure [Nginx](https://www.nginx.com/) to act as a front-end reverse proxy.

## Prerequisites

Before starting this guide, you should have:

- A server with Ubuntu 18.04 installed and a non-root user with sudo privileges. Follow our [initial server setup guide](initial-server-setup-with-ubuntu-18-04) for guidance.
- Nginx installed, following Steps 1 and 2 of [How To Install Nginx on Ubuntu 18.04](how-to-install-nginx-on-ubuntu-18-04).
- A domain name configured to point to your server. You can purchase one on [Namecheap](https://namecheap.com) or get one for free on [Freenom](http://www.freenom.com/en/index.html). You can learn how to point domains to DigitalOcean by following the relevant [documentation on domains and DNS](https://www.digitalocean.com/docs/networking/dns/). Be sure to create the following DNS records:

- Familiarity with the WSGI specification, which the Gunicorn server will use to communicate with your Flask application. [This discussion](how-to-set-up-uwsgi-and-nginx-to-serve-python-apps-on-ubuntu-14-04#definitions-and-concepts) covers WSGI in more detail. 

## Step 1 — Installing the Components from the Ubuntu Repositories

Our first step will be to install all of the pieces we need from the Ubuntu repositories. This includes `pip`, the Python package manager, which will manage our Python components. We will also get the Python development files necessary to build some of the Gunicorn components.

First, let’s update the local package index and install the packages that will allow us to build our Python environment. These will include `python3-pip`, along with a few more packages and development tools necessary for a robust programming environment:

    sudo apt update
    sudo apt install python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools

With these packages in place, let’s move on to creating a virtual environment for our project.

## Step 2 — Creating a Python Virtual Environment

Next, we’ll set up a virtual environment in order to isolate our Flask application from the other Python files on the system.

Start by installing the `python3-venv` package, which will install the `venv` module:

    sudo apt install python3-venv

Next, let’s make a parent directory for our Flask project. Move into the directory after you create it:

    mkdir ~/myproject
    cd ~/myproject

Create a virtual environment to store your Flask project’s Python requirements by typing:

    python3.6 -m venv myprojectenv

This will install a local copy of Python and `pip` into a directory called `myprojectenv` within your project directory.

Before installing applications within the virtual environment, you need to activate it. Do so by typing:

    source myprojectenv/bin/activate

Your prompt will change to indicate that you are now operating within the virtual environment. It will look something like this: `(myprojectenv)user@host:~/myproject$`.

## Step 3 — Setting Up a Flask Application

Now that you are in your virtual environment, you can install Flask and Gunicorn and get started on designing your application.

First, let’s install `wheel` with the local instance of `pip` to ensure that our packages will install even if they are missing wheel archives:

    pip install wheel

Note
Regardless of which version of Python you are using, when the virtual environment is activated, you should use the `pip` command (not `pip3`).  

Next, let’s install Flask and Gunicorn:

    pip install gunicorn flask

### Creating a Sample App

Now that you have Flask available, you can create a simple application. Flask is a microframework. It does not include many of the tools that more full-featured frameworks might, and exists mainly as a module that you can import into your projects to assist you in initializing a web application.

While your application might be more complex, we’ll create our Flask app in a single file, called `myproject.py`:

    nano ~/myproject/myproject.py

The application code will live in this file. It will import Flask and instantiate a Flask object. You can use this to define the functions that should be run when a specific route is requested:

~/myproject/myproject.py

    from flask import Flask
    app = Flask( __name__ )
    
    @app.route("/")
    def hello():
        return "<h1 style='color:blue'>Hello There!</h1>"
    
    if __name__ == " __main__":
        app.run(host='0.0.0.0')

This basically defines what content to present when the root domain is accessed. Save and close the file when you’re finished.

If you followed the initial server setup guide, you should have a UFW firewall enabled. To test the application, you need to allow access to port `5000`:

    sudo ufw allow 5000

Now you can test your Flask app by typing:

    python myproject.py

You will see output like the following, including a helpful warning reminding you not to use this server setup in production:

    Output* Serving Flask app "myproject" (lazy loading)
     * Environment: production
       WARNING: Do not use the development server in a production environment.
       Use a production WSGI server instead.
     * Debug mode: off
     * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)

Visit your server’s IP address followed by `:5000` in your web browser:

    http://your_server_ip:5000

You should see something like this:

![Flask sample app](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_uwsgi_wsgi_1404/test_app.png)

When you are finished, hit `CTRL-C` in your terminal window to stop the Flask development server.

### Creating the WSGI Entry Point

Next, let’s create a file that will serve as the entry point for our application. This will tell our Gunicorn server how to interact with the application.

Let’s call the file `wsgi.py`:

    nano ~/myproject/wsgi.py

In this file, let’s import the Flask instance from our application and then run it:

~/myproject/wsgi.py

    from myproject import app
    
    if __name__ == " __main__":
        app.run()

Save and close the file when you are finished.

## Step 4 — Configuring Gunicorn

Your application is now written with an entry point established. We can now move on to configuring Gunicorn.

Before moving on, we should check that Gunicorn can serve the application correctly.

We can do this by simply passing it the name of our entry point. This is constructed as the name of the module (minus the `.py` extension), plus the name of the callable within the application. In our case, this is `wsgi:app`.

We’ll also specify the interface and port to bind to so that the application will be started on a publicly available interface:

    cd ~/myproject
    gunicorn --bind 0.0.0.0:5000 wsgi:app

You should see output like the following:

    Output[2018-07-13 19:35:13 +0000] [28217] [INFO] Starting gunicorn 19.9.0
    [2018-07-13 19:35:13 +0000] [28217] [INFO] Listening at: http://0.0.0.0:5000 (28217)
    [2018-07-13 19:35:13 +0000] [28217] [INFO] Using worker: sync
    [2018-07-13 19:35:13 +0000] [28220] [INFO] Booting worker with pid: 28220

Visit your server’s IP address with `:5000` appended to the end in your web browser again:

    http://your_server_ip:5000

You should see your application’s output:

![Flask sample app](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_uwsgi_wsgi_1404/test_app.png)

When you have confirmed that it’s functioning properly, press `CTRL-C` in your terminal window.

We’re now done with our virtual environment, so we can deactivate it:

    deactivate

Any Python commands will now use the system’s Python environment again.

Next, let’s create the systemd service unit file. Creating a systemd unit file will allow Ubuntu’s init system to automatically start Gunicorn and serve the Flask application whenever the server boots.

Create a unit file ending in `.service` within the `/etc/systemd/system` directory to begin:

    sudo nano /etc/systemd/system/myproject.service

Inside, we’ll start with the `[Unit]` section, which is used to specify metadata and dependencies. Let’s put a description of our service here and tell the init system to only start this after the networking target has been reached:

/etc/systemd/system/myproject.service

    [Unit]
    Description=Gunicorn instance to serve myproject
    After=network.target

Next, let’s open up the `[Service]` section. This will specify the user and group that we want the process to run under. Let’s give our regular user account ownership of the process since it owns all of the relevant files. Let’s also give group ownership to the `www-data` group so that Nginx can communicate easily with the Gunicorn processes. Remember to replace the username here with your username:

/etc/systemd/system/myproject.service

    [Unit]
    Description=Gunicorn instance to serve myproject
    After=network.target
    
    [Service]
    User=sammy
    Group=www-data

Next, let’s map out the working directory and set the `PATH` environmental variable so that the init system knows that the executables for the process are located within our virtual environment. Let’s also specify the command to start the service. This command will do the following:

- Start 3 worker processes (though you should adjust this as necessary)
- Create and bind to a Unix socket file, `myproject.sock`, within our project directory. We’ll set an umask value of `007` so that the socket file is created giving access to the owner and group, while restricting other access
- Specify the WSGI entry point file name, along with the Python callable within that file (`wsgi:app`)

Systemd requires that we give the full path to the Gunicorn executable, which is installed within our virtual environment.

Remember to replace the username and project paths with your own information:

/etc/systemd/system/myproject.service

    [Unit]
    Description=Gunicorn instance to serve myproject
    After=network.target
    
    [Service]
    User=sammy
    Group=www-data
    WorkingDirectory=/home/sammy/myproject
    Environment="PATH=/home/sammy/myproject/myprojectenv/bin"
    ExecStart=/home/sammy/myproject/myprojectenv/bin/gunicorn --workers 3 --bind unix:myproject.sock -m 007 wsgi:app

Finally, let’s add an `[Install]` section. This will tell systemd what to link this service to if we enable it to start at boot. We want this service to start when the regular multi-user system is up and running:

/etc/systemd/system/myproject.service

    [Unit]
    Description=Gunicorn instance to serve myproject
    After=network.target
    
    [Service]
    User=sammy
    Group=www-data
    WorkingDirectory=/home/sammy/myproject
    Environment="PATH=/home/sammy/myproject/myprojectenv/bin"
    ExecStart=/home/sammy/myproject/myprojectenv/bin/gunicorn --workers 3 --bind unix:myproject.sock -m 007 wsgi:app
    
    [Install]
    WantedBy=multi-user.target

With that, our systemd service file is complete. Save and close it now.

We can now start the Gunicorn service we created and enable it so that it starts at boot:

    sudo systemctl start myproject
    sudo systemctl enable myproject

Let’s check the status:

    sudo systemctl status myproject

You should see output like this:

    Output● myproject.service - Gunicorn instance to serve myproject
       Loaded: loaded (/etc/systemd/system/myproject.service; enabled; vendor preset: enabled)
       Active: active (running) since Fri 2018-07-13 14:28:39 UTC; 46s ago
     Main PID: 28232 (gunicorn)
        Tasks: 4 (limit: 1153)
       CGroup: /system.slice/myproject.service
               ├─28232 /home/sammy/myproject/myprojectenv/bin/python3.6 /home/sammy/myproject/myprojectenv/bin/gunicorn --workers 3 --bind unix:myproject.sock -m 007
               ├─28250 /home/sammy/myproject/myprojectenv/bin/python3.6 /home/sammy/myproject/myprojectenv/bin/gunicorn --workers 3 --bind unix:myproject.sock -m 007
               ├─28251 /home/sammy/myproject/myprojectenv/bin/python3.6 /home/sammy/myproject/myprojectenv/bin/gunicorn --workers 3 --bind unix:myproject.sock -m 007
               └─28252 /home/sammy/myproject/myprojectenv/bin/python3.6 /home/sammy/myproject/myprojectenv/bin/gunicorn --workers 3 --bind unix:myproject.sock -m 007

If you see any errors, be sure to resolve them before continuing with the tutorial.

## Step 5 — Configuring Nginx to Proxy Requests

Our Gunicorn application server should now be up and running, waiting for requests on the socket file in the project directory. Let’s now configure Nginx to pass web requests to that socket by making some small additions to its configuration file.

Begin by creating a new server block configuration file in Nginx’s `sites-available` directory. Let’s call this `myproject` to keep in line with the rest of the guide:

    sudo nano /etc/nginx/sites-available/myproject

Open up a server block and tell Nginx to listen on the default port `80`. Let’s also tell it to use this block for requests for our server’s domain name:

/etc/nginx/sites-available/myproject

    server {
        listen 80;
        server_name your_domain www.your_domain;
    }

Next, let’s add a location block that matches every request. Within this block, we’ll include the `proxy_params` file that specifies some general proxying parameters that need to be set. We’ll then pass the requests to the socket we defined using the `proxy_pass` directive:

/etc/nginx/sites-available/myproject

    server {
        listen 80;
        server_name your_domain www.your_domain;
    
        location / {
            include proxy_params;
            proxy_pass http://unix:/home/sammy/myproject/myproject.sock;
        }
    }

Save and close the file when you’re finished.

To enable the Nginx server block configuration you’ve just created, link the file to the `sites-enabled` directory:

    sudo ln -s /etc/nginx/sites-available/myproject /etc/nginx/sites-enabled

With the file in that directory, you can test for syntax errors:

    sudo nginx -t

If this returns without indicating any issues, restart the Nginx process to read the new configuration:

    sudo systemctl restart nginx

Finally, let’s adjust the firewall again. We no longer need access through port `5000`, so we can remove that rule. We can then allow full access to the Nginx server:

    sudo ufw delete allow 5000
    sudo ufw allow 'Nginx Full'

You should now be able to navigate to your server’s domain name in your web browser:

    http://your_domain

You should see your application’s output:

![Flask sample app](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/nginx_uwsgi_wsgi_1404/test_app.png)

If you encounter any errors, trying checking the following:

- `sudo less /var/log/nginx/error.log`: checks the Nginx error logs.
- `sudo less /var/log/nginx/access.log`: checks the Nginx access logs.
- `sudo journalctl -u nginx`: checks the Nginx process logs.
- `sudo journalctl -u myproject`: checks your Flask app’s Gunicorn logs.

## Step 6 — Securing the Application

To ensure that traffic to your server remains secure, let’s get an SSL certificate for your domain. There are multiple ways to do this, including getting a free certificate from [Let’s Encrypt](https://letsencrypt.org/), [generating a self-signed certificate](how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-18-04), or [buying one from another provider](how-to-install-an-ssl-certificate-from-a-commercial-certificate-authority) and configuring Nginx to use it by following Steps 2 through 6 of &nbsp;[How to Create a Self-signed SSL Certificate for Nginx in Ubuntu 18.04](how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-18-04#step-2-%E2%80%93-configuring-nginx-to-use-ssl). We will go with option one for the sake of expediency.

First, add the Certbot Ubuntu repository:

    sudo add-apt-repository ppa:certbot/certbot

You’ll need to press `ENTER` to accept.

Install Certbot’s Nginx package with `apt`:

    sudo apt install python-certbot-nginx

Certbot provides a variety of ways to obtain SSL certificates through plugins. The Nginx plugin will take care of reconfiguring Nginx and reloading the config whenever necessary. To use this plugin, type the following:

    sudo certbot --nginx -d your_domain -d www.your_domain

This runs `certbot` with the `--nginx` plugin, using `-d` to specify the names we’d like the certificate to be valid for.

If this is your first time running `certbot`, you will be prompted to enter an email address and agree to the terms of service. After doing so, `certbot` will communicate with the Let’s Encrypt server, then run a challenge to verify that you control the domain you’re requesting a certificate for.

If that’s successful, `certbot` will ask how you’d like to configure your HTTPS settings:

    OutputPlease choose whether or not to redirect HTTP traffic to HTTPS, removing HTTP access.
    -------------------------------------------------------------------------------
    1: No redirect - Make no further changes to the webserver configuration.
    2: Redirect - Make all requests redirect to secure HTTPS access. Choose this for
    new sites, or if you're confident your site works on HTTPS. You can undo this
    change by editing your web server's configuration.
    -------------------------------------------------------------------------------
    Select the appropriate number [1-2] then [enter] (press 'c' to cancel):

Select your choice then hit `ENTER`. The configuration will be updated, and Nginx will reload to pick up the new settings. `certbot` will wrap up with a message telling you the process was successful and where your certificates are stored:

    OutputIMPORTANT NOTES:
     - Congratulations! Your certificate and chain have been saved at:
       /etc/letsencrypt/live/your_domain/fullchain.pem
       Your key file has been saved at:
       /etc/letsencrypt/live/your_domain/privkey.pem
       Your cert will expire on 2018-07-23. To obtain a new or tweaked
       version of this certificate in the future, simply run certbot again
       with the "certonly" option. To non-interactively renew *all* of
       your certificates, run "certbot renew"
     - Your account credentials have been saved in your Certbot
       configuration directory at /etc/letsencrypt. You should make a
       secure backup of this folder now. This configuration directory will
       also contain certificates and private keys obtained by Certbot so
       making regular backups of this folder is ideal.
     - If you like Certbot, please consider supporting our work by:
    
       Donating to ISRG / Let's Encrypt: https://letsencrypt.org/donate
       Donating to EFF: https://eff.org/donate-le
    

If you followed the Nginx installation instructions in the prerequisites, you will no longer need the redundant HTTP profile allowance:

    sudo ufw delete allow 'Nginx HTTP'

To verify the configuration, navigate once again to your domain, using `https://`:

    https://your_domain

You should see your application output once again, along with your browser’s security indicator, which should indicate that the site is secured.

## Conclusion

In this guide, you created and secured a simple Flask application within a Python virtual environment. You created a WSGI entry point so that any WSGI-capable application server can interface with it, and then configured the Gunicorn app server to provide this function. Afterwards, you created a systemd service file to automatically launch the application server on boot. You also created an Nginx server block that passes web client traffic to the application server, relaying external requests, and secured traffic to your server with Let’s Encrypt.

Flask is a very simple, but extremely flexible framework meant to provide your applications with functionality without being too restrictive about structure and design. You can use the general stack described in this guide to serve the flask applications that you design.
