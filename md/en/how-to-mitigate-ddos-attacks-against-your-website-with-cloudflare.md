---
author: Mitchell Anicas
date: 2015-07-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-mitigate-ddos-attacks-against-your-website-with-cloudflare
---

# How To Mitigate DDoS Attacks Against Your Website with CloudFlare

## Introduction

CloudFlare is a company that provides content delivery network (CDN) and distributed DNS services by acting as a reverse proxy for websites. CloudFlare’s free and paid services can be used to improve the security, speed, and availability of a website in a variety of ways. In this tutorial, we will show you how to use CloudFlare’s free tier service to protect your web servers against ongoing HTTP-based DDoS attacks by enabling “I’m Under Attack Mode”. This security mode can mitigate DDoS attacks by presenting an interstitial page to verify the legitimacy of a connection before passing it to your web server.

## Prerequisites

This tutorial assumes that you have the following:

- A web server 
- A registered domain that points to your web server
- Access to the control panel of the domain registrar that issued the domain

You must also sign up for a CloudFlare account before continuing. Note that this tutorial will require the use of CloudFlare’s nameservers.

## Configure Your Domain to Use CloudFlare

Before using any of CloudFlare’s features, you must configure your domain to use CloudFlare’s DNS.

If you haven’t already done so, log in to CloudFlare.

### Add a Website and Scan DNS Records

After logging in, you will be taken to the **Get Started with CloudFlare** page. Here, you must add your website to CloudFlare:

![Add a website](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cloudflare/ddos/2-add-website.png)

Enter the domain name that you want to use CloudFlare with and click the **Begin Scan** button. You should be taken to a page that looks like this:

![Scanning your DNS records](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cloudflare/ddos/3-scanning-dns-records.png)

This takes about a minute. When it is complete, click the **Continue** button.

The next page shows the results of the DNS record scan. Be sure that all of your existing DNS records are present, as these are the records that CloudFlare will use to resolve requests to your domain. In our example, we used `cockroach.nyc` as the domain:

![Add DNS Records](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cloudflare/ddos/4-add-dns-records.png)

Note that, for your A and CNAME records that point to your web server(s), the **Status** column should have an orange cloud with an arrow going through it. This indicates that the traffic will flow through CloudFlare’s reverse proxy before hitting your server(s).

Next, select your CloudFlare plan. In this tutorial, we will select the **Free plan** option. If you want to pay for a different plan because you want additional CloudFlare features, feel free to do so:

![Select CloudFlare Plan](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cloudflare/ddos/5-select-cloudflare-plan.png)

### Change Your Nameservers

The next page will display a table of your domain’s current nameservers and what they should be changed to. Two of them should be changed to CloudFlare nameservers, and the remaining entries should be removed. Here is an example of what the page might look like if your domain is using the DigitalOcean nameservers:

![Change your nameservers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cloudflare/ddos/6-change-your-nameservers.png)

To change your domain’s nameservers, log in to your domain registrar control panel and make the DNS changes that CloudFlare presented. For example, if you purchased your domain through a registrar like GoDaddy or NameCheap, you will need to log into appropriate registrar’s control panel and make the changes there.

The process varies based on your particular domain registrar. If you can’t figure out how to do this, it is similar to the process described in [How to Point to DigitalOcean Nameservers From Common Domain Registrars](how-to-point-to-digitalocean-nameservers-from-common-domain-registrars) except you will use the CloudFlare nameservers instead of DigitalOcean’s.

In the example case, the domain is using DigitalOcean’s nameservers and we need to update it to use CloudFlare’s DNS. The domain was registered through NameCheap so that’s where we should go to update the nameservers.

When you are finished changing your nameservers, click the **Continue** button. It can take up to 24 hours for the nameservers to switch but it usually only takes several minutes.

### Wait for Nameservers to Update

Because updating nameservers takes an unpredictable amount of time, it is likely that you will see this page next:

![Pending nameservers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cloudflare/ddos/7-pending-nameservers.png)

The **Pending** status means that CloudFlare is waiting for the nameservers to update to the ones that it prescribed (e.g. `olga.ns.cloudflare.com` and `rob.ns.cloudflare.com`). If you changed your domain’s nameservers, all you have to do is wait and check back later for an **Active** status. If you click the **Recheck Nameservers** button or navigate to the CloudFlare dashboard, it will check if the nameservers have updated.

### CloudFlare Is Active

Once the nameservers update, your domain will be using CloudFlare’s DNS and you will see it has an **Active** status, like this:

![Active Status](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cloudflare/ddos/8-active.png)

This means that CloudFlare is acting as a reverse proxy to your website, and you have access to whichever features are available to the pricing tier that you signed up for. If you’re using the **free** tier, as we are in this tutorial, you will have access some of the features that can improve your site’s security, speed, and availability. We won’t cover all of the features in this tutorial, as we are focusing on mitigating ongoing DDoS attacks, but they include CDN, SSL, static content caching, a firewall (before the traffic reaches your server), and traffic analytics tools.

Also note the **Settings Summary** , right below your domain will show your website’s current security level (medium by default) and some other information.

Before continuing, to get the most out of CloudFlare, you will want to follow this guide: [Recommended First Steps for All CloudFlare Users](https://support.cloudflare.com/hc/en-us/articles/201897700). This is important to ensure that CloudFlare will allow legitimate connections from services that you want to allow, and so that your web server logs will show the original visitor IP addresses (instead of CloudFlare’s reverse proxy IP addresses).

Once you’re all set up, let’s take a look at the **I’m Under Attack Mode** setting in the CloudFlare firewall.

## I’m Under Attack Mode

By default, CloudFlare’s firewall security is set to **Medium**. This offers some protection against visitors who are rated as a moderate threat by presenting them with a challenge page before allowing them to continue to your site. However, if your site is the target of a DDoS attack, that may not be enough to keep your site operational. In this case, the **I’m Under Attack Mode** might be appropriate for you.

If you enable this mode, any visitor to your website will be presented with an interstitial page that performs some browser checks and delays the visitor for about 5 seconds before passing them to your server. It will look something like this;

![Interstitial Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cloudflare/ddos/11-interstitial-page.png)

If the checks pass, the visitor will be allowed through to your website. The combination of preventing and delaying malicious visitors from connecting to your site is often enough to keep it up and running, even during a DDoS attack.

**Note:** Visitors to the site must have JavaScript and Cookies enabled to pass the interstitial page. If this isn’t acceptable, consider using the “High” firewall security setting instead.

Keep in mind that you only want to have **I’m Under Attack Mode** enabled when your site is the victim of a DDoS attack. Otherwise, it should be turned off so it does not delay normal users from accessing your website for no reason.

### How To Enable I’m Under Attack Mode

If you want enable **I’m Under Attack Mode** , the easiest way is to go to the CloudFlare Overview page (the default page) and select it from the **Quick Actions** menu:

![Under Attack Mode action](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cloudflare/ddos/9-quick-actions.png)

The security settings will immediately switch to **I’m Under Attack** status. Now, any visitors to your site will be presented with the CloudFlare interstitial page that was described above.

### How To Disable I’m Under Attack Mode

As the **I’m Under Attack Mode** should only be used during DDoS emergencies, you should disable it if you aren’t under attack. To do so, go to the CloudFlare Overview page, and click the **Disable** button:

![I'm Under Attack enabled](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cloudflare/ddos/10-under-attack-status.png)

Then select the security level that you would like to switch to. The default and generally recommended, mode is **Medium** :

![Disable I'm Under Attack Mode](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/cloudflare/ddos/12-disable-under-attack.png)

Your site should revert back to an **Active** status, and the DDoS protection page will be disabled.

## Conclusion

Now that your website is using CloudFlare, you have another tool to easily protect it against HTTP-based DDoS attacks. There are also a variety of other tools that CloudFlare provides that you may be interested in setting up, like free SSL certificates. As such, it is recommended that you explore the options and see what is useful to you.

Good luck!
