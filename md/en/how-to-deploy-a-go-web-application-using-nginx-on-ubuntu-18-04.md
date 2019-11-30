---
author: Michael Okoh
date: 2019-07-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-deploy-a-go-web-application-using-nginx-on-ubuntu-18-04
---

# How To Deploy a Go Web Application Using Nginx on Ubuntu 18.04

_The author selected the [Tech Education Fund](https://www.brightfunds.org/funds/tech-education) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Go](https://golang.org/) is a general-purpose programming language that is gradually becoming one of the most popular web back-end programming languages. By focusing on simplicity, the designers of Go created a language that is both easy to learn and faster than many other languages for web applications, leveraging efficient features like its ability to handle multiple requests at a time due to its concurrency. Because of this, deploying a web application in Go will be useful to many back-end developers.

[Nginx](https://www.nginx.com/) is one of the most popular web servers in the world due to its lightweight resource usage and its reliability under load. Many of the largest and most highly trafficked sites on the internet depend on Nginx to serve their content. In deployment, Nginx is often used as a load balancer or a reverse proxy to increase security and make the application more robust. In conjunction with a Go web back-end, Nginx can serve up a powerful and fast web application.

In this tutorial, you will build a `Hello World` web application in Go and deploy it on an Ubuntu 18.04 server using Nginx as a reverse proxy.

## Prerequisites

To follow this tutorial, you will need the following:

- One Ubuntu 18.04 server set up by following this [initial server setup for Ubuntu 18.04 tutorial](initial-server-setup-with-ubuntu-18-04), including a sudo non-root user and a firewall.
- The [Go](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-go) programming language installed by following [How To Install Go and Set Up a Local Programming Environment on Ubuntu 18.04](how-to-install-go-and-set-up-a-local-programming-environment-on-ubuntu-18-04).
- [Nginx](https://www.nginx.com/) installed by following [How To Install Nginx on Ubuntu 18.04](how-to-install-nginx-on-ubuntu-18-04). Do not follow [**Step 5 – Setting Up Server Blocks**](how-to-install-nginx-on-ubuntu-18-04#step-5-%E2%80%93-setting-up-server-blocks-(recommended)); you will create an Nginx server block later on in this tutorial.
- A domain name pointed at your server, as described in [How To Set Up a Host Name with DigitalOcean](how-to-set-up-a-host-name-with-digitalocean). This tutorial will use `your_domain` throughout. This is necessary to obtain an SSL certificate for your website, so you can securely serve your application with TLS encryption.

Additionally, in order to achieve a production-grade deployment of your Go web application, it’s important that you keep your server secure by installing a TLS/SSL certificate. This step is **strongly encouraged**. To secure your Go web application, follow [How To Secure Nginx with Let’s Encrypt on Ubuntu 18.04](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-18-04) after **Step 3** of this tutorial to obtain the free TLS/SSL certificate.

## Step 1 — Building the Go Web Application

In this step, you will build a sample Go web application that displays `Hello World` at `your_domain` and greets the user at `your_domain/greet/`. If you would like to learn more about the basics of programming in Go, check out our [How To Write Your First Program in Go](how-to-write-your-first-program-in-go) article.

First, create a new directory in your [`GOPATH`](understanding-the-gopath) directory to hold the source file. You can name the folder whatever you like, but this tutorial will use `go-web`:

    mkdir $GOPATH/go-web

Following the file structure suggested in the prerequisite tutorial [How To Install Go and Set Up a Local Programming Environment on Ubuntu 18.04](how-to-install-go-and-set-up-a-local-programming-environment-on-ubuntu-18-04), this will give your directory the path of `~/go/go-web`.

Next, run the following to change directory to your newly created folder in your `GOPATH`:

    cd $GOPATH/go-web

Use `nano` or your preferred text editor to create a file named `main.go`, which will contain the source code for your web application:

    nano main.go

To create the functionality of the `Hello World` application, add the following Go code into the newly created `main.go` file:

~/go/go-web/main.go

    package main
    
    import (
        "fmt"
        "net/http"
    )
    
    func main() {
        http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
            fmt.Fprintf(w, "Hello World")
        })
    
        http.HandleFunc("/greet/", func(w http.ResponseWriter, r *http.Request) {
            name := r.URL.Path[len("/greet/"):]
            fmt.Fprintf(w, "Hello %s\n", name)
        })
    
        http.ListenAndServe(":9990", nil)
    }

Now let’s go through what the preceding code snippet will do, starting from the first line.

First, you wrote the entry point into your application:

~/go/go-web/main.go

    package main
    ...

The `package main` tells the Go compiler to compile this file as an executable program instead of as a shared library.

Next, you have the `import` statements:

~/go/go-web/main.go

    ...
    
    import (
        "fmt"
        "net/http"
    )
    ...

This snippet imports the necessary modules required for this code to work, which include the standard `fmt` package and the `net/http` package for your web server.

The next snippet creates your first route in the `main` function, which is the entry point of any Go application:

~/go/go-web/main.go

    ...
    func main () {
        http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
            fmt.Fprintf(w, "Hello World")
        })
      ...
    }
    ...

A parent route `/` is created within `func main`, which will return the text `Hello World` when requested.

The second route as shown in the following snippet accepts a URL parameter, in this case a name, to display accompanied by a greeting.

~/go/go-web/main.go

    ...
    func main () {
      ...
        http.HandleFunc("/greet/", func(w http.ResponseWriter, r *http.Request) {
            name := r.URL.Path[len("/greet/"):]
            fmt.Fprintf(w, "Hello %s\n", name)
        })
    ...
    }
    ...

This uses Go’s `URL.Path` to store the value right after `/greet/` and pass it down as the name from the URL parameter.

Finally, you instantiate your server:

~/go/go-web/main.go

    ...
    func main () {
      ...
      http.ListenAndServe(":9990", nil)
    }

The preceding snippet starts the server and exposes your application via port `9990` using Go’s inbuilt `http` server.

Once you are finished examining the code in `main.go`, save the file and quit your text editor.

Next, build the binary executable of your application by running:

    go build main.go

The preceding command will compile `main.go` to produce an executable titled `main`.

You have created your sample Go web application. Next, you will create a systemd unit file to keep your application running in the background even when you are not accessing your server.

## Step 2 — Creating a Systemd Unit File

In this step, you will create a [systemd](understanding-systemd-units-and-unit-files) unit file to keep your application running in the background even when a user logs out of the server. This will make your application persistent, bringing you one step closer to a production-grade deployment.

First, create a new file in `/lib/systemd/system` directory named `goweb.service` using `nano` or you preferred text editor:

    sudo nano /lib/systemd/system/goweb.service

To set the parameters of the service, add the following snippet into the file.

/lib/systemd/system/goweb.service

    [Unit]
    Description=goweb
    
    [Service]
    Type=simple
    Restart=always
    RestartSec=5s
    ExecStart=/home/user/go/go-web/main
    
    [Install]
    WantedBy=multi-user.target

The `ExecStart=/home/user/go/go-web/main` variable specifies that the point of entry for this service is through the `main` executable located in the `/home/user/go/go-web` directory, where `user` is the server non-root sudo account username. `Restart=always` ensures that systemd will always try to restart the program if it stops. On the next line, `RestartSec=5s` sets a five-second wait time between restart attempts. `WantedBy=multi-user.target` specifies in what state your server will enable the service.

Save and exit the file.

Now that you’ve written the service unit file, start your Go web service by running:

    sudo service goweb start

To confirm if the service is running, use the following command:

    sudo service goweb status

You’ll receive the following output:

    Output● goweb.service - goweb
       Loaded: loaded (/lib/systemd/system/goweb.service; disabled; vendor preset: enabled)
       Active: active (running) since Wed 2019-07-17 23:28:57 UTC; 6s ago
     Main PID: 1891 (main)
        Tasks: 4 (limit: 1152)
       CGroup: /system.slice/goweb.service
               └─1891 /home/user/go/go-web/main

To learn more about working with systemd unit file, take a look at [Understanding Systemd Units and Unit Files](understanding-systemd-units-and-unit-files).

Now that you have your application up and running, you can set up the Nginx reverse proxy.

## Step 3 — Setting Up a Reverse Proxy with Nginx

In this step, you will create an Nginx server block and set up an Nginx reverse proxy to expose your application to the internet.

First, change your working directory to the Nginx `sites-available` directory:

    cd /etc/nginx/sites-available

Create a new file with the name of the domain on which you wish to expose your application. This tutorial will use `your_domain`:

    sudo nano your_domain

Add the following lines into the file to establish the settings for `your_domain`:

/etc/nginx/sites-available/your\_domain

    server {
        server_name your_domain www.your_domain;
    
        location / {
            proxy_pass http://localhost:9990;
        }
    }

This Nginx server block uses [`proxy_pass`](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass) to serve the Go web application on your server’s IP address indicated as `localhost` to make it run on port `9990`. `server_name` indicates the domain name mapped to your IP address, in this case `your_domain` and `www.your_domain`.

Next, create a symlink of this Nginx configuration in the `sites-enabled` folder by running the following command:

    sudo ln -s /etc/nginx/sites-available/your_domain /etc/nginx/sites-enabled/your_domain

A symlink is a shortcut of a file in another location. The newly created shortcut will always reference the original file to adjust to updates when edits are made to it. Nginx requires a copy of the configuration in both directories.

Next, reload your Nginx configurations by running the reload command:

    sudo nginx -s reload

To make sure that your deployment is working, visit `http://your_domain` in your browser. You will be greeted with a **Hello World** text string.

**Note:** As mentioned in the Prerequisites section, at this point it is recommended to enable SSL/TLS on your server. This will make sure that all communication between the application and its visitors will be encrypted, which is especially important if the application asks for sensitive information such as a login or password. Follow [How To Secure Nginx with Let’s Encrypt on Ubuntu 18.04](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-18-04) now to obtain a free SSL certificate for Nginx on Ubuntu 18.04. After obtaining your SSL/TLS certificates, come back and complete this tutorial.

You have now set up the Nginx reverse proxy to expose your application at your domain name, and secured your Go web application with SSL/TLS. In the next step, you will be testing your application over a secure connection.

## Step 4 — Testing the Application

In this step, you will test your application over a secure connection to make sure everything is working.

Open your preferred web browser, visit `https://your_domain`:

![Hello World Page Display](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/66224/Hello_World.png)

You will receive a simple `Hello World` message. Receiving this message when using `https://` in the URL indicates that your application is being served over a secure connection.

Next, try visiting the second route `https://your_domain/greet/your-name`, replacing `your-name` with whichever name you want your app to greet:

![Greeting Page Display](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/66224/Greet.png)

The application will return a simple greeting along with `your-name`, which is based on the parameter passed to the URL.

Once you have received these results, you have successfully deployed your Go web application.

## Conclusion

In this tutorial, you created a simple web application with Go using its standard libraries, set up a reverse proxy using Nginx, and used a SSL certificate on your domain to secure your app. To learn more about Go, check their [official documentation](https://golang.org/doc/). Also, you can look at our series [How To Code in Go](https://www.digitalocean.com/community/tutorial_series/how-to-code-in-go) to learn more about programming in this efficient language.
