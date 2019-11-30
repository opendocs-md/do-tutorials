---
author: James Kolce
date: 2017-03-29
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-secure-your-rancher-web-app-with-let-s-encrypt-on-ubuntu-16-04
---

# How To Secure Your Rancher Web App with Let's Encrypt on Ubuntu 16.04

## Introduction

Protecting web applications with [TLS/SSL](https://en.wikipedia.org/wiki/Transport_Layer_Security) used to be considered necessary only for applications handling sensitive information, since getting an official certificate had a cost and required extra setup. [Let’s Encrypt](https://letsencrypt.org) lets us create official certificates in an automated way without any cost, meaning we can add this layer of security to any website without trade-offs.

[Rancher](http://rancher.com) manages Docker containers in an intuitive way with an easy-to-use dashboard. Rancher has a [catalog of popular applications](http://docs.rancher.com/rancher/v1.4/en/catalog/) that we can deploy instantly, including a Let’s Encrypt service that can generate certificates, and will also take care of renewal when necessary. Once created, the certificates are stored within Rancher and are available for use without any complications.

The process to set up Let’s Encrypt in Rancher consists of three major steps: We deploy the Let’s Encrypt service, we apply the certificate it generates to the load balancer, and we set up HTTP to HTTPS redirection. This tutorial walks you through the entire process.

## Prerequisites

To complete this tutorial, you will need:

- One 1GB Ubuntu 16.04 server with Rancher installed. To configure this, follow the tutorial [How To Manage Multi-Node Deployments with Rancher and Docker Machine on Ubuntu 16.04](how-to-manage-multi-node-deployments-with-rancher-and-docker-machine-on-ubuntu-16-04). You will create additional servers in that tutorial, which will act as hosts for your Docker containers.
- An application deployed using Rancher that uses Rancher’s built-in Load Balancer service. While you can follow this tutorial with any application, including the ones in the Rancher catalog, you can also check out our guide about [How to Deploy a Node.js and MongoDB application with Rancher on Ubuntu 16.04](how-to-deploy-a-node-js-and-mongodb-application-with-rancher-on-ubuntu-16-04) to get started. Whichever route you choose, ensure that your configuration uses Rancher’s built-in Load Balancer service to forward requests to the application containers.
- A Fully-Qualified Domain Name (FQDN) with an **A** record for `your_domain` pointed at the public IP address of your host that runs the Rancher Load Balancer service. This is required because of how Let’s Encrypt validates that you own the domain it is issuing a certificate for. You can follow the tutorial [How To Set Up a Host Name with DigitalOcean](how-to-set-up-a-host-name-with-digitalocean) to configure this record. Ensure that you can view your deployed application at `http://your_domain` before you begin this tutorial.

## Step 1 — Deploying the Let’s Encrypt Service

We are going to deploy the Let’s Encrypt service as a Docker container, which is going to be hosted on one of our Rancher hosts. The process consists of selecting the Let’s Encrypt service from the Rancher catalog and filling in the required information. Once you finish this step, you will have a certificate available in Rancher. Best of all, the service will automatically renew the certificate when it is close to expiration, without any further action on your part.

To start, go to the **Rancher Catalog** by clicking the **Catalog** menu at the top of the Rancher user interface. Then search for the **Let’s Encrypt** service. Once you find it, click the **View Details** button and follow these steps to configure the service:

1. Select the latest template version. This tutorial uses version **0.4.0**.
2. Give the new application stack a distinctive name. We’ll call it **Certificates** in this tutorial, but any name will work.
3. Select the **Yes** option for the **I Agree to the Let’s Encrypt TOS** field after reading the information if you agree with the terms.
4. Select the **Production** version of the Let’s Encrypt API.
5. Enter your valid email address in the **Your Email Address** field.
6. For **Certificate Name** , enter the name of the certificate so you can easily identify it in Rancher’s user interface. You can use your domain name for this.
7. For **Domain Names** , enter the domain name you want to protect. If you want to protect multiple domains, enter each domain, separated by commas.
8. For the **Public Key Algorithm** , select the default **RSA-2048** , which is the most common algorithm used in web applications, or choose an algorithm that fits your needs.
9. For **Renewal Time of Day** select the time of the day, in UTC, in which you want to renew the certificate. The default value of **12** will work fine unless you have some specific constraints.
10. For **Domain Validation Method** , select **HTTP** for this tutorial. There are other methods you can select that work with the DNS provider that you are using for your domain. DigitalOcean is included in the list, along with Cloudflare, DNSimple, Dyn, Gandi, Ovh, Route53 and Vultr. The **HTTP** option works regardless of provider and is the approach we will use for this tutorial.
11. The rest of the fields are related to specific DNS providers. Since you chose the **HTTP** method, you can leave them blank.
12. Next, uncheck the **Start service after creating** checkbox. We’ll start the service after we make some additional configuration changes.
13. Finally, click the **Launch** button at the bottom of the page to start the service and wait for it to be deployed.

Next, we need to tell Racher’s load balancer service to forward requests for `/.well-known/acme-challenge` to our new **Certificate** service. Without this, Let’s Encrypt won’t be able to verify that we are the owner of the domain. Follow these steps to complete the process:

1. Locate your load balancer service in Rancher and click its **Upgrade/Edit** button.
2. Add a new **Service Rule**.
3. For the new rule:
  1. Ensure the **Access** is set to **Public**.
  2. Ensure the **Protocol** is set to **HTTP**.
  3. Ensure **Port** is set to `80`.
  4. Set the **Path** to `/.well-known/acme-challenge`.
  5. Set **Target** to the **Certificate** service.
4. Press the **Up** arrow for this new service to make sure it’s the first service in the list.
5. Press **Edit** at the bottom of the screen to save the configuration.

With the new rule in place, start the Let’s Encrypt service:

1. Locate your **Certificate** stack by selecting the **Stacks** menu at the top of the interface.
2. Select the **Certificates** stack to reveal the **letsencrypt** service.
3. Press the **Start** button to start the service.

At this point, the Let’s Encrypt service should be running and a certificate will be created. The process can take anywhere from 5 to 15 minutes. Select the **Infrastructure** menu and choose **Certificates** to view the certificates. In a short while, you’ll see the new certificate appear, although you may need to refresh the page. Once you see the certificate, you can use it with your application.

## Step 2 — Linking the Certificate with the Application

Once the Let’s Encrypt certificate is available in Rancher, you can select it for use in the Rancher Load Balancer service. To do that, you’ll change the rule in your Load Balancer to use HTTPS and apply the certificate. Follow these steps to make those configuration changes:

1. Locate your load balancer service in Rancher and press its **Upgrade/Edit** button to access its settings.
2. In the **Port Rules** section, look for the entry that forwards requests to your application and change the **Protocol** to **HTTPS** and change the **Request Host Port** to **443** which is the default port for HTTPS. 
3. Go to the **SSL Termination** tab at the bottom of the page and select the certificate you want to use in the **Certificate** field. If you want to add multiple certificates, you can select them in the **Alternate Certs** field. When you select a certificate, it gets automatically linked to the corresponding domain.
4. Click the **Create** button at the bottom of the page. 

If you access the website with the HTTPS protocol (`https://your_domain`) you can see that the connection is now secure. But since you replaced port `80` with port `443`, any request via HTTP will no longer work. To solve this problem, we could just add back the rule for HTTP and port `80` that we had before, but instead, we will adjust our load balancer to redirect the traffic from HTTP to HTTPS. This ensures people always visit the site in a secure manner.

## Step 3 — Redirecting HTTP to HTTPS

The Rancher Load Balancer service has support for custom HAProxy configuration settings. We are going to use that feature to include some configuration that will redirect all the traffic coming from HTTP to HTTPS. The approach in this section leverages the Let’s Encrypt service you configured previously, as it’s currently listening on port `80` to forward domain verification requests.

To set up the redirection, locate your load balancer service in Rancher and press the **Upgrade/Edit** button to access the settings as you did in the previous steps. Once the settings page appears, select the **Custom haproxy.cfg** tab at the bottom of the page.

Add the following piece of code to create the redirection:

Custom haproxy.cfg

    frontend 80
    acl lepath path_beg -i /.well-known/acme-challenge
    redirect scheme https code 301 if !lepath !{ ssl_fc }

This creates a rule for the load balancer that redirects all traffic to HTTPS, but ignores requests for the `/.well-known/acme-challenge` path we configured for Let’s Encrypt domain verification. We use `code 301` to indicate that we want a permanent redirection for this domain. To learn more about redirection settings, you can look at the [HAProxy documentation](https://cbonte.github.io/haproxy-dconv/1.7/configuration.html#redirect%20scheme).

Click the **Edit** button at the bottom of the page to apply these changes.

At this point, every time your visitors access the website through HTTP, they will be redirected to HTTPS, making the website secure for everybody. Now we can proceed to test our website.

## Step 4 — Testing the Setup

To test your website, open the address in a web browser, using the HTTP protocol (`http://your_domain`) and then look for the secure indicator in the address bar. You can also test it using the `curl` utility by executing the following command, which sends a request to the server, follows any redirects, and returns only the response headers:

    curl -I -L http://your_domain

You should see a result like the following:

    OutputHTTP/1.1 301 Found
    Cache-Control: no-cache
    Content-length: 0
    Location: https://your_domain/
    Connection: close
    
    HTTP/1.1 200 OK
    Cache-Control: public, max-age=0
    Content-Type: text/html; charset=utf-8
    Vary: Accept-Encoding
    Date: Sun, 19 Feb 2017 03:42:47 GMT

The first block of output shows the response when first requesting the website through HTTP, saying that it was found but the location is now in another address. Note the `301 Found` section, which tells you that the HAProxy rule we added has worked. The `Location` section shows the new location of the requested resource. The second block of output shows that `curl` followed the redirect to the new location. It also shows that the website has been found at the new location, as indicated by the `200 OK` response.

## Conclusion

In this tutorial, you set up HTTPS on a website using Rancher and the Let’s Encrypt service. Getting a secure website is now easier than ever and you don’t have to worry about constantly renewing your certificates or setting up other tools for the task. And with Rancher, you can scale up your infrastructure to meet future demand.
