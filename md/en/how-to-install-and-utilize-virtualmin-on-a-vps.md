---
author: 
date: 2013-08-12
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-and-utilize-virtualmin-on-a-vps
---

# How To Install and Utilize VirtualMin on a VPS

### About Virtualmin

Virtualmin is a Webmin module which allows for extensive management of (multiple) virtual private servers. You will be able to manage Apache, Nginx, PHP, DNS, MySQL, PostgreSQL, mailboxes, FTP, SSH, SSL, Subversion/Git repositories and many more.

In this tutorial, we will be installing the GPL (free) edition of Virtualmin on a freshly created VPS (droplet).

## Prerequisites

- Virtualmin highly recommends using a freshly installed server to prevent conflicts, assuming you just created a new VPS, this should be all good.
- Confirm that your VPS has a fully qualified domain name set as hostname. An example of a fully qualified domain name is "[myserver.example.com](http://myserver.example.com)" or "[example.com](http://example.com)". Make sure that the domain name points to your server's IP address. Use the following command to check your current hostname. 

    hostname -f

 And use the following command to change your hostname if necessary. 

    hostname [myserver.example.com](http://myserver.example.com)

## Login as Root

Grab the IP address of your droplet from the DigitalOcean control panel and use SSH to login as root.

    ssh [root@123.45.67.89](mailto:root@123.45.67.89)

## Downloading the Install Script

Virtualmin provides an install script which allows for an easy installation. Use the following command to download the script to your root directory.

    wget [http://software.virtualmin.<wbr>com/gpl/scripts/install.sh</wbr>](http://software.virtualmin.com/gpl/scripts/install.sh) -O /root/virtualmin-install.sh

You should expect to see something like this when it's finished:

    2013-07-06 11:03:57 (129 KB/s) - `/root/virtualmin-install.sh' saved [45392/45392]

## Running the Install Script
 Now it's time to run the script we just downloaded.

    sh /root/virtualmin-install.sh

This will start the installation wizard. It will start with a short disclaimer, after accepting it the installation will begin.

## Accessing Virtualmin

When the install script has finished installing, you can reach Virtualmin with the following URL:

**[https://myserver.example.com:<wbr>10000/</wbr>](https://myserver.example.com:10000/)**

There you can login with your root username and password. Once you are logged in the "Post-Installation Wizard", it will begin to configure your Virtualmin installation.

## Post-Installation Wizard

This wizard is pretty self-explanatory, we'll cover some of the steps with some additional information.

**Memory use**

- Preload Virtualmin libraries? This will make your Virtualmin UI faster, use this when you are going to use the UI extensively, the UI is very usable without it.
- Run email domain lookup server? If fast e-mail is important to you and you have the spare RAM then it's recommended to enable this.

**Virus scanning**

- Run ClamAV server scanner? This is explained pretty well on the page, if your server receives a lot of e-mails then it's beneficial to enable it.

**Note:** If you are installing Virtualmin on a 512MB VPS and you have just enabled ClamAV server scanner in the step above, then it is very likely that you run accros this error:

     A problem occurred testing the ClamAV server scanner : ERROR: Can't connect to clamd: No such file or directory ----------- SCAN SUMMARY ----------- Infected files: 0 Time: 0.000 sec (0 m 0 s) 

The reason why you get this error is because your VPS is running out of RAM... you can choose to upgrade your RAM or add swap space to handle the increased memory usage.

 For more information about swap space and how to enable it, please follow this tutorial: [https://www.digitalocean.com/<wbr>community/articles/how-to-add-<wbr>swap-on-ubuntu-12-04</wbr></wbr>](https://www.digitalocean.com/community/articles/how-to-add-swap-on-ubuntu-12-04). 

**Spam filtering**

- Run SpamAssassin server filter?  
  
 Again this is explained pretty well on the page, if your server receives a lot of e-mails then it's beneficial to enable it.  

**Database servers**

This step should be pretty clear assuming you know what MySQL or PostgreSQL is. Enable whichever one you need.

If you picked MySQL, the next step will ask you to enter a root password for your MySQL server. The step after that asks what type of configuration MySQL should use.

It's recommended to pick the one that matches your RAM (I believe it selects the right one by default).

**DNS zones**

If you plan on managing your DNS zones with Virtualmin then enter your primary and secondary nameservers here.

**Passwords**

Virtualmin gives you two choices on how it should save passwords. It is highly recommended to select "Only store hashed passwords".

This way if any uninvited people get into your server they won't be able to retrieve any personal passwords.

All right, you've completed the post-installation wizard! You might see a big yellow bar on the top of the page with a button that says "Re-check and refresh configuration".

It's recommended to press that button just to make sure everything is well.

If you run into an error during that check, follow the instructions to resolve it and re-check your configuration until all errors are gone.

## Some Useful Knowledge

Here's some information which will help you get around Virtualmin:

**Virtual Private Server**

A virtual private server (usually) represents a website, typically every website has it's own virtual private server.

**Sub-server**

A sub-server sounds confusing but it's basically a subdomain.

**Virtualmin vs Webmin**

As you can see on the top left, you have Virtualmin and Webmin. These are different control panels, Virtualmin is where you manage all the VPS and anything related to that. Webmin is where you manage the server itself.

**Documentation**

Virtualmin is very well documented, this means that every page has it's own help page and every option's label (the label in front of the input field) is linked to an explanation of that option.

Here's a screenshot explaining the menu structure of Virtualmin.

 ![](https://assets.digitalocean.com/tutorial_images/IyndTvb.jpg)
## Setting Up a Virtual Private Server

Now that we've gone through the installation and wizard, we can start setting up our virtual private server(s). Click "Create Virtual Server" in the navigation on the left side.

Enter the domain name you want to setup a server for, in this tutorial we will use: [example.com](http://example.com).

Enter an administration password which will become the main password to manage the virtual private server. If you are managing the virtual private server by yourself then you don't really need to know this password. In that case, I suggest using a long generated password for extra security.

Virtualmin allows you to manage server configuration templates and account plans, these can be modified under "System Settings" and then "Server Templates" and "Account Plans".

You can specify an administration username, leaving it on automatic would make "example" the username.

Have a look at the options hidden underneath the other tabs and enable/disable/change anything you'd like to configure your virtual private server.

Now click "Create Server", Virtualmin will execute the steps needed to setup your virtual private server, if any errors occur, it will display them there.

## Setting Up a Subdomain

Now that we've setup our virtual private server, it's time to add a subdomain, click on "Create Virtual Server" again.

Notice how different options are now on the top of the page: "Top-level server" (Virtual private server), "Sub-server" (Subdomain), "Alias of [example.com](http://example.com)" and "Alias of [example.com](http://example.com), with own e-mail".

Click on "Sub-server" to create a subdomain of "[example.com](http://example.com)".

Fill in the full domain name ([test.example.com](http://test.example.com)) and go through the options below it, once you are ready click "Create Server".

Watch Virtualmin do what it needs to do and after it's all done, you should see "[test.example.com](http://test.example.com)" as the currently selected virtual private server.

## Setting Up Users

First of all, let's make sure we are on the top-level server "[example.com](http://example.com)" and then click on "Edit Users". On the top, you see you have three options of creating users: "Add a user to this server.", "Batch create users." and "Add a website FTP access user."

If you are only looking to setup a user that has FTP access then click that link, we will go with "Add a user to this server.". The first step is to enter the user's email address, real name and password. Then, carefully look at the other options available to get your ideal setup, when you're done press "Create".

You will now see your user being added to the list, the main user is bold. It also tells you what the user's login is (by default this is something like test.example).

For further setup of e-mail addresses see the "Edit Mail Aliases" link in the menu.

## Setting Up Your Databases

Click the "Edit Databases" link in the menu, remember to set your virtual private server correctly. Depending on your settings, every virtual private server has its own database (or multiple).

Every database has a "Manage..." link which gives you a very simple view of the database and allows you to execute queries. Now go back to the "Edit Databases" page and click "Passwords", here is your database's password which was automatically generated by Virtualmin.

Moving on to the "Import Database" tab you can assign an existing database (a database created outside of Virtualmin) to the current virtual private server, useful for when you created databases using a MySQL client of some form.

Last but not least, the "Remote hosts" tab allows you to provide multiple hosts to connect to your server, it's recommended to leave it as is (localhost) and use an SSH tunnel to login to your database server.

## Directory Structure

Virtualmin has a very nicely organised directory structure. See the following scheme.

     `-- /home/example |-- /home/example/awstats |-- /home/example/cgi-bin |-- /home/example/domains | `-- /home/example/domains/[test.<wbr>example.com</wbr>](http://test.example.com) | |-- /home/example/domains/[test.<wbr>example.com/awstats</wbr>](http://test.example.com/awstats) | |-- /home/example/domains/[test.<wbr>example.com/cgi-bin</wbr>](http://test.example.com/cgi-bin) | |-- /home/example/domains/[test.<wbr>example.com/homes</wbr>](http://test.example.com/homes) | |-- /home/example/domains/[test.<wbr>example.com/logs</wbr>](http://test.example.com/logs) | `-- /home/example/domains/[test.<wbr>example.com/public_html</wbr>](http://test.example.com/public_html) | `-- /home/example/domains/[test.<wbr>example.com/public_html/stats</wbr>](http://test.example.com/public_html/stats) |-- /home/example/etc | `-- /home/example/etc/php5 |-- /home/example/fcgi-bin |-- /home/example/homes | `-- /home/example/homes/test | `-- /home/example/homes/test/<wbr>Maildir
        | |-- /home/example/homes/test/<wbr>Maildir/cur
        | |-- /home/example/homes/test/<wbr>Maildir/new
        | `-- /home/example/homes/test/<wbr>Maildir/tmp
        |-- /home/example/logs
        |-- /home/example/public_html
        | `-- /home/example/public_html/<wbr>stats
        `-- /home/example/tmp	
    		</wbr></wbr></wbr></wbr></wbr>

As you can see, everything is put in **/home/example** and our subdomain can be found in **/home/example/domains/[test.<wbr>example.com/</wbr>](http://test.example.com/)**. Every domain has its own logs directory and Virtualmin comes with awstats by default and is accessible through "[http://www.example.com/stats](http://www.example.com/stats)"<wbr>, unless you disabled this during the creation of the virtual private server.</wbr>

## Where Do I Go from Here?

Take some time to go through Virtualmin's settings. There are many things you can change to make your experience better. Don't forget to also explore the Webmin side of this control panel.

This tutorial only touches the surface of Virtualmin and there's a lot more which can be done with it or added to it through modules. There are even modules for setting up svn/git repositories.
