---
author: Marko Mudrinić
date: 2018-05-11
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-alertmanager-and-blackbox-exporter-to-monitor-your-web-server-on-ubuntu-16-04
---

# How To Use Alertmanager And Blackbox Exporter To Monitor Your Web Server On Ubuntu 16.04

_The author selected the [Tech Education Fund](https://www.brightfunds.org/funds/tech-education) to receive a $300 donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

When problems arise, sending alerts to the appropriate team significantly speeds up identifying the root cause of an issue, allowing teams to resolve incidents quickly.

[Prometheus](https://prometheus.io/) is an open-source monitoring system that collects metrics from your services and stores them in a time-series database. [Alertmanager](https://github.com/prometheus/alertmanager) is a tool for processing alerts, which de-duplicates, groups, and sends alerts to the appropriate receiver. It can handle alerts from client applications such as Prometheus, and it supports many receivers including e-mail, [PagerDuty](https://www.pagerduty.com/), [OpsGenie](https://www.opsgenie.com/) and [Slack](https://slack.com/).

Thanks to the many Prometheus exporters available, you can configure alerts for every part of your infrastructure, including [web](https://prometheus.io/docs/instrumenting/exporters/#http) and [database servers](https://prometheus.io/docs/instrumenting/exporters/#databases), [messaging systems](https://prometheus.io/docs/instrumenting/exporters/#messaging-systems) or [APIs](https://prometheus.io/docs/instrumenting/exporters/#apis).

[Blackbox Exporter](https://github.com/prometheus/blackbox_exporter) probes endpoints over HTTP, HTTPS, DNS, TCP or ICMP protocols, returning detailed metrics about the request, including whether or not it was successful and how long it took to receive a response.

In this tutorial you’ll install and configure Alertmanager and Blackbox Exporter to monitor the responsiveness of an Nginx web server. You’ll then configure Alertmanager to notify you over e-mail and Slack if your server isn’t responding.

## Prerequisites

For this tutorial, you’ll need:

- One Ubuntu 16.04 server, set up by following the [Initial Server Setup with Ubuntu 16.04 tutorial](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall.
- Nginx installed by following the first two steps of the [How To Install Nginx on Ubuntu 16.04](how-to-install-nginx-on-ubuntu-16-04) tutorial.
- An Nginx server block listening on port `8080`, which you can configure by following the [How To Set Up Nginx Server Blocks (Virtual Hosts) on Ubuntu 16.04](how-to-set-up-nginx-server-blocks-virtual-hosts-on-ubuntu-16-04) tutorial. You’ll use this as the endpoint to monitor in this tutorial.
  - Change the port by modifying the `listen` directive from `80` to `8080`. You can use a domain or sub-domain, but make sure to replace the endpoint address through the tutorial. 
- Prometheus 2.x installed by following the tutorial [How To Install Prometheus On Ubuntu 16.04](how-to-install-prometheus-on-ubuntu-16-04). 
- An SMTP server for sending e-mails. You can use any SMTP server, or set up your own by following the tutorial [How to Install and Configure Postfix as a Send-Only SMTP Server on Ubuntu 16.04](how-to-install-and-configure-postfix-as-a-send-only-smtp-server-on-ubuntu-16-04).
- Optionally, a [Slack](https://slack.com) account and workspace if you want to receive alerts from Alertmanager over Slack. 

## Step 1 — Creating Service Users

For security purposes, we’ll create two new user accounts, **blackbox\_exporter** and **alertmanager**. We’ll use these accounts throughout the tutorial to run Blackbox Exporter and Alertmanager, as well as to isolate the ownership on appropriate core files and directories. This ensures Blackbox Exporter and Alertmanager can’t access and modify data they don’t own.

Create these users with the `useradd` command using the `--no-create-home` and `--shell /bin/false` flags so that these users can’t log into the server:

    sudo useradd --no-create-home --shell /bin/false blackbox_exporter
    sudo useradd --no-create-home --shell /bin/false alertmanager

With the users in place, let’s download and configure Blackbox Exporter.

## Step 2 — Installing Blackbox Exporter

First, download the latest stable version of Blackbox Exporter to your home directory. You can find the latest binaries along with their checksums on the [Prometheus Download page](https://prometheus.io/download/).

    cd ~
    curl -LO https://github.com/prometheus/blackbox_exporter/releases/download/v0.12.0/blackbox_exporter-0.12.0.linux-amd64.tar.gz

Before unpacking the archive, verify the file’s checksums using the following `sha256sum` command:

    sha256sum blackbox_exporter-0.12.0.linux-amd64.tar.gz

Compare the output from this command with the checksum on the Prometheus download page to ensure that your file is both genuine and not corrupted:

    Outputc5d8ba7d91101524fa7c3f5e17256d467d44d5e1d243e251fd795e0ab4a83605 blackbox_exporter-0.12.0.linux-amd64.tar.gz

If the checksums don’t match, remove the downloaded file and repeat the preceding steps to re-download the file.

When you’re sure the checksums match, unpack the archive:

    tar xvf blackbox_exporter-0.12.0.linux-amd64.tar.gz

This creates a directory called `blackbox_exporter-0.12.0.linux-amd64`, containing the `blackbox_exporter` binary file, a license, and example files.

Copy the binary file to the `/usr/local/bin` directory.

    sudo mv ./blackbox_exporter-0.12.0.linux-amd64/blackbox_exporter /usr/local/bin

Set the user and group ownership on the binary to the **blackbox\_exporter** user, ensuring non-root users can’t modify or replace the file:

    sudo chown blackbox_exporter:blackbox_exporter /usr/local/bin/blackbox_exporter

Lastly, we’ll remove the archive and unpacked directory, as they’re no longer needed.

    rm -rf ~/blackbox_exporter-0.12.0.linux-amd64.tar.gz ~/blackbox_exporter-0.12.0.linux-amd64

Next, let’s configure Blackbox Exporter to probe endpoints over the HTTP protocol and then run it.

## Step 3 — Configuring and Running Blackbox Exporter

Let’s create a configuration file defining how Blackbox Exporter should check endpoints. We’ll also create a systemd unit file so we can manage Blackbox’s service using `systemd`.

We’ll specify the list of endpoints to probe in the Prometheus configuration in the next step.

First, create the directory for Blackbox Exporter’s configuration. Per Linux conventions, configuration files go in the `/etc` directory, so we’ll use this directory to hold the Blackbox Exporter configuration file as well:

    sudo mkdir /etc/blackbox_exporter

Then set the ownership of this directory to the **blackbox\_exporter** user you created in Step 1:

    sudo chown blackbox_exporter:blackbox_exporter /etc/blackbox_exporter

In the newly-created directory, create the `blackbox.yml` file which will hold the Blackbox Exporter configuration settings:

    sudo nano /etc/blackbox_exporter/blackbox.yml

We’ll configure Blackbox Exporter to use the default `http` prober to probe endpoints. _Probers_ define how Blackbox Exporter checks if an endpoint is running. The `http` prober checks endpoints by sending a HTTP request to the endpoint and testing its response code. You can select which HTTP method to use for probing, as well as which status codes to accept as successful responses. Other popular probers include the `tcp` prober for probing via the TCP protocol, the `icmp` prober for probing via the ICMP protocol and the `dns` prober for checking DNS entries.

For this tutorial, we’ll use the `http` prober to probe the endpoint running on port `8080` over the HTTP `GET` method. By default, the prober assumes that valid status codes in the `2xx` range are valid, so we don’t need to provide a list of valid status codes.

We’ll configure a timeout of **5** seconds, which means Blackbox Exporter will wait 5 seconds for the response before reporting a failure. Depending on your application type, choose any value that matches your needs.

**Note:** Blackbox Exporter’s configuration file uses the [YAML format](http://www.yaml.org/start.html), which forbids using tabs and strictly requires using two spaces for indentation. If the configuration file is formatted incorrectly, Blackbox Exporter will fail to start up.

Add the following configuration to the file:

/etc/blackbox\_exporter/blackbox.yml

    modules:
      http_2xx:
        prober: http
        timeout: 5s
        http:      
          valid_status_codes: []
          method: GET

You can find more information about the configuration options in the [the Blackbox Exporter’s documentation](https://github.com/prometheus/blackbox_exporter/blob/master/CONFIGURATION.md).

Save the file and exit your text editor.

Before you create the service file, set the user and group ownership on the configuration file to the **blackbox\_exporter** user created in Step 1.

    sudo chown blackbox_exporter:blackbox_exporter /etc/blackbox_exporter/blackbox.yml

Now create the service file so you can manage Blackbox Exporter using `systemd`:

    sudo nano /etc/systemd/system/blackbox_exporter.service

Add the following content to the file:

/etc/systemd/system/blackbox\_exporter.service

    [Unit]
    Description=Blackbox Exporter
    Wants=network-online.target
    After=network-online.target
    
    [Service]
    User=blackbox_exporter
    Group=blackbox_exporter
    Type=simple
    ExecStart=/usr/local/bin/blackbox_exporter --config.file /etc/blackbox_exporter/blackbox.yml
    
    [Install]
    WantedBy=multi-user.target

This service file tells `systemd` to run Blackbox Exporter as the **blackbox\_exporter** user with the configuration file located at `/etc/blackbox_exporter/blackbox.yml`. The details of `systemd` service files are beyond the scope of this tutorial, but if you’d like to learn more see the [Understanding Systemd Units and Unit Files](understanding-systemd-units-and-unit-files#where-are-systemd-unit-files-found) tutorial.

Save the file and exit your text editor.

Finally, reload `systemd` to use your newly-created service file:

    sudo systemctl daemon-reload

Now start Blackbox Exporter:

    sudo systemctl start blackbox_exporter

Make sure it started successfully by checking the service’s status:

    sudo systemctl status blackbox_exporter

The output contains information about Blackbox Exporter’s process, including the main process identifier (PID), memory use, logs and more.

    Output● blackbox_exporter.service - Blackbox Exporter
       Loaded: loaded (/etc/systemd/system/blackbox_exporter.service; disabled; vendor preset: enabled)
       Active: active (running) since Thu 2018-04-05 17:48:58 UTC; 5s ago
     Main PID: 5869 (blackbox_export)
        Tasks: 4
       Memory: 968.0K
          CPU: 9ms
       CGroup: /system.slice/blackbox_exporter.service
               └─5869 /usr/local/bin/blackbox_exporter --config.file /etc/blackbox_exporter/blackbox.yml

If the service’s status isn’t `active (running)`, follow the on-screen logs and retrace the preceding steps to resolve the problem before continuing the tutorial.

Lastly, enable the service to make sure Blackbox Exporter will start when the server restarts:

    sudo systemctl enable blackbox_exporter

Now that Blackbox Exporter is fully configured and running, we can configure Prometheus to collect metrics about probing requests to our endpoint, so we can create alerts based on those metrics and set up notifications for alerts using Alertmanager.

## Step 4 — Configuring Prometheus To Scrape Blackbox Exporter

As mentioned in Step 3, the list of endpoints to be probed is located in the Prometheus configuration file as part of the Blackbox Exporter’s `targets` directive. In this step you’ll configure Prometheus to use Blackbox Exporter to scrape the Nginx web server running on port `8080` that you configured in the prerequisite tutorials.

Open the Prometheus configuration file in your editor:

    sudo nano /etc/prometheus/prometheus.yml

At this point, it should look like the following:

/etc/prometheus/prometheus.yml

    global:
      scrape_interval: 15s
    
    scrape_configs:
      - job_name: 'prometheus'
        scrape_interval: 5s
        static_configs:
          - targets: ['localhost:9090']
      - job_name: 'node_exporter'
        scrape_interval: 5s
        static_configs:
          - targets: ['localhost:9100']

At the end of the `scrape_configs` directive, add the following entry, which will tell Prometheus to probe the endpoint running on the local port `8080` using the Blackbox Exporter’s module `http_2xx`, configured in Step 3.

/etc/prometheus/prometheus.yml

    ...
      - job_name: 'blackbox'
        metrics_path: /probe
        params:
          module: [http_2xx]
        static_configs:
          - targets:
            - http://localhost:8080
        relabel_configs:
          - source_labels: [__address__]
            target_label: __param_target
          - source_labels: [__param_target]
            target_label: instance
          - target_label: __address__
            replacement: localhost:9115

By default, Blackbox Exporter runs on port `9115` with metrics available on the `/probe` endpoint.

The `scrape_configs` configuration for Blackbox Exporter differs from the configuration for other exporters. The most notable difference is the `targets` directive, which lists the endpoints being probed instead of the exporter’s address. The exporter’s address is specified using the appropriate set of ` __address__ ` labels.

You’ll find a detailed explanation of the `relabel` directives in the [Prometheus documentation](https://prometheus.io/docs/introduction/overview/).

Your Prometheus configuration file will now look like this:

Prometheus config file - /etc/prometheus/prometheus.yml

    global:
      scrape_interval: 15s
    
    scrape_configs:
      - job_name: 'prometheus'
        scrape_interval: 5s
        static_configs:
          - targets: ['localhost:9090']
      - job_name: 'node_exporter'
        scrape_interval: 5s
        static_configs:
          - targets: ['localhost:9100']
      - job_name: 'blackbox'
        metrics_path: /probe
        params:
          module: [http_2xx]
        static_configs:
          - targets:
            - http://localhost:8080
        relabel_configs:
          - source_labels: [__address__]
            target_label: __param_target
          - source_labels: [__param_target]
            target_label: instance
          - target_label: __address__
            replacement: localhost:9115

Save the file and close your text editor.

Restart Prometheus to put the changes into effect:

    sudo systemctl restart prometheus

Make sure it’s running as expected by checking the Prometheus service status:

    sudo systemctl status prometheus

If the service’s status isn’t `active (running)`, follow the on-screen logs and retrace the preceding steps to resolve the problem before continuing the tutorial.

At this point, you’ve configured Prometheus to scrape metrics from Blackbox Exporter. In order to receive alerts from Alertmanager, in the next step you’ll create an appropriate set of Prometheus alert rules.

## Step 5 — Creating Alert Rules

[Prometheus Alerting](https://prometheus.io/docs/alerting/overview/) is separated into two parts. The first part is handled by the Prometheus server and includes generating alerts based on alert rules and sending them to [Alertmanager](https://github.com/prometheus/alertmanager). The second part is done by Alertmanager, which manages received alerts and sends them to the appropriate receivers, depending on the configuration.

In this step, you’ll learn the basic syntax of alert rules as you create an alert rule to check if your server is available.

First, create a file to store your alerts. Create an empty file named `alert.rules.yml` in the `/etc/prometheus` directory:

    sudo touch /etc/prometheus/alert.rules.yml

As this file is part of the Prometheus configuration, make sure the ownership is set to the **prometheus** user you created in the prerequisite Prometheus tutorial:

    sudo chown prometheus:prometheus /etc/prometheus/alert.rules.yml

With the alerts file in place, we need to tell Prometheus about it by adding the appropriate directive to the configuration file.

Open the Prometheus configuration file in your editor:

    sudo nano /etc/prometheus/prometheus.yml

Add the `rule_files` directive after the `global` directive to make Prometheus load your newly-created alerts file when Prometheus starts.

/etc/prometheus/prometheus.yml

    global:
      scrape_interval: 15s
    
    rule_files:
      - alert.rules.yml
    
    scrape_configs:
    ...

Save the file and exit your text editor.

Now let’s build a rule that checks if the endpoint is down.

In order to make the alert rule, you’ll use Blackbox Exporter’s `probe_success` metric which returns **1** if the endpoint is up and **0** if it isn’t.

The `probe_success` metric contains two labels: the `instance` label with the address of the endpoint, and the `job` label with the name of the exporter that collected the metric.

Open the alert rules file in your editor:

    sudo nano /etc/prometheus/alert.rules.yml

Like the Prometheus configuration file, the alerts rule file uses the YAML format, which strictly forbids tabs and requires two spaces for indentation. Prometheus will fail to start if the file is incorrectly formatted.

First, we’ll create an alert rule called `EndpointDown` to check if the `probe_sucess` metric equals **0** with a duration of **10** seconds. This ensures that Prometheus will not send any alert if the endpoint is not available for less than 10 seconds. You’re free to choose whatever duration you want depending on your application type and needs.

Also, we’ll attach two labels denoting critical severity and a summary of the alert, so we can easily manage and filter alerts.

If you want to include more details in the alert’s labels and annotations, you can use the `{{ $labels.metrics_label }}` syntax to get the label’s value. We’ll use this to include the endpoint’s address from the metric’s `instance` label.

Add the following rule to the alerts file:

/etc/prometheus/alert.rules.yml

    groups:
    - name: alert.rules
      rules:
      - alert: EndpointDown
        expr: probe_success == 0
        for: 10s
        labels:
          severity: "critical"
        annotations:
          summary: "Endpoint {{ $labels.instance }} down"

Save the file and exit your text editor.

Before restarting Prometheus, make sure your alerts file is syntactically correct using the following `promtool` command:

    sudo promtool check rules /etc/prometheus/alert.rules.yml

The output contains the number of rules found in the file, along with information about whether or not the rules are syntactically correct:

    OutputChecking /etc/prometheus/alert.rules.yml
      SUCCESS: 1 rules found

Lastly, restart Prometheus to apply the changes:

    sudo systemctl restart prometheus

Verify the service is running with the `status` command:

    sudo systemctl status prometheus

If the service’s status isn’t `active`, follow the on-screen logs and retrace the preceding steps to resolve the problem before continuing the tutorial.

With the alert rules in place, we can download and install Alertmanager.

## Step 6 — Downloading Alertmanager

Blackbox Exporter is configured and our alert rules are in place. Let’s download and install Alertmanager to process the alerts received by Prometheus.

You can find the latest binaries along with their checksums on the [Prometheus download page](https://prometheus.io/download/). Download and unpack the current stable version of Alertmanager into your home directory:

    cd ~
    curl -LO https://github.com/prometheus/alertmanager/releases/download/v0.14.0/alertmanager-0.14.0.linux-amd64.tar.gz

Before unpacking the archive, verify the file’s checksums using the following `sha256sum` command:

    sha256sum alertmanager-0.14.0.linux-amd64.tar.gz

Compare the output from this command with the checksum on the Prometheus download page to ensure that your file is both genuine and not corrupted.

    Outputcaddbbbe3ef8545c6cefb32f9a11207ae18dcc788e8d0fb19659d88c58d14b37 alertmanager-0.14.0.linux-amd64.tar.gz

If the checksums don’t match, remove the downloaded file and repeat the preceding steps to re-download the file.

Once you’ve verified the download, unpack the archive:

    tar xvf alertmanager-0.14.0.linux-amd64.tar.gz

This creates a directory called `alertmanager-0.14.0.linux-amd64` containing two binary files (`alertmanager` and `amtool`), a license and an example configuration file.

Move the two binary files to the `/usr/local/bin` directory:

    sudo mv alertmanager-0.14.0.linux-amd64/alertmanager /usr/local/bin
    sudo mv alertmanager-0.14.0.linux-amd64/amtool /usr/local/bin

Set the user and group ownership on the binary files to the **alertmanager** user you created in Step 1:

    sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager
    sudo chown alertmanager:alertmanager /usr/local/bin/amtool

Remove the leftover files from your home directory as they are no longer needed:

    rm -rf alertmanager-0.14.0.linux-amd64 alertmanager-0.14.0.linux-amd64.tar.gz

Now that the required files are in the appropriate location, we can configure Alertmanager to send notifications for alerts over email.

## Step 7 — Configuring Alertmanager To Send Alerts Over Email

In this step, you’ll create the directory and files to store Alertmanager’s data and configuration settings, and then configure Alertmanager to send alerts via email.

Following the standard Linux conventions, we’ll create a directory in `/etc` to store Alertmanager’s configuration file.

    sudo mkdir /etc/alertmanager

Set the user and group ownership for the newly-created directory to the **alertmanager** user:

    sudo chown alertmanager:alertmanager /etc/alertmanager

We’ll store the configuration file in the `alertmanager.yml` file, so create this file and open it in your editor:

    sudo nano /etc/alertmanager/alertmanager.yml

Like other Prometheus-related files, this one uses YAML format as well, so make sure to use two spaces instead of tabs for indentation.

We’ll configure Alertmanager to send emails using Postfix, which you installed following the prerequisite tutorial. We need to provide the SMTP server’s address, using the `smtp_smarthost` directive, as well as the address we want to send emails from, using the `smtp_from` directive. As Postfix is running on the same server as Alertmanager, the server’s address is `localhost:25`. We’ll use the **alertmanager** user for sending emails.

By default, Postfix doesn’t have TLS configured, so we need to tell Alertmanager to allow non-TLS SMTP servers using the `smtp_require_tls` directive.

Put the SMTP configuration under the `global` directive, as it’s used to specify parameters valid in all other configuration contexts. This includes SMTP configuration in our case, and can also include API tokens for various integrations:

Alertmanager config file part 1 - /etc/alertmanager/alertmanager.yml

    global:
      smtp_smarthost: 'localhost:25'
      smtp_from: 'alertmanager@your_domain'
      smtp_require_tls: false

**Note:** Make sure to replace `your_domin` in the `smtp_from` directive with your domain name.

At this point, Alertmanager knows how to send emails, but we need to define how it will handle incoming alerts using the `route` directive. The `route` directive is applied to every incoming alert and defines properties such as how Alertmanager will group alerts, who is the default recipient, or how long Alertmanager will wait before sending an initial alert.

To group alerts, use the `group_by` sub-directive, which takes an inline array of labels (such as `['label-1', 'label-2']`). Grouping ensures that alerts containing the same labels will be grouped and sent in the same batch.

Every `route` directive has a single receiver defined using the `receiver` sub-directive. If you want to add multiple receivers, you’ll need to either define multiple receivers under the same directive or nest multiple `route` directives using the `routes` sub-directive. In this tutorial, we’ll cover the first approach to configure Slack alerts.

In this case, we’ll only group by Blackbox’s `instance` label and the `severity` label we attached to the alert in step 6, ensuring we’ll get multiple alerts for our endpoint with critical severity in one mail.

Add the following `group_by` directive:

Alertmanager config file part 2 - /etc/alertmanager/alertmanager.yml

    ...
    route:
      group_by: ['instance', 'alert']

Next, we’ll define intervals, such as how long Alertmanager will wait before sending initial and new alerts.

Using the `group_wait` sub-directive, we’ll define how long Alertmanager will wait before sending the initial alert. During this period, Alertmanager will wait for Prometheus to send other alerts if they exist so they can be sent in the same batch. As we only have one alert, we’ll select an arbitrary value of 30 seconds.

Next, using the `group_interval` interval, we’ll define how long Alertmanager will wait before sending the next batch of alerts if there are new alerts in the same group. You’re free to choose any value depending on your needs, but we’ll set this to every 5 minutes.

The last interval we’ll configure is the `repeat_interval`, which defines how long Alertmanager will wait before it sends notification if alerts are not resolved yet. You can choose whatever value suits your needs, but we’ll use the arbitrary value of 3 hours.

Lastly, using the `receiver` sub-directive, define who will receive notifications for the alerts. We’ll use a receiver called `team-1`, which we will define later.

Modify the route directive so it looks like this:

Alertmanager config file part 2 - /etc/alertmanager/alertmanager.yml

    route:
      group_by: ['instance', 'severity']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 3h
      receiver: team-1

If you want to match and send notifications only about specific alerts, you can use the `match` and `match_re` sub-directives to filter out alerts by their label’s value. The `match` sub-directive represents equality match, where the `match_re` sub-directive represents matching via regular expressions.

Now we’ll configure the `team-1` receiver so you can receive notifications for alerts. Under the `receivers` directive you can define receivers containing the name and appropriate configuration sub-directive. The list of available receivers and instructions on how to configure them is available as the part of [Alertmanager’s documentation](https://prometheus.io/docs/alerting/configuration/#%3Creceiver).

In order to configure the `team-1` email receiver, we’ll use the `email_configs` sub-directive under the `receivers` directive:

Alertmanager config file part 3 - /etc/alertmanager/alertmanager.yml

    receivers:
      - name: 'team-1'
        email_configs:
          - to: 'your-email-address'

At this point, you have configured Alertmanager to send notifications for alerts to your e-mail address. Your configuration file should look like:

Alertmanager config file - /etc/alertmanager/alertmanager.yml

    global:
      smtp_smarthost: 'localhost:25'
      smtp_from: 'alertmanager@example.com'
      smtp_require_tls: false
    
    route:
      group_by: ['instance', 'severity']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 3h
      receiver: team-1
    
    receivers:
      - name: 'team-1'
        email_configs:
          - to: 'your-email-address'

In the next step, we’ll configure Alertmanager to send alerts to your Slack channel. If you don’t want to configure Slack, you can skip straight to step 10 where we’ll create the service file and configure Prometheus to work with Alertmanager.

## Step 8 — Configuring Alertmanager To Send Alerts Over Slack

Before proceeding with this step, make sure you have created an Slack account and that you have a Slack workspace available.

To send alerts to Slack, first create an [Incoming Webhook](https://api.slack.com/incoming-webhooks).

Point your browser to the Incoming Webhook creation page available at `https://workspace-name.slack.com/services/new/incoming-webhook/`. You’ll get the page containing details about Incoming Webhooks as well as a dropdown from which you need to choose the channel where you want to send alerts.

![Slack Incoming Webhook](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/prometheus_blackbox_alertmanager_1604/uBKKA4O.png)

Once you choose the channel, click on the **Add Incoming WebHooks integration** button.

You’ll see a new page confirming that the webhook was created successfully. Copy the **Webhook URL** displayed on this page, as you’ll use it to configure Alertmanager’s Slack notifications.

Open the Alertmanager configuration file in your editor to configure Slack notifications:

    sudo nano /etc/alertmanager/alertmanager.yml

First, add the `slack_api_url` sub-directive to the `global` part of your configuration, using the URL you got when you created the Slack Incoming Webhook.

Alertmanager config file part 1 - /etc/alertmanager/alertmanager.yml

    global:
      smtp_smarthost: 'localhost:25'
      smtp_from: 'alertmanager@example.com'
      smtp_require_tls: false
    
      slack_api_url: 'your_slack_webhook_url'

There are two ways to send alerts to multiple receivers:

1. Include multiple receiver configurations under the same entry. This is the the least error-prone solution and the easiest method. 
2. Create multiple receiver entries and nest multiple `route` directives. 

We won’t cover the second approach in this tutorial, but if you’re interested, take a look at the [Route configuration](https://prometheus.io/docs/alerting/configuration/#route) portion of Alertmanager documentation.

In the `team-1` receiver, add a new sub-directive called [`slack_configs`](https://prometheus.io/docs/alerting/configuration/#slack_config) and provide the name of the channel that should receive alerts. In this case, we’ll use use the `general` channel:

Alertmanager config file part 2 - /etc/alertmanager/alertmanager.yml

    receivers:
      - name: 'team-1'
        email_configs:
          - to: 'your-email-address'
        slack_configs:
          - channel: 'general<^>'

Your completed configuration file will look like the following:

Alertmanager config file - /etc/alertmanager/alertmanager.yml

    global:
      smtp_smarthost: 'localhost:25'
      smtp_from: 'alertmanager@example.com'
      smtp_require_tls: false
    
      slack_api_url: 'your_slack_webhook_url'
    
    route:
      group_by: ['instance', 'severity']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 3h
      receiver: team-1
    
    receivers:
      - name: 'team-1'
        email_configs:
          - to: 'your-email-address'
        slack_configs:
          - channel: 'general'

Save the file and exit your editor.

We’re now ready to run Alertmanager for the first time.

## Step 9 — Running Alertmanager

Let’s get Alertmanager up and running. We’ll first create a systemd unit file for Alertmanager to manage its service using `systemd`. Then we’ll update Prometheus to use Alertmanager.

Create a new `systemd` unit file and open it in your text editor:

    sudo nano /etc/systemd/system/alertmanager.service

Add the following to the file to configure systemd to run Alertmanager as the **alertmanager** user, using the configuration file located at `/etc/alertmanager/alertmanager.yml` and Alertmanager’s URL, configured to use your server’s IP address:

/etc/systemd/system/alertmanager.service

    [Unit]
    Description=Alertmanager
    Wants=network-online.target
    After=network-online.target
    
    [Service]
    User=alertmanager
    Group=alertmanager
    Type=simple
    WorkingDirectory=/etc/alertmanager/
    ExecStart=/usr/local/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --web.external-url http://your_server_ip:9093
    
    [Install]
    WantedBy=multi-user.target

This will run Alertmanager as the **alertmanager** user. It also tells Alertmanager to use the URL `http://your_server_ip:9093` for its Web UI, where `9093` is Alertmanager’s default port. Be sure to include the protocol (`http://`) or things won’t work.

Save the file and close your text editor.

Next, we need to tell Prometheus about Alertmanager by adding the appropriate Alertmanager service discovery directory to the Prometheus configuration file. By default, Alertmanager is running on port `9093`, and since it’s on the same server as Prometheus, we’ll use the address `localhost:9093`.

Open the Prometheus configuration file:

    sudo nano /etc/prometheus/prometheus.yml

After the `rule_files` directive, add the following `alerting` directive:

Prometheus configuration file - /etc/prometheus/prometheus.yml

    ...
    rule_files:
      - alert.rules.yml
    
    alerting:
      alertmanagers:
      - static_configs:
        - targets:
          - localhost:9093
    ...

Once you’re done, save the file and close your text editor.

In order to be able to follow URLs from the alerts you receive, you need to tell Prometheus the IP address or domain name of your server using the `-web.external-url` flag when you start Prometheus.

Open the `systemd` unit file for Prometheus:

    sudo nano /etc/systemd/system/prometheus.service

Replace the existing `ExecStart` line with the following one:

    ExecStart=/usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml \
        --storage.tsdb.path /var/lib/prometheus/ --web.console.templates=/etc/prometheus/consoles \
        --web.console.libraries=/etc/prometheus/console_libraries \ 
        --web.external-url http://your_server_ip

Your new Prometheus unit file will look like this:

Prometheus service file - /etc/systemd/system/prometheus.service

    [Unit]
    Description=Prometheus
    Wants=network-online.target
    After=network-online.target
    
    [Service]
    User=prometheus
    Group=prometheus
    Type=simple
    ExecStart=/usr/local/bin/prometheus --config.file /etc/prometheus/prometheus.yml \
        --storage.tsdb.path /var/lib/prometheus/ --web.console.templates=/etc/prometheus/consoles \
        --web.console.libraries=/etc/prometheus/console_libraries \ 
        --web.external-url http://your_server_ip
    
    [Install]
    WantedBy=multi-user.target

Save the file and close your text editor.

Reload `systemd` and restart Prometheus to apply the changes:

    sudo systemctl daemon-reload
    sudo systemctl restart prometheus

Make sure Prometheus is working as intended by checking the service’s status:

    sudo systemctl status prometheus

If the service’s status isn’t `active (running)`, follow the on-screen logs and retrace the preceding steps to resolve the problem before continuing the tutorial.

Finally, start Alertmanager for the first time:

    sudo systemctl start alertmanager

Check the service’s status to make sure Alertmanager is working as intended:

    sudo systemctl status alertmanager

If the service’s status isn’t `active (running)`, follow the on-screen messages and retrace the preceding steps to resolve the problem before continuing the tutorial.

Lastly, enable the service to make sure Alertmanager will start when the system boots:

    sudo systemctl enable alertmanager

To access Alertmanager’s Web UI, allow traffic to port `9093` through your firewall:

    sudo ufw allow 9093/tcp

Alertmanager is now configured to send notifications for alerts via email and Slack. Let’s ensure it works.

## Step 10 — Testing Alertmanager

Let’s make sure Alertmanger is working correctly and sending emails and Slack notifications. We’ll disable the endpoint by removing the Nginx server block you created in the prerequisite tutorials:

    sudo rm /etc/nginx/sites-enabled/your_domain

Reload Nginx to apply the changes:

    sudo systemctl reload nginx

If you want to confirm it’s actually disabled, you can point your web browser to your server’s address. You should see a message indicating that the site is no longer reachable. If you don’t, retrace the preceding steps and make sure you deleted correct server block and reloaded Nginx.

Depending on the `group_wait` interval, which is **30 seconds** in our case, you should receive email and Slack notifications after 30 seconds.

If you don’t, check the service’s status by using the following `status` commands and follow the on-screen logs to find the cause of the problem:

    sudo systemctl status alertmanager
    sudo systemctl status prometheus

You can also check the alert’s status from the Prometheus Web UI, by pointing your web browser to the `http://your_server_ip/alerts`. You’ll be asked to enter the username and password you chose by following the Prometheus tutorial. By clicking on the alert name, you’ll see the status, the alert rule, and associated labels:

![Prometheus UI - alerts](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/prometheus_blackbox_alertmanager_1604/ikIPV9Q.png)

Once you’ve verified Alertmanager is working, enable the endpoint by re-creating the symbolic link from the `sites-available` directory to the `sites-enabled` directory:

    sudo ln -s /etc/nginx/sites-available/your_domain /etc/nginx/sites-enabled

Reload Nginx once again to apply the changes:

    sudo systemctl reload nginx

In the next step, we’ll look at how to use Alertmanager’s Command-Line Interface.

## Step 11 — Managing Alerts Using the CLI

Alertmanager comes with the command-line tool `amtool`, which lets you monitor, manage and silence alerts.

The `amtool` tool requires you to provide the URL of Alertmanager using the `--alertmanager.url` flag every time you execute an command. In order to use `amtool` without providing the URL, we’ll start by creating a configuration file.

Default locations for the configuration file are `$HOME/.config/amtool/config.yml`, which makes the configuration available only for your current user, and `/etc/amtool/config.yml`, which makes the configuration available for the every user on the server.

You’re free to choose whatever suits your needs, but for this tutorial, we’ll use the `$HOME/.config/amtool/config.yml` file.

First, create the directory. The `-p` flag tells `mkdir` to create any necessary parent directories along the way:

    mkdir -p $HOME/.config/amtool

Create the `config.yml` file and open it in your text editor:

    nano $HOME/.config/amtool/config.yml

Add the following line to tell `amtool` to use Alertmanager with the `http://localhost:9093` URL:

~/.config/amtool/config.yml

    alertmanager.url: http://localhost:9093

Save the file and exit your text editor.

Now, we’ll take a look at what we can do with the `amtool` command line tool.

Using the `amtool alert query` command, you can list all alerts that have been send to Alertmanager:

    amtool alert query

The output shows the alert’s name, the time of the alert’s first occurrence, and the alert’s summary you provided when you configured it:

    OutputAlertname Starts At Summary
    EndpointDown 2018-04-03 08:48:47 UTC Endpoint http://localhost:8080 down

You can also filter alerts by their labels using the appropriate matcher. A matcher contains the label name, the appropriate operation, which can be `=` for full matching and `=~` for partial matching, and the label’s value.

If you want to list all alerts that have a critical severity label attached, use the `severity=critical` matcher in the `alert query` command:

    amtool alert query severity=critical

Like before, the output contains the alert’s name, the time of alert’s first occurrence and the alert’s summary.

    OutputAlertname Starts At Summary
    EndpointDown 2018-04-03 08:48:47 UTC Endpoint http://localhost:8080 down

You can use regular expressions to match labels with the `=~` operator. For example, to list all alerts for `http://localhost` endpoints not depending on the port, you can use the `instance=~http://localhost.*` matcher:

    amtool alert query instance=~http://localhost.*

As you have only one alert and endpoint, the output would be the same as in the previous example.

To look at the Alertmanager configuration, use the `amtool config` command:

    amtool config

The output will contain the content of the `/etc/alertmanager/alertmanager.yml` file.

Now let’s look at how to silence alerts using `amtool`.

Silencing alerts lets you mute alerts based on the matcher for a given time. During that period, you’ll not receive any email or Slack notification for the silenced alert.

The `amtool silence add` command takes the matcher as an argument and creates a new _silence_ based on the matcher.

To define the expiration of an alert, use the `--expires` flag with desired duration of the silence, such as `1h` or the `--expire-on` flag with the time of silence expiration in the [RFC3339 format](https://www.ietf.org/rfc/rfc3339.txt). For example, the format `2018-10-04T07:50:00+00:00` represents 07.50am on October 4th, 2018.

If the `--expires` or the `--expires-on` flag is not provided, alerts will be silenced for **1 hour**.

To silence all alerts for the `http://localhost:8080` instance for **3 hours** , you’d use the following command:

    amtool silence add instance=http://localhost:8080 --expires 3h

The output contains an identification number for the silence, so make sure to note it down as you’ll need it in case you want to remove the silence:

    Output4e89b15b-0814-41d3-8b74-16c513611732

If you want to provide additional information when creating the silence, such as the author and comments, use the `--author` and `--comment` flags:

    amtool silence add severity=critical --expires 3h --author "Sammy The Shark" --comment "Investigating the progress"

Like before, the output contains the ID of the silence:

    Output12b7b9e1-f48a-4ceb-bd85-65ac882ceed1

The command `amtool silence query` will show the list of all non-expired silences:

    amtool silence query

The output contains the ID of the silence, the list of matchers, the expiration timestamp, the author, and a comment:

    OutputID Matchers Ends At Created By Comment
    12b7b9e1-f48a-4ceb-bd85-65ac882ceed1 severity=critical 2018-04-04 08:02:58 UTC Sammy The Shark Investigating in the progress
    4e89b15b-0814-41d3-8b74-16c513611732 instance=http://localhost:8080 2018-04-04 08:14:21 UTC sammy

Similar to the `alert query` command, you can use label matchers to filter the output by labels attached on creation:

    amtool silence query instance=http://localhost:8080

Like before, the output will include the ID number and details of the alert:

    OutputID Matchers Ends At Created By Comment
    4e89b15b-0814-41d3-8b74-16c513611732 instance=http://localhost:8080 2018-04-04 08:14:21 UTC sammy

Finally, to expire a silence, use the `amtool silence expire` with the ID of the silence you want to expire:

    amtool silence expire 12b7b9e1-f48a-4ceb-bd85-65ac882ceed1
    amtool silence expire 4e89b15b-0814-41d3-8b74-16c513611732

No output represents successful command execution. If you see an error, make sure you provided the correct ID of the silence.

## Conclusion

In this tutorial you configured Blackbox Exporter and Alertmanager to work together with Prometheus so you can receive alerts via email and Slack. You also used Alertmanager’s command-line interface, `amtool`, to manage and silence alerts.

If you’d like to learn more about other Alertmanager integrations, take a look at the [Configuration](([https://prometheus.io/docs/alerting/configuration/)](https://prometheus.io/docs/alerting/configuration/))) portion of Alertmanager’s documentation.

Also, you can take a look how to integrate Prometheus Alerts with other services such as [Grafana](http://docs.grafana.org/alerting/rules/).
