---
author: Kathleen Juell, Josh Barnett
date: 2014-10-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-point-to-digitalocean-nameservers-from-common-domain-registrars
---

# How To Point to DigitalOcean Nameservers From Common Domain Registrars

## Introduction

_DNS (Domain Name System)_ is a naming system that maps a server’s domain name, like `example.com`, to an IP address, like `203.0.113.1`. This is what allows you to direct a domain name to the web server hosting that domain’s content, for example.

To set up a domain name, you need to purchase a domain name from a domain name registrar and then set up DNS records for it. _Registrars_ are organizations that have completed an [accreditation process](https://www.icann.org/resources/pages/accreditation-2012-02-25-en) that allows them to sell domain names. Registrars typically offer services to manage DNS records as well, but once you have purchases a domain, most registrars will allow you to manage your DNS records with other providers.

DigitalOcean is not a domain name registrar, but you _can_ manage your DNS records from the DigitalOcean Control Panel. This can make record management easier because DigitalOcean DNS integrates with Droplets and Load Balancers.

To use DigitalOcean DNS, you’ll need to update the nameservers used by your domain registrar to DigitalOcean’s nameservers instead. In this article, we’ll show you how to look up the registrar for your domain, then provide step-by-step guidance on how to update the nameserver settings for the following registrars:

- GoDaddy
- HostGator
- Namecheap
- 1&1
- Name.com
- Network Solutions
- eNom
- Gandi
- Register.com
- A Small Orange
- iwantmyname
- Google Domains beta

## Prerequisites

To follow along with this tutorial, you will need a domain name that you own or control.

If you need to look up your domain’s registrar, you can use the [ICANN WHOIS website](https://whois.icann.org/en) or use the `whois` command from a Linux or macOS terminal:

    whois example.com

The registrar’s website is located on the **Registrar URL** line:

    Excerpt of whois output Domain Name: EXAMPLE.COM
       Registry Domain ID: 2336799_DOMAIN_COM-VRSN
       Registrar WHOIS Server: whois.iana.org
       Registrar URL: http://res-dom.iana.org
       Updated Date: 2017-08-14T07:04:03Z
       Creation Date: 1995-08-14T04:00:00Z
    . . .

To change the nameservers, you’ll need to log into the domain registrar’s account management section. Once you’re logged in, follow the directions for your registrar below. If your registrar is not included, check their documentation for changing nameservers.

## Registrar: GoDaddy

_This section of the guide was last updated on February 16, 2018_

1. Sign in to your GoDaddy account.

2. On your account homepage, click the **DNS** tab on the right-hand side of the **Domains** main page. It will be located in between the **Add Privacy** and **Manage** tabs.

![DNS Tab](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/godaddy_step2.png)

3. On the next screen, navigate to the section of the page that reads **Nameservers.** Click **Change.**

4. When prompted, select **Custom** from the drop-down menu, and enter the following nameservers:

- ns1.digitalocean.com
- ns2.digitalocean.com
- ns3.digitalocean.com

![Manage Nameservers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/godaddy_step4.png)

Note that you will have to click **Add Nameserver** to add the last entry. Click **Save** to apply your changes.

5. Now you are ready to move on to connecting the domain with your Droplet in the DigitalOcean control panel. Check out the Conclusion section at the end of this article to find out about what to do next.

## Registrar: HostGator

_This section of the guide was last updated on February 16, 2018_

1. Sign into your HostGator account.

2. Click on the domain name that you want to use with your Droplet.

3. You will then be presented with a **Domain Overview**. Click on **Change** under **Name Servers**.

![Change Name Servers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/hostgator_steptwos.png)

4. Select **Manually set my name servers** and enter the following:

- ns1.digitalocean.com
- ns2.digitalocean.com
- ns3.digitalocean.com

![Name Servers tab](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/hostgator_step4.png)

Note that you will have to click the green **+** symbol to add the third name server.

5. Click **Save Name Servers** to apply your changes. Now you are ready to move on to connecting the domain with your Droplet in the DigitalOcean control panel. Check out the Conclusion section at the end of this article to read about what to do next.

## Registrar: Namecheap

_This section of the guide was last updated on October 10, 2017_

1. Sign in to your Namecheap account, then click **Domain List** in the left-hand column. You will be presented with a dashboard listing all of your domains. Click the **Manage** button of the domain you’d like to update.

![Namecheap domain dashboard entry](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/namecheap-domain-list.png)

2. In the **Nameservers** section of the resulting screen, select **Custom DNS** from the dropdown menu and enter the following nameservers:

- ns1.digitalocean.com
- ns2.digitalocean.com
- ns3.digitalocean.com

![Namecheap custom dns nameserver entry](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/namecheap-ns-entries.png)

3. Click the green checkmark to apply your changes. Now you are ready to move on to connecting the domain with your Droplet in the DigitalOcean control panel. Check out the Conclusion section at the end of this article to read on what to do next.

## Registrar: 1&1

_This section of the guide was last updated on February 16, 2018_

1. Sign in to your 1&1 account and go to **Domains** tab on the left side of your homepage.

![1&1 Domain Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/oneandone_stpone.png)

2. Once on the **Domains** landing page, click on your domain name.

3. On the next page, click on **Modify DNS Settings**.

4. Under **Name Server Settings** , select **Other name servers**. Enter the following nameservers:

- ns1.digitalocean.com
- ns2.digitalocean.com
- ns3.digitalocean.com

![Other name servers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/oneandone_stp4.png)

5. Scroll down to the bottom of the page and click **Save** to apply your changes. Now you are ready to move on to connecting the domain with your Droplet in the DigitalOcean control panel. Check out the Conclusion section at the end of this article to read about what to do next.

## Registrar: Name.com

_This section of the guide was last updated on February 16, 2018_

1. Sign in to your Name.com account.

2. Click on the **My Account** icon, and select **My Dashboard** from the dropdown menu.

![Domain Dashboard](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/name.com_step2.png)

3. On the **Dashboard** screen, click on your domain name.

4. On the your domain’s home screen, click on **Nameservers** , on the left side of your screen.

![Domain Menu](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/namedotcom_step4.png)

5. You will be presented with the option to **Edit** each of your nameservers. You can replace the Name.com default nameservers with the following:

- ns1.digitalocean.com
- ns2.digitalocean.com
- ns3.digitalocean.com

You will be asked to update each change individually, and to **Apply Changes** once you are finished with your edits. Be sure to also delete the fourth default nameserver from the list.

![Add Nameservers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/namedotcom_step5.png)

6. Now you are ready to move on to connecting the domain with your Droplet in the DigitalOcean control panel. Check out the Conclusion section at the end of this article to read about what to do next.

## Registrar: Network Solutions

_This section of the guide was last updated on February 16, 2018_

1. Sign in to your Network Solutions account.

2. Select **My Domain Names**.

![My Domain Names](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/network_solutions_my_domain_names.png)

3. Find the domain name that you want to use with your Droplet, then select **Change Where Domain Points**.

![Change Where Domain Points](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/network_solutions_change_where_domain_points.png)

4. Select **Domain Name Server (DNS)**, then select **Continue**.

![My Domain Names](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/network_solutions_domain_name_server.png)

5. Enter the following nameservers:

- ns1.digitalocean.com
- ns2.digitalocean.com
- ns3.digitalocean.com

![Add Nameservers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/network_solutions_add_nameservers.png)

6. Select **Continue** , then confirm your changes on the next page by selecting **Apply Changes**. Now you are ready to move on to connecting the domain with your Droplet in the DigitalOcean control panel. Check out the Conclusion section at the end of this article to read about what to do next.

## Registrar: eNom

_This section of the guide was last updated on February 16, 2018_

1. Sign in to your eNom account.

2. Under **Domains** , select **Registered Domains**. If you have multiple domains registered with eNom, select the domain name that you want to use with your Droplet.

![Domain Manager](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/eNom_step2.png)

3. Select **DNS Server Settings**.

4. Under **User our Name Servers?** , select **Custom**.

5. Enter the following nameservers:

- ns1.digitalocean.com
- ns2.digitalocean.com
- ns3.digitalocean.com

![Add Nameservers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/enom_add_nameservers.png)

6. Select **save** , then confirm your changes in the popup by selecting **OK**. Now you are ready to move on to connecting the domain with your Droplet in the DigitalOcean control panel. Check out the Conclusion section at the end of this article to read about what to do next.

## Registrar: Gandi

_This section of the guide was last updated on February 16, 2018_

1. Sign in to your Gandi account.

2. Navigate to **Domains** on the left side of your dashboard.

![Dashboard](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/gandi_steptwo.png)

3. Click on the domain you would like to use with your Droplet.

4. Select **Nameservers** from the menu on the left of your screen.

5. Click on the pen icon under the **Change** heading at the bottom of the **Nameservers** screen.

![Change Nameservers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/gandi_step5.png)

6. Fill in the nameserver fields with the following:

- ns1.digitalocean.com
- ns2.digitalocean.com
- ns3.digitalocean.com

![Add Nameservers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/gandi_step6.png)

7. Click **Save**. Now you are ready to move on to connecting the domain with your Droplet in the DigitalOcean control panel. Check out the Conclusion section at the end of this article to read about what to do next.

## Registrar: Register.com

_This section of the guide was last updated on February 16, 2018_

1. Sign in to your Register.com account.

2. Under the **Account Dashboard** , select **Domains** and then **Manage** from the list of available options.

![Account Dashboard](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/register.com_steptwo.png)

3. Click **Manage** under **Manage Product** for the domain name you want to associate with your Droplet.

![Manage Options](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/register.com_stepthree.png)

4. Under **DOMAIN NAME SYSTEM SERVERS (DNS SERVERS)**, enter the following nameservers into the **New DNS Server** fields:

- ns1.digitalocean.com
- ns2.digitalocean.com
- ns3.digitalocean.com

![Add Nameservers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/register_dotcom_add_nameservers.png)

5. Select **Continue** , then confirm your changes on the next page by selecting **Continue**. Now you are ready to move on to connecting the domain with your Droplet in the DigitalOcean control panel. Check out the Conclusion section at the end of this article to read about what to do next.

## Registrar: A Small Orange

_This section of the guide was last updated on October 27, 2014_

1. Sign in to your A Small Orange account and select **My Domains**.

![My Domains](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/a_small_orange_my_domains.png)

2. Find the domain name that you want to use with your Droplet, then select **Manage Domain** to the right of that domain name.

3. By default, A Small Orange locks your domain to prevent it from being transferred away without your authorization. This means that before we can change the nameservers, we’ll need to disable this lock. Select the **Registrar Lock** tab, then select **Disable Registrar Lock**.

4. Select the **Nameservers** tab.

5. Enter the following nameservers:

- ns1.digitalocean.com
- ns2.digitalocean.com
- ns3.digitalocean.com

![Add Nameservers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/a_small_orange_add_nameservers.png)

6. Select **Change Nameservers** to apply your changes. Now you are ready to move on to connecting the domain with your Droplet in the DigitalOcean control panel. Check out the Conclusion section at the end of this article to read on what to do next.

## Registrar: iwantmyname

_This section of the guide was last updated on February 16, 2018_

1. Sign in to your iwantmyname account and select the **Domains** tab.

2. Select the domain name that you want to use with your Droplet.

3. Under **Nameservers** , select **update nameservers**.

4. Unlike many other domain registrars, iwantmyname features a menu of popular web hosts with preconfigured DNS settings.

![Popular settings menu](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/iwantmyname_step4.png)

5. Choose **DigitalOcean (ns1-3.digitalocean.com)** from the dropdown menu, and the fields below will be automatically filled in with the correct settings.

![Add Nameservers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/iwantmyname_add_nameservers.png)

6. Select **Update nameservers** to apply your changes. Now you are ready to move on to connecting the domain with your Droplet in the DigitalOcean control panel. Check out the Conclusion section at the end of this article to read about what to do next.

## Registrar: Google Domains

_This section of the guide was last updated on February 26, 2019_

1. Sign in to your Google Domains account.

2. Select the domain name that you want to use with your Droplet.

3. On the lefthand navbar, click on **DNS**.

![Configure DNS](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/gdomains_step_3.png)

4. Click on **Use custom name servers**.

![Custom Name Servers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/googledomains_step4.png)

5. Enter the following nameservers:

- ns1.digitalocean.com
- ns2.digitalocean.com
- ns3.digitalocean.com

![Add Nameservers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/point_to_nameservers/googledomains_step5.png)

**Note:** You’ll need to hit the **+** to the right of the nameserver field to make more fields visible.

6. Select **Save** to apply your changes. Now you are ready to move on to connecting the domain with your Droplet in the DigitalOcean control panel. Check out the Conclusion section below to read about what to do next.

## Additional Registrars

There are additional domain registrars that you can use to link your domain to DigitalOcean’s nameservers. The following list of registrars includes links to documentation on how to transfer domains to custom nameservers. DigitalOcean’s nameservers are:

- ns1.digitalocean.com
- ns2.digitalocean.com
- ns3.digitalocean.com

You can enter these nameservers into the appropriate fields when prompted, following the examples outlined in the previous sections.

- [Bluehost](https://my.bluehost.com/hosting/help/transferaway).

- [BigRock](https://manage.bigrock.in/kb/servlet/KBServlet/faq455.html).

- [Joker.com](https://joker.com/faq/content/11/102/en/how-do-i-change-my-nameservers.html).

- [DreamHost](https://help.dreamhost.com/hc/en-us/articles/216385417-How-do-I-change-my-nameservers-at-DreamHost-).

- [OVH](https://www.ovh.com/world/g2015.general_information_about_dns_servers#modify_your_dns_servers_adding_new_dns_servers).

- [123 Reg](https://www.123-reg.co.uk/support/answers/Video/Domains-Archive/Domain-Configuration/how-do-i-change-the-nameservers-for-my-domain-name-1206/).

- [Media Temple](https://mediatemple.net/community/products/dv/204643220/how-do-i-edit-my-domain's-nameservers).

- [Hover](https://help.hover.com/hc/en-us/articles/217282477-How-to-Change-your-domain-nameservers-DNS-servers-).

## Conclusion

It will take some time for the name server changes to propagate after you’ve saved them. During this time, the domain registrar communicates the changes you’ve made with your ISP (Internet Service Provider). In turn, your ISP caches the new nameservers to ensure quick site connections. This process usually takes about 30 minutes, but could take up to a few hours depending on your registrar and your ISP’s communication methods.

Once your domain is pointed to DigitalOcean’s nameservers, you can begin managing its DNS records from the Control Panel. See [An Introduction to DigitalOcean DNS](how-to-set-up-a-host-name-with-digitalocean) to get started. You can also learn more about how DNS works in [An Introduction to DNS Terminology, Components, and Concepts](an-introduction-to-dns-terminology-components-and-concepts)
