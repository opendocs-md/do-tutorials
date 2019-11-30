---
author: Brian Boucheron
date: 2017-06-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-work-with-digitalocean-load-balancers-using-doctl
---

# How To Work with DigitalOcean Load Balancers Using Doctl

## Introduction

DigitalOcean Load Balancers are an easy way to distribute HTTP, HTTPS, and TCP traffic between multiple backend servers. In this tutorial we will use `doctl` — the official command-line client for DigitalOcean’s API — to create and configure a load balancer for multiple backend web servers.

## Prerequisites

Before starting this tutorial, you should familiarize yourself with `doctl` and DigitalOcean Load Balancers. The following articles will be helpful:

- [How To Use Doctl, the Official DigitalOcean Command-Line Client](how-to-use-doctl-the-official-digitalocean-command-line-client)
- [An Introduction to DigitalOcean Load Balancers](an-introduction-to-digitalocean-load-balancers)

You should make sure you have `doctl` version 1.6.0 or higher installed and authenticated before continuing. Check your `doctl` version by running `doctl version`. You will also need to have an SSH key added to your DigitalOcean account.

## Step 1 — Setting Up the Backend Web Servers

First, we will use `doctl` to create the two web servers our Load Balancer will direct traffic to. We’ll start with two servers that have the LAMP stack (Linux, Apache, MySQL, PHP) preinstalled, and update them to each serve unique web pages. This will help us verify that the load balancer is indeed distributing connections between multiple servers.

In order to create the two servers, we first need to know the region we want them to be in, and the fingerprint of the SSH key we want to use. We will use the **nyc1** region for this tutorial. You can list all the regions and their shortened slugs with `doctl`:

    doctl compute region list

    OutputSlug Name Available
    nyc1 New York 1 true
    sfo1 San Francisco 1 true
    nyc2 New York 2 true
    ams2 Amsterdam 2 true
    sgp1 Singapore 1 true
    lon1 London 1 true
    nyc3 New York 3 true
    ams3 Amsterdam 3 true
    fra1 Frankfurt 1 true
    tor1 Toronto 1 true
    sfo2 San Francisco 2 true
    blr1 Bangalore 1 true

Choose the slug for whichever region you’d like to use.

**Note:** Your Load Balancer and its target Droplets must all be in the same region.

To find your SSH key fingerprint, again use `doctl`:

    doctl compute ssh-key list

    OutputID Name FingerPrint
    7738555 sammy@host your_ssh_key_fingerprint

In the output, note the fingerprint of the SSH key you’ll be using. We’ll need it for the next command.

We are going to use a one-click LAMP stack image running Ubuntu 16.04, and we’ll put this on a 512mb droplet. The different options available for images and droplet sizes can be listed with `doctl` as well, using the `list` command. You can read more about this in the [Creating, Deleting, and Inspecting Droplets section](how-to-use-doctl-the-official-digitalocean-command-line-client#creating,-deleting,-and-inspecting-droplets) of the prequisite article.

Now that we have all of our information, we can create the two servers in a single command:

    doctl compute droplet create web-1 web-2 \
        --region nyc1 \
        --image lamp-16-04 \
        --ssh-keys your_ssh_key_fingerprint \
        --enable-private-networking \
        --size 512mb

`web-1` and `web-2` will be the names of the servers. We’ve also selected `--enable-private-networking`. This will ensure that the traffic from the Load Balancer to the target Droplets will stay on DigitalOcean’s unmetered private network.

The `create` command will output information about the new Droplets:

    OutputID Name Public IPv4 Private IPv4 Public IPv6 Memory VCPUs Disk Region Image Status Tags
    48463543 web-1 512 1 20 nyc1 Ubuntu LAMP on 16.04 new
    48463544 web-2 512 1 20 nyc1 Ubuntu LAMP on 16.04 new

Our two servers are now being provisioned. Wait a few minutes for the process to finish, and then list out your web Droplets:

    doctl compute droplet list web-*

The `list` command accepts the `*` wildcard character. In this case, we will only show Droplets with at least `web-` in their name:

    OutputID Name Public IPv4 Private IPv4 Public IPv6 Memory VCPUs Disk Region Image Status Tags
    48603683 web-1 111.111.111.111 111.111.111.333 512 1 20 nyc1 Ubuntu LAMP on 16.04 active
    48603684 web-2 111.111.111.222 111.111.111.444 512 1 20 nyc1 Ubuntu LAMP on 16.04 active

Notice the Droplets now have IPv4 addresses assigned and are listed as `active`. If you navigate to either of the Droplets’ public addresses in your web browser, a default Apache placeholder page will load. Let’s add a new unique page to each, so we can tell **web-1** apart from **web-2**.

We can SSH to our server through `doctl`:

    doctl compute ssh web-1

This will connect and log you in as **root** using the SSH key you specified during creation. Open up a new HTML file on the server. We’ll use the `nano` text editor:

    nano /var/www/html/test.html

Paste in the following HTML snippet:

/var/www/html/test.html

    <h1 style="color:blue">Hello from web-1!</h1>

Save the file and exit the text editor. This is not a full HTML file, but browsers are forgiving and it’s sufficient for our purposes.

Navigate to the following address to make sure the new page is being served properly. Be sure to substitute the correct IP for the highlighted portion:

    http://web-1_public_ip_address/test.html

On the page, you should see the headline **Hello from web-1!** that we just created.

Exit out of the SSH session:

    exit

Now, SSH into the second server, and repeat the process, using a different message in the HTML page:

    doctl compute ssh web-2

Open the new HTML file:

    nano /var/www/html/test.html

Paste in the content:

/var/www/html/test.html

    <h1 style="color: orange">Hello from web-2!</h1>

Save and exit the text editor, then exit the SSH session:

    exit

Use your browser to check that **web-2** is also serving the new web page properly. If so, we’re ready to create a load balancer to distribute load between our two servers.

## Step 2 — Creating a Load Balancer

We will create our new Load Balancer in the **nyc1** region. Note again that the Load Balancer and its target Droplets need to be in the same region, so be sure to use the region where your Droplets are located:

    doctl compute load-balancer create \
        --name load-balancer-1 \
        --region nyc1 \
        --forwarding-rules entry_protocol:http,entry_port:80,target_protocol:http,target_port:80

This command creates a Load Balancer with the name `load-balancer-1` in the `nyc1` region. Each Load Balancer needs at least one rule under the `--forwarding-rules` flag. These rules describe how the load balancer will accept traffic and how it will forward it onto the targets. The above forwarding rule indicates that we’re passing HTTP traffic on port 80 straight through to the target servers.

Other `--forwarding-rules` protocol options are `https` and `tcp`, and you can choose any valid ports for both entry and target. If you need to specify multiple forwarding rules, surround the whole list of rules in quotes and use a space between each rule. Here’s an example that would enable both HTTP and HTTPS forwarding:

    --forwarding-rules "entry_protocol:http,entry_port:80,target_protocol:http,target_port:80 entry_protocol:https,entry_port:443,target_protocol:https,target_port:443"

The `create` command we just ran will output information about our new Load Balancer:

    OutputID IP Name Status Created At Algorithm Region Tag Droplet IDs SSL Sticky Sessions Health Check Forwarding Rules
    ae3fa042-bfd2-5e94-b564-c352fc6874ef load-balancer-1 new 2017-05-10T19:28:30Z round_robin nyc1 false type:none,cookie_name:,cookie_ttl_seconds:0 protocol:http,port:80,path:/,check_interval_seconds:10,response_timeout_seconds:5,healthy_threshold:5,unhealthy_threshold:3 entry_protocol:http,entry_port:80,target_protocol:http,target_port:80,certificate_id:,tls_passthrough:false

Take note of the Load Balancer’s ID, highlighted above, which we will use in the next step to add our target Droplets. There’s also information on some default configurations we did not set, such as health check rules and sticky sessions. You can find more information about these options in the [prerequisite load balancer article](an-introduction-to-digitalocean-load-balancers). To find out details on how to set these options using `doctl`, you can always run the `create` command with a `--help` flag. For Load Balancer creation, that would look like this:

    doctl compute load-balancer create --help

This will output a list of all available command line flags and options. You can use this `--help` flag on any `doctl` command.

Now that our Load Balancer is created, we need to add the target droplets to it. We’ll do that in the next section.

## Step 3 – Adding Droplets to the Load Balancer

Let’s list out the information for our two Droplets again, so we can get their IDs:

    doctl compute droplet list web-*

    OutputID Name Public IPv4 Private IPv4 Public IPv6 Memory VCPUs Disk Region Image Status Tags
    48603683 web-1 111.111.111.111 111.111.111.333 512 1 20 nyc1 Ubuntu LAMP on 16.04 active
    48603684 web-2 111.111.111.222 111.111.111.444 512 1 20 nyc1 Ubuntu LAMP on 16.04 active

The IDs are highlighted in the example output above. **Be sure to use your actual IDs, not the examples.**

Now we use the `add-droplets` command to add the target Droplets to our Load Balancer. Specify the ID of the Load Balancer we created in the previous step:

    doctl compute load-balancer add-droplets  
        ae3fa042-bfd1-4e94-b564-c352fc6874ef \
        --droplet-ids 48463543,48463544

We can now use the `get` command to retrieve the updated info for our load balancer:

    doctl compute load-balancer get ae3fa042-bfd1-4e94-b564-c352fc6874ef

    OutputID IP Name Status Created At Algorithm Region Tag Droplet IDs SSL Sticky Sessions Health Check Forwarding Rules
    ae3fa042-bfd1-4e94-b564-c352fc6874ef 111.111.111.555 load-balancer-1 active 2017-05-10T19:28:30Z round_robin nyc1 48603683,48603684 false type:none,cookie_name:,cookie_ttl_seconds:0 protocol:http,port:80,path:/,check_interval_seconds:10,response_timeout_seconds:5,healthy_threshold:5,unhealthy_threshold:3 entry_protocol:http,entry_port:80,target_protocol:http,target_port:80,certificate_id:,tls_passthrough:false

Note that the status is now `active`, we have an IP assigned, and our target droplets are listed. Navigate to this new load balanced IP in your browser, again loading the `test.html` page. The url will look like:

    http://load-balancer-1_ip_address/test.html

Your browser will load the message from either **web-1** or **web-2**. Refresh the page and you should see the other server’s message. Our Load Balancer is in _round robin_ mode, meaning it sends connections to the next Droplet on the list for each request. The alternative is _least connections_ mode, where the Load Balancer sends new traffic to whichever target has the fewest active connections.

Now that we know our Load Balancer is working, let’s disable a server and see how it handles the interruption.

## Step 4 – Testing Fail Over

One big advantage of Load Balancers is increased tolerance to problems with individual backend web servers. The Load Balancer runs a health check at predetermined intervals (every 10 seconds by default). The default health check is to fetch a web page on the target server. If this check fails a few times in a row, the target will be taken out of the rotation and no traffic will be sent to it until it recovers.

Let’s test the failover feature by failing the health check. SSH back into **web-2** :

    doctl compute ssh web-2

Now shut down the Apache web server:

    systemctl stop apache2

Return to the browser and refresh the load balanced page a few times. At first you might get a few **503 Service Unavailable** errors. By default the Load Balancer waits for three health checks to fail before removing a server from the pool. This will take about thirty seconds. After that, you’ll only see responses from **web-1**.

Start Apache back up on **web-2** :

    systemctl start apache2

Again, after a short time the load balancer will detect that **web-2** is up and it will be added back to the pool. You’ll start to see **web-2** responses when refreshing the page.

Your load balancer is now back to full health.

Read on for some next steps you can take to make your Load Balancer production-ready.

## Conclusion

In this tutorial we’ve used `doctl` to create a DigitalOcean Load Balancer and some backend web servers, configured the Load Balancer to send HTTP traffic to the backend servers, and tested the Load Balancer’s health check functionality. There are a few more steps you could take to make your Load Balancer ready for production:

- You’ll want to point a domain name at your load balancer, so your users aren’t typing in an unfriendly IP address. You can learn how to do that with our tutorial [How To Set Up a Host Name with DigitalOcean](how-to-set-up-a-host-name-with-digitalocean).
- DigitalOcean lets you tag your droplets so you can keep them organized and address whole sets of Droplets as a group. You can configure your Load Balancer to send traffic to all Droplets in a certain tag, instead of adding droplets individually. This will allow you to add new backend servers to the pool more dynamically. You can learn about DigitalOcean tags in [How To Tag DigitalOcean Droplets](how-to-tag-digitalocean-droplets).
- If you need to add HTTPS security to your load balanced website, we have tutorials on the two different ways you can achieve this: [SSL passthrough](how-to-configure-ssl-passthrough-on-digitalocean-load-balancers) and [SSL termination](how-to-configure-ssl-termination-on-digitalocean-load-balancers).
