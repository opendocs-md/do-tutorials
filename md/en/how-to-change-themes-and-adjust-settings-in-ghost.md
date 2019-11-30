---
author: Justin Ellingwood
date: 2013-10-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-change-themes-and-adjust-settings-in-ghost
---

# How To Change Themes and Adjust Settings in Ghost

## Introduction

* * *

Ghost is a great new blogging platform that focuses on content creation and presentation over the superfluous bells and whistles that dominate other platforms. It provides a clean, easy-to-use interface and can produce very polished results.

In the [first part of this article](https://www.digitalocean.com/community/articles/how-to-manage-content-using-the-ghost-blogging-platform), we discussed how to manage content in Ghost by creating, editing, and deleting blog posts.

The second part of this article will cover some simple configuration that will help get your site off the ground.

## How To Change Ghost Themes

* * *

The main aesthetic adjustment that you can make to your blog is the theme. A theme controls how all of the pieces are presented visually and how the elements are drawn together.

There are a number of different themes you can get for Ghost. Some are free and some you must purchase.

We will apply one of the free themes from the Ghost Marketplace called “N'Coded”.

You can see this theme by visiting:

    marketplace.ghost.org

Click on the “N'Coded” theme to be taken to the theme’s GitHub page.

Log into your Ghost VPS and navigate to the Ghost themes directory:

    cd /var/www/ghost/content/themes/

We will use git to install the theme into this directory. Install git if it is not already present in the system:

    apt-get update && apt-get install git-core -y

Now, we can clone the project from the GitHub page:

    git clone https://github.com/polygonix/N-Coded.git

Change ownership of the files to the Ghost user and group:

    chown -R ghost:ghost N-Coded

Restart Ghost to allow it to see the new theme folder:

    service ghost restart

Open your web browser and navigate to the general settings page:

    your\_domain\_name/ghost/settings/general

Scroll down to the bottom and you will see a “Theme” area. Change the theme to “N-Coded”:

![Ghost change theme](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ghost_use/change_theme.png)

Click the “Save” button in the upper right corner.

Navigate to your blog to see the new theme:

![Ghost theme example](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ghost_use/theme_example.png)

## How To Change Ghost Settings

* * *

You can change most of your blog’s settings by navigating to the “settings” page of your blog:

    your\_domain\_name/ghost/settings

You will be taken to the general settings page:

![Ghost general settings](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ghost_use/gen_settings.png)

Here, you can adjust items like the title and description of your blog, and update the logo and cover images.

To change details for your user, click on the “User” tab on the left-hand side:

![Ghost user settings](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ghost_use/user_settings.png)

Here, you can adjust settings for your profile. These details include your user name and email, as well as a short biography and a link to a personal external site.

If you scroll to the bottom of the page, you can change your personal password by typing in your current password and supplying/confirming a replacement:

![Ghost change password](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ghost_use/change_password.png)

## Conclusion

* * *

Ghost helps you stay focused on your content by removing the distractions present in other blogging platforms. You should now be able to start generating content and adjust themes and the most common settings.

Explore the interface and practice using the system to manage your ideas. Publish some posts and create some drafts without publishing to see how Ghost organizes those pieces. The more you play around, the more comfortable you will be using the platform on a daily basis.

By Justin Ellingwood
