---
author: Hathy A
date: 2015-06-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-prometheus-to-monitor-your-ubuntu-14-04-server
---

# How To Use Prometheus to Monitor Your Ubuntu 14.04 Server

## Introduction

Prometheus is an open source monitoring system developed by SoundCloud. Like other monitoring systems, such as InfluxDB and Graphite, Prometheus stores all its data in a time series database. However, it offers a multi-dimensional data-model and a powerful query language, allowing system administrators to not only easily fine tune the definitions of their metrics, but also generate more accurate reports.

Additionally, the Prometheus project also includes PromDash (a browser-based tool that can be used to develop custom dashboards) and an experimental AlertManager capable of sending alerts via e-mail, Flowdock, Slack, HipChat and more.

In this tutorial, you will learn how to install, configure, and use the Prometheus Server, Node Exporter, and PromDash.

## Prerequisites

To follow this tutorial, you will need:

- One 64-bit Ubuntu 14.04 Droplet with a [sudo non-root](how-to-add-and-delete-users-on-an-ubuntu-14-04-vps) user.

Note: If you must use a 32-bit server, make sure you replace **-amd64** with **-386** in all the filenames and links mentioned in this tutorial.

## Step 1 — Installing Prometheus Server

First, create a new directory to store all the files you download in this tutorial and move to it.

    mkdir ~/Downloads
    cd ~/Downloads

Use `wget` to download the latest build of the Prometheus server and time-series database from GitHub.

    wget "https://github.com/prometheus/prometheus/releases/download/0.15.1/prometheus-0.15.1.linux-amd64.tar.gz"

The Prometheus monitoring system consists of several components, each of which needs to be installed separately. Keeping all the components inside one parent directory is a good idea, so create one, and an additional subdirectory to store all the binaries of the Prometheus server.

    mkdir -p ~/Prometheus/server

Enter the directory you just created.

    cd ~/Prometheus/server

Use `tar` to extract `prometheus-0.15.1.linux-amd64.tar.gz`.

    tar -xvzf ~/Downloads/prometheus-0.15.1.linux-amd64.tar.gz

This completes the installation of Prometheus server. Verify the installation by typing in:

    ./prometheus -version

You should see the following message on your screen:

Prometheus output

    prometheus, version 0.15.1 (branch: master, revision: 64349aa)
      build user: julius@julius-thinkpad
      build date: 20150727-17:56:00
      go version: 1.4.2

## Step 2 — Installing Node Exporter

Prometheus was developed for the purpose of monitoring web services. In order to monitor the metrics of your Ubuntu server, you should install a tool called Node Exporter. Node Exporter, as its name suggests, exports lots of metrics (such as disk I/O statistics, CPU load, memory usage, network statistics, and more) in a format Prometheus understands.

Create a new directory called `node_exporter` inside the `Prometheus` directory, and get inside it:

    mkdir -p ~/Prometheus/node_exporter
    cd ~/Prometheus/node_exporter

Use `wget` to download the latest build of Node Exporter which is available on GitHub, and place it in the `Downloads` directory.

    wget https://github.com/prometheus/node_exporter/releases/download/0.11.0/node_exporter-0.11.0.linux-amd64.tar.gz -O ~/Downloads/node_exporter-0.11.0.linux-amd64.tar.gz

You can now use the `tar` command to extract `node_exporter-0.11.0.linux-amd64.tar.gz`.

    tar -xvzf ~/Downloads/node_exporter-0.11.0.linux-amd64.tar.gz

## Step 3 — Running Node Exporter as a Service

To make it easy to start and stop Node Exporter, let us now convert it into a service.

Create a soft link to the `node_exporter` binary in `/usr/bin`.

    sudo ln -s ~/Prometheus/node_exporter/node_exporter /usr/bin

Use `nano` or your favorite text editor to create an Upstart configuration file called `node_exporter.conf`.

    sudo nano /etc/init/node_exporter.conf

This file should contain the link to the `node_exporter` executable, and also specify when the executable should be started. Accordingly, add the following code:

/etc/init/node\_exporter.conf

    # Run node_exporter
    
    start on startup
    
    script
       /usr/bin/node_exporter
    end script

At this point, Node Exporter is available as a service which can be started using the `service` command:

    sudo service node_exporter start

After Node Exporter starts, use a browser to view its web interface available at `http://your_server_ip:9100/metrics`. You should see a page with a lot of text:

http://your\_server\_ip:9100/metrics excerpt

    # HELP go_gc_duration_seconds A summary of the GC invocation durations.
    # TYPE go_gc_duration_seconds summary
    go_gc_duration_seconds{quantile="0"} 0.00023853100000000002
    go_gc_duration_seconds{quantile="0.25"} 0.00023998700000000002
    go_gc_duration_seconds{quantile="0.5"} 0.00028122
    . . .

## Step 4 — Starting Prometheus Server

Enter the directory where you installed the Prometheus server:

    cd ~/Prometheus/server

Before you start Prometheus, you must first create a configuration file for it called `prometheus.yml`.

    nano ~/Prometheus/server/prometheus.yml

Copy the following code into the file.

~/Prometheus/server/prometheus.yml

    scrape_configs:
      - job_name: "node"
        scrape_interval: "15s"
        target_groups:
        - targets: ['localhost:9100']

This creates a `scrape_configs` section and defines a job called `node`. It includes the URL of your Node Exporter’s web interface in its array of `targets`. The `scrape_interval` is set to 15 seconds so that Prometheus scrapes the metrics once every fifteen seconds.

You could name your job anything you want, but calling it “node” allows you to use the default console templates of Node Exporter.

Save the file and exit.

Start the Prometheus server as a background process.

    nohup ./prometheus > prometheus.log 2>&1 &

Note that you redirected the output of the Prometheus server to a file called `prometheus.log`. You can view the last few lines of the file using the `tail` command:

    tail ~/Prometheus/server/prometheus.log

Once the server is ready, you will see the following messages in the file:

prometheus.log excerpt

    INFO[0000] Starting target manager... file=targetmanager.go line=75
    INFO[0000] Listening on :9090 file=web.go line=118

Use a browser to visit Prometheus’s homepage available at `http://your_server_ip:9090`. You’ll see the following homepage.

![Prometheus Homepage](http://i.imgur.com/cfw7Gnb.png)

To make sure that Prometheus is scraping data from Node Exporter, click on the **Graph** tab at the top of the page. On the page that opens, type in the name of a metric (like **node\_procs\_running** , for example) in the text field that says **Expression**. Then, press the blue **Execute** button. Click **Graph** (next to **Console** ) just below, and you should see a graph for that metric:

![Prometheus Graph](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/prometheus/lo6upjI.png)

Prometheus has console templates that let you view graphs of a few commonly used metrics. These console template are accessible only if you set the value of `job_name` to `node` in Prometheus’s configuration.

Visit `http://your_server_ip:9090/consoles/node.html` to access the Node Console and click on your server, **`localhost:9100`** , to view its metrics:

![Node Console](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/prometheus/E8flb93.png)

## Step 5 — Installing PromDash

Though the Prometheus server allows you to view graphs and experiment with expressions, it is generally used only for debugging purposes or to run one-off queries. The preferred way to visualize the data in Prometheus’s time-series database is to use PromDash, a tool that allows you to create custom dashboards which are not only highly configurable but also better-looking.

Enter the `Prometheus` directory:

    cd ~/Prometheus

PromDash is a Ruby on Rails application whose source files are available on GitHub. In order to download and run it, you need to install Git, Ruby, SQLite3, Bundler, which is a gem dependency manager, and their dependencies. Use `apt-get` to do so.

    sudo apt-get update && sudo apt-get install git ruby bundler libsqlite3-dev sqlite3 zlib1g-dev

You can now use the `git` command to download the source files.

    git clone https://github.com/prometheus/promdash.git

Enter the `promdash` directory.

    cd ~/Prometheus/promdash

Use `bundle` to install the Ruby gems that PromDash requires. As we will be configuring PromDash to work with SQLite3 in this tutorial, make sure you exclude the gems for MySQL and PostgreSQL using the `--without` parameter:

    bundle install --without mysql postgresql

Because PromDash depends on several gems, you will have to wait for a few minutes for this command to complete. Once done, you should see the following messages.

Bundle output

    . . .
    Your bundle is complete!
    Gems in the groups mysql and postgresql were not installed.
    Use `bundle show [gemname]` to see where a bundled gem is installed.

## Step 6 — Setting Up the Rails Environment

Create a directory to store the SQLite3 databases associated with PromDash.

    mkdir ~/Prometheus/databases

PromDash uses an environment variable called `DATABASE_URL` to determine the name of the the database associated with it. Type in the following so that PromDash creates a SQLite3 database called `mydb.sqlite3` inside the `databases` directory:

    echo "export DATABASE_URL=sqlite3:$HOME/Prometheus/databases/mydb.sqlite3" >> ~/.bashrc

In this tutorial, you will be running PromDash in production mode, so set the `RAILS_ENV` environment variable to `production`.

    echo "export RAILS_ENV=production" >> ~/.bashrc

Apply the changes we made to the `.bashrc` file.

    . ~/.bashrc

Next, create PromDash’s tables in the SQLite3 database using the `rake` tool.

    rake db:migrate

Because PromDash uses the Rails Asset Pipeline, all the assets(CSS files, images and Javascript files) of the PromDash project should be precompiled. Type in the following to do so:

    rake assets:precompile

## Step 7 — Starting and Configuring PromDash

PromDash runs on Thin, a light-weight web server. Start the server as a daemon by typing in the following command:

    bundle exec thin start -d

Wait for a few seconds for the server to start and then visit `http://your_server_ip:3000/` to view PromDash’s homepage.

![PromDash's Homepage](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/prometheus/j0AfIQA.png)

Before you start creating your custom dashboards, you should let PromDash know the URL of your Prometheus server. You can do so by clicking on the **Servers** tab at the top. Click **New Server** , then in the form, give any name to your Prometheus server. Set the **Url** field to `http://your_server_ip:9090` and the **Server type** field to **Prometheus**.

![PromDash's Create Server Screen](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/prometheus/C0ChfYZ.png)

Finally, click on **Create Server** to complete the configuration. Your page will say **Server was successfully created.** and you can click back to **Dashboards** in the top menu.

## Step 8 — Creating a Dashboard

Because a Promdash dashboard should belong to a Promdash directory, first create a new directory by clicking on the **New Directory**. In the form that shows up, give a name to your directory, like **My Dashboards** , then click **Create Directory**.

Once you submit the form, you will be taken back to the homepage. Click on the **New Dashboard** button now to create a new dashboard. In the form shown, give a name to your dashboard, like **Simple Dashboard** and select the directory you just created from the drop-down menu.

After submitting the form, you will be able to see the new dashboard.

![Empty Dashboard](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/prometheus/PQ1eTVJ.png)

Your dashboard already has one graph, but it needs to be configured. Hovering over the graph’s header (which says **Title** ) will reveal various icons that let you configure the graph. To change its title, you can click on the **Graph and Axis Settings** icon (fourth from the left) and type in a new title in the **Graph Title** field.

Click on the **Datasources** icon, which is the second to the left, to add one or more expressions to the graph. Click **Add Expression** , and in the field that says **Enter Expression** , enter **node\_procs\_running**.

![Add Expression](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/prometheus/zHslJPa.png)

Now click on the **Refresh** icon (the leftmost one) in the graph’s header to update the graph. Your dashboard now contains one fully configured graph. You can add more graphs by clicking on the **Add Graph** button at the bottom.

After making all the changes, make sure you click on the **Save Changes** button on the right to make your changes permanent. The next time you visit PromDash’s homepage, you will be able to see a link to your dashboard:

![PromDash Dashboards](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/prometheus/fztROmE.png)

## Conclusion

You now have a fully functional Prometheus ecosystem running on your Ubuntu 14.04 server, and you can use PromDash to create monitoring dashboards that suit your requirements.

Even though you installed all the components on a single Ubuntu machine, you can easily monitor more machines by installing only Node Exporter on each of them, and adding the URLs of the new Node Exporters to the `targets` array of `prometheus.yml`.

You can learn more about Prometheus by referring to its [documentation](http://prometheus.io/docs/introduction/overview/).
