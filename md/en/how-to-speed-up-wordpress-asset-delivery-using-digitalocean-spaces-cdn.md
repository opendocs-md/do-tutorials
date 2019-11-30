---
author: Hanif Jetha
date: 2018-09-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn
---

# How to Speed Up WordPress Asset Delivery Using DigitalOcean Spaces CDN

## Introduction

Implementing a CDN, or **C** ontent **D** elivery **N** etwork, to deliver your WordPress site’s static assets can greatly decrease your servers’ bandwidth usage as well as speed up page load times for geographically dispersed users. WordPress static assets include images, CSS stylesheets, and JavaScript files. Leveraging a system of edge servers distributed worldwide, a [CDN](using-a-cdn-to-speed-up-static-content-delivery) caches copies of your site’s static assets across its network to reduce the distance between end users and this bandwidth-intensive content.

In a previous Solutions guide, [How to Store WordPress Assets on DigitalOcean Spaces](how-to-store-wordpress-assets-on-digitalocean-spaces), we covered offloading a WordPress site’s Media Library (where images and other site content gets stored) to DigitalOcean Spaces, a highly redundant object storage service. We did this using the [DigitalOcean Spaces Sync plugin](https://wordpress.org/plugins/do-spaces-sync/), which automatically syncs WordPress uploads to your Space, allowing you to delete these files from your server and free up disk space.

In this [Solutions](https://www.digitalocean.com/community/tags/solutions?type=tutorials) guide, we’ll extend this procedure by enabling the Spaces CDN and rewriting Media Library asset URLs. This forces users’ browsers to download static assets directly from the CDN, a geographically distributed set of cache servers optimized for delivering static content. We’ll go over how to enable the CDN for Spaces, how to rewrite links to serve your WordPress assets from the CDN, and finally how to test that your website’s assets are being correctly delivered by the CDN.

We’ll demonstrate how to implement Media Library offload and link rewriting using the free and open-source Spaces Sync plugin. We’ll also cover how to do this using two popular paid WordPress plugins: **[WP Offload Media](https://deliciousbrains.com/wp-offload-s3/)** and **[Media Library Folders Pro](https://maxgalleria.com/downloads/media-library-plus-pro/)**. You should choose the plugin that suits your production needs best.

## Prerequisites

Before you begin this tutorial, you should have a running WordPress installation on top of a LAMP or LEMP stack. You should also have [WP-CLI](http://wp-cli.org/) installed on your WordPress server, which you can learn to set up by following [these instructions](how-to-back-up-wordpress-site-to-spaces#using-plugins-to-create-backups).

To offload your Media Library, you’ll need a DigitalOcean Space and an access key pair:

- To learn how to create a Space, consult [the Spaces product documentation](https://www.digitalocean.com/docs/spaces/how-to/create-and-delete).
- To learn how to create an access key pair and upload files to your Space using the open source `s3cmd` tool, consult [s3cmd 2.x Setup](https://www.digitalocean.com/docs/spaces/resources/s3cmd/), also on the DigitalOcean product documentation site.

There are a few WordPress plugins that you can use to offload your WordPress assets:

- **[DigitalOcean Spaces Sync](https://wordpress.org/plugins/do-spaces-sync/)** is a free and open-source WordPress plugin for offloading your Media Library to a DigitalOcean Space. You can learn how to do this in [How To Store WordPress Assets on DigitalOcean Spaces](how-to-store-wordpress-assets-on-digitalocean-spaces).
- **[WP Offload Media](https://deliciousbrains.com/wp-offload-media/)** is a paid plugin that copies files from your WordPress Media Library to DigitalOcean Spaces and rewrites URLs to serve the files from the CDN. With the Assets Pull addon, it can identify assets (CSS, JS, images, etc) used by your site (for example by WordPress themes) and also serve these from CDN.
- **[Media Library Folders Pro](https://maxgalleria.com/downloads/media-library-plus-pro/)** is another paid plugin that helps you organize your Media Library assets, as well as offload them to DigitalOcean Spaces.

Using a [custom domain](https://www.digitalocean.com/docs/spaces/how-to/customize-cdn-endpoint) with Spaces CDN is highly recommended. This will drastically improve Search Engine Optimization (SEO) for your site by keeping your offloaded asset URLs similar to your Wordpress site’s URLs. To use a custom domain with Spaces CDN, you need to ensure that you first add your domain to your DigitalOcean account:

- To learn how to do this, consult [How to Add Domains](https://www.digitalocean.com/docs/networking/dns/how-to/add-domains/).

For testing purposes, be sure to have a modern web browser such as [Google Chrome](https://www.google.com/chrome/) or [Firefox](https://www.mozilla.org/firefox) installed on your client (e.g. laptop) computer.

Once you have a running WordPress installation and have created a DigitalOcean Space, you’re ready to enable the CDN for your Space and begin with this guide.

## Enabling Spaces CDN

We’ll begin this guide by enabling the CDN for your DigitalOcean Space. This will not affect the availability of existing objects. With the CDN enabled, objects in your Space will be “pushed out” to edge caches across the content delivery network, and a new CDN endpoint URL will be made available to you. To learn more about how CDNs work, consult [Using a CDN to Speed Up Static Content Delivery](using-a-cdn-to-speed-up-static-content-delivery).

First, enable the CDN for your Space by following [How to Enable the Spaces CDN](http://digitalocean.com/docs/spaces/how-to/enable-cdn).

If you’d like to use a custom domain with Spaces CDN (recommended), create the subdomain CNAME record and appropriate SSL certificates by following [How to Customize the Spaces CDN Endpoint with a Subdomain](https://www.digitalocean.com/docs/spaces/how-to/customize-cdn-endpoint). Note down the subdomain you’ll be using with Spaces CDN, as we’ll need to use this when configuring the WordPress asset offload plugin.

Navigate back to your Space and reload the page. You should see a new **Endpoints** link under your Space name:

![Endpoints Link](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/endpoints_link.png)

These endpoints contain your Space name. We’re using `wordpress-offload` in this tutorial.

Notice the addition of the new **Edge** endpoint. This endpoint routes requests for Spaces objects through the CDN, serving them from the edge cache as much as possible. Note down this **Edge** endpoint, which you’ll use to configure your WordPress plugin in future steps. If you created a subdomain for Spaces CDN, this subdomain is an alias for the **Edge** endpoint.

Now that you have enabled the CDN for your Space, you’re ready to begin configuring your asset offload and link rewriting plugin.

If you’re using DigitalOcean Spaces Sync and continuing from [How to Store WordPress Assets on DigitalOcean Spaces](how-to-store-wordpress-assets-on-digitalocean-spaces), begin reading from the following section. If you’re not using Spaces Sync, skip to either the [WP Offload Media section](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#wordpress-offload-media-plugin) or the [Media Library Folders Pro section](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#media-library-folders-pro-and-cdn-enabler-plugins), depending on the plugin you choose to use.

## Spaces Sync Plugin

If you’d like to use the free and open-source DigitalOcean Spaces Sync and CDN Enabler plugins to serve your files from the CDN’s edge caches, follow the steps outlined in this section.

We’ll begin by ensuring that our WordPress installation and Spaces Sync plugin are configured correctly and are serving assets from DigitalOcean Spaces.

### Modifying Spaces Sync Plugin Configuration

Continuing from [How To Store WordPress Assets on DigitalOcean Spaces](how-to-store-wordpress-assets-on-digitalocean-spaces#storing-files-on-spaces), your Media Library should be offloaded to your DigitalOcean Space and your Spaces Sync plugin settings should look as follows:

![Sync Cloud Only](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/do_spaces_sync_plugin/sync_cloud_only.png)

If you haven’t completed the [How To Store WordPress Assets on DigitalOcean Spaces](how-to-store-wordpress-assets-on-digitalocean-spaces#storing-files-on-spaces) tutorial, you can still follow this guide by installing the Spaces Sync plugin using the [built-in plugin installer](https://codex.wordpress.org/Managing_Plugins#Installing_Plugins). If you encounter any errors, please consult the steps in this prerequisite guide.

We are going to make some minor changes to ensure that our configuration allows us to offload WordPress themes and other directories, beyond the `wp-content/uploads` Media Library folder.

First, we’re going to modify the **Full URL-path to files** field so that the Media Library files are served from our Space’s CDN and not locally from the server. This setting essentially rewrites links to Media Library assets, changing them from file links hosted locally on your WordPress server, to file links hosted on the DigitalOcean Spaces CDN.

Recall the **Edge** endpoint you noted down in the [Enabling Spaces CDN](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#enabling-spaces-cdn) step. If you are using a custom subdomain with Spaces CDN, you’ll use that subdomain instead of the Edge endpoint.

In this tutorial, the Space’s name is `wordpress-offload` and the Space’s CDN endpoint is:

    https://wordpress-offload.nyc3.cdn.digitaloceanspaces.com

Now, in the Spaces Sync plugin settings page, replace the URL in the **Full URL-path to files** field with your Spaces CDN endpoint, followed by `/wp-content/uploads`.

In this tutorial, using the above Spaces CDN endpoint, the full URL would be:

    https://wordpress-offload.nyc3.cdn.digitaloceanspaces.com/wp-content/uploads

If you’re using a custom subdomain, say `https://assets.example.com`, the full URL would look as follows:

    https://assets.example.com/wp-content/uploads

Next, for the **Local path** field, enter the full path to the `wp-content/uploads` directory on your WordPress server. In this tutorial, the path to the WordPress installation on the server is `/var/www/html/`, so the full path to `uploads` would be `/var/www/html/wp-content/uploads`.

**Note:** If you’re continuing from [How To Store WordPress Assets on DigitalOcean Spaces](how-to-store-wordpress-assets-on-digitalocean-spaces), this guide will slightly modify the path to files in your Space to enable you to optionally offload themes and other `wp-content` assets. You should clear out your Space before doing this (be sure to save a copy of the files), or alternatively you can transfer existing files into the correct `wp-content/uploads` Space directory using [s3cmd](https://www.digitalocean.com/docs/spaces/resources/s3cmd-usage/).

In the **Storage prefix** field, we’re going to enter `/wp-content/uploads`, which will ensure that we build the correct `wp-content` directory hierarchy so that we can offload other WordPress directories to this Space.

**Filemask** can remain wildcarded with `*`, unless you’d like to exclude certain files.

It’s not necessary to check the **Store files only in the cloud and delete…** option; only check this box if you’d like to delete the Media Library assets from your server after they’ve been successfully uploaded to your DigitalOcean Space.

Your final settings should look something like this:

![Final Spaces Sync Settings](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/modified_sync_settings.png)

Be sure to replace the above values with the values corresponding to your WordPress installation and Spaces configuration.

Finally, hit **Save Changes**.

You should see a **Settings saved** box appear at the top of your screen, confirming that the Spaces Sync plugin settings have successfully been updated.

**Future** WordPress Media Library uploads should now be synced to your DigitalOcean Space, and served using the Spaces Content Delivery Network.

In this step, we did _not_ offload the WordPress theme or other `wp-content` assets. To learn how to transfer these assets to Spaces and serve them using the Spaces CDN, skip to [Offloading Additional Assets](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#offloading-additional-assets-(optional)).

To verify and test that your Media Library uploads are being delivered from the Spaces CDN, skip to [Test CDN Caching](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#testing-cdn-caching).

## WordPress Offload Media Plugin

The DeliciousBrains WordPress Offload Media [plugin](https://deliciousbrains.com/wp-offload-media/) allows you to quickly and automatically upload your Media Library assets to DigitalOcean Spaces and rewrite links to these assets so that you can deliver them directly from Spaces or via the Spaces CDN. In addition, [the Assets Pull addon](https://deliciousbrains.com/wp-offload-media/doc/assets-pull-addon/) allows you to quickly offload additional WordPress assets like JS, CSS, and font files in combination with a [pull CDN](using-a-cdn-to-speed-up-static-content-delivery#push-vs-pull-zones). Setting up this addon is beyond the scope of this guide but to learn more you can consult [the DeliciousBrains documentation](https://deliciousbrains.com/wp-offload-media/doc/assets-pull-addon/).

We’ll begin by installing and configuring the WP Offload Media plugin for a sample WordPress site.

### Installing WP Offload Media Plugin

To begin, you must purchase a copy of the plugin on the DeliciousBrains [plugin site](https://deliciousbrains.com/wp-offload-media/pricing/). Choose the appropriate version depending on the number of assets in your Media Library, and support and feature requirements for your site.

After going through checkout, you’ll be brought to a post-purchase site with a download link for the plugin and a license key. The download link and license key will also be sent to you at the email address you provided when purchasing the plugin.

Download the plugin and navigate to your WordPress site’s admin interface (`https://your_site_url/wp-admin`). Log in if necessary. From here, hover over **Plugins** and click on **Add New**.

Click **Upload Plugin** and the top of the page, **Choose File** , and then select the zip archive you just downloaded.

Click **Install Now** , and then **Activate Plugin**. You’ll be brought to WordPress’s plugin admin interface.

From here, navigate to the WP Offload Media plugin’s settings page by clicking **Settings** under the plugin name.

You’ll be brought to the following screen:

![WP Offload Media Configuration](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/wp_offload_storage_provider.png)

Click the radio button next to **DigitalOcean Spaces**. You’ll now be prompted to either configure your Spaces Access Key in the `wp-config.php` file (recommended), or directly in the web interface (the latter will store your Spaces credentials in the WordPress database).

We’ll configure our Spaces Access Key in `wp-config.php`.

Log in to your WordPress server via the command line, and navigate to your WordPress root directory (in this tutorial, this is `/var/www/html`). From here, open up `wp-config.php` in your favorite editor:

    sudo nano wp-config.php

Scroll down to the line that says `/* That's all, stop editing! Happy blogging. */`, and before it insert the following lines containing your Spaces Access Key pair (to learn how to generate an access key pair, consult the [Spaces product docs](https://www.digitalocean.com/docs/spaces/how-to/administrative-access/#access-keys)):

wp-config.php

    . . . 
    define( 'AS3CF_SETTINGS', serialize( array(
        'provider' => 'do',
        'access-key-id' => 'your_access_key_here',
        'secret-access-key' => 'your_secret_key_here',
    ) ) );
    
    /* That's all, stop editing! Happy blogging. */
    . . .

Once you’re done editing, save and close the file. The changes will take effect immediately.

Back in the WordPress Offload Media plugin admin interface, select the radio button next to **Define access keys in wp-config.php** and hit **Save Changes**.

You should be brought to the following interface:

![WP Offload Bucket Selection](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/wp_offload_bucket_selection.png)

On this configuration page, select the appropriate region for your Space using the **Region** dropdown and enter your Space name next to **Bucket** (in this tutorial, our Space is called `wordpress-offload`).

Then, hit **Save Bucket**.

You’ll be brought to the main WP Offload Media configuration page. At the top you should see the following warning box:

![WP Offload License](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/wp_offload_license.png)

Click on **enter your license key** , and on the subsequent page enter the license key found in your email receipt or on the checkout page and hit **Activate License**.

If you entered your license key correctly, you should see **License activated successfully**.

Now, navigate back to main WP Offload Media configuration page by clicking on **Media Library** at the top of the window.

At this point, WP Offload Media has successfully been configured for use with your DigitalOcean Space. You can now begin offloading assets and delivering them using the Spaces CDN.

### Configuring WP Offload Media

Now that you’ve linked WP Offload Media with your DigitalOcean Space, you can begin offloading assets and configuring URL rewriting to deliver media from the Spaces CDN.

You should see the following configuration options on the main WP Offload Media configuration page:

![WP Offload Main Nav](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/wp_offload_main_nav.png)

These defaults should work fine for most use cases. If your Media Library exists at a nonstandard path within your WordPress directory, enter the path in the text box under the **Path** option.

If you’d like to change asset URLs so that they are served directly from Spaces and not your WordPress server, ensure the toggle is set to **On** next to **Rewrite Media URLs**.

To deliver Media Library assets using the Spaces CDN, ensure you’ve enabled the CDN for your Space (see [Enable Spaces CDN](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#enabling-spaces-cdn) to learn how) and have noted down the URL for the **Edge** endpoint. Hit the toggle next to **Custom Domain (CNAME)**, and In the text box that appears, enter the CDN **Edge** endpoint URL, without the `https://` prefix.

In this guide the Spaces CDN endpoint is:

    https://wordpress-offload.nyc3.cdn.digitaloceanspaces.com

So here we enter:

     wordpress-offload.nyc3.cdn.digitaloceanspaces.com

If you’re using a custom subdomain with Spaces CDN, enter that subdomain here:

    your_subdomain.example.com

To improve security, we’ll force HTTPS for requests to Media Library assets (now served using the CDN) by setting the toggle to **On**.

You can optionally clear out files that have been offloaded to Spaces from your WordPress server to free up disk space. To do this, hit **On** next to **Remove Files From Server**.

Once you’ve finished configuring WP Offload Media, hit **Save Changes** at the bottom of the page to save your settings.

The **URL Preview** box should display a URL containing your Spaces CDN endpoint. It should look something like the following:

`https://wordpress‑offload.nyc3.cdn.digitaloceanspaces.com/wp‑content/uploads/2018/09/21211354/photo.jpg`

If you’re using a custom subdomain with Spaces CDN, the URL preview should contain this subdomain.

This URL indicates that WP Offload Media has been successfully configured to deliver Media Library assets using the Spaces CDN. If the path doesn’t contain `cdn`, ensure that you correctly entered the **Edge** endpoint URL and _not_ the **Origin** URL (this does not apply when using a custom subdomain).

At this point, WP Offload Media has been set up to deliver your Media Library using Spaces CDN. Any **future** uploads to your Media Library will be automatically copied over to your DigitalOcean Space and served using the CDN.

You can now bulk offload existing assets in your Media Library using the built-in upload tool.

### Offloading Media Library

We’ll use the plugin’s built-in “Upload Tool” to offload existing files in our WordPress Media Library.

On the right-hand side of the main WP Offload Media configuration page, you should see the following box:

![WP Offload Upload Tool](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/wp_offload_upload_tool.png)

Click **Offload Now** to upload your Media Library files to your DigitalOcean Space.

If the upload procedure gets interrupted, the box will change to display the following:

![WP Offload Upload Tool 2](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/wp_offload_upload_tool_2.png)

Hit **Offload Remaining Now** to transfer the remaining files to your DigitalOcean Space.

Once you’ve offloaded the remaining items from your Media Library, you should see the following new boxes:

![WP Offload Success](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/wp_offload_success.png)

At this point you’ve offloaded your Media Library to your Space and are delivering the files to users using the Spaces CDN.

At any point in time, you can download the files back to your WordPress server from your Space by hitting **Download Files**.

You can also clear out your DigitalOcean Space by hitting **Remove Files**. Before doing this, ensure that you’ve first downloaded the files back to your WordPress server from Spaces.

In this step, we learned how to offload our WordPress Media Library to DigitalOcean Spaces and rewrite links to these Library assets using the WP Offload Media plugin.

To offload additional WordPress assets like themes and JavaScript files, you can use the [Asset Pull addon](https://deliciousbrains.com/wp-offload-media/doc/assets-pull-addon/) or consult the [Offload Additional Assets](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#offload-additional-assets-(optional)) section of this guide.

To verify and test that your Media Library uploads are being delivered from the Spaces CDN, skip to [Testing CDN Caching](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#testing-cdn-caching).

## Media Library Folders Pro and CDN Enabler Plugins

The MaxGalleria Media Library Folders Pro [plugin](https://maxgalleria.com/media-library-plus/) is a convenient WordPress plugin that allows you to better organize your WordPress Media Library assets. In addition, the free [Spaces addon](https://maxgalleria.com/downloads/wordpress-amazon-s3/) allows you to bulk offload your Media Library assets to DigitalOcean Spaces, and rewrite URLs to those assets to serve them directly from object storage. You can then enable the Spaces CDN and use the Spaces CDN endpoint to serve your library assets from the distributed delivery network. To accomplish this last step, you can use the [CDN Enabler](https://wordpress.org/plugins/cdn-enabler/) plugin to rewrite CDN endpoint URLs for your Media Library assets.

We’ll begin by installing and configuring the Media Library Folders Pro (MLFP) plugin, as well as the MLFP Spaces addon. We’ll then install and configure the CDN Enabler plugin to deliver Media Library assets using the Spaces CDN.

### Installing MLFP Plugin

After purchasing the MLFP plugin, you should have received an email containing your MaxGalleria account credentials as well as a plugin download link. Click on the plugin download link to download the MLFP plugin zip archive to your local computer.

Once you’ve downloaded the archive, log in to your WordPress site’s administration interface (`https://your_site_url/wp-admin`), and navigate to **Plugins** and then **Add New** in the left-hand sidebar.

From the **Add Plugins** page, click **Upload Plugin** and then select the zip archive you just downloaded.

Click **Install Now** to complete the plugin installation, and from the **Installing Plugin** screen, click **Activate Plugin** to activate MLFP.

You should then see a **Media Library Folders Pro** menu item appear in the left-hand sidebar. Click it to go to the Media Library Folders Pro interface. Covering the plugin’s various features is beyond the scope of this guide, but to learn more, you can consult [the MaxGalleria site](https://maxgalleria.com/downloads/media-library-plus-pro/) and [forums](https://maxgalleria.com/forums/).

We’ll now activate the plugin. Click into **Settings** under the MLFP menu item, and enter your license key next to the **License Key** text box. You can find your MLFP license key in the email sent to you when you purchased the plugin. Hit **Save Changes** and then **Activate License**. Next, hit **Update Settings**.

Your MLFP plugin is now active, and you can use it to organize existing or new Media Library assets for your WordPress site.

We’ll now install and configure the Spaces addon plugin so that you can offload and serve these assets from DigitalOcean Spaces.

### Installing MLFP Spaces Addon Plugin and Offload Media Library

To install the Spaces Addon, log in to your MaxGalleria [account](https://maxgalleria.com/my-account/). You can find your account credentials in an email sent to you when you purchased the MLFP plugin.

Navigate to the **Addons** page in the top menu bar and scroll down to **Media Sources**. From here, click into the **Media Library Folders Pro S3 and Spaces** option.

From this page, scroll down to the **Pricing** section and select the option that suits the size of your WordPress Media Library (for Media Libraries with 3000 images or less, the addon is free).

After completing the addon “purchase,” you can navigate back to your account page (by clicking the **Account** link in the top menu bar), from which the addon plugin will now be available.

Click on the **Media Library Folders Pro S3** image and the plugin download should begin.

Once the download completes, navigate back to your WordPress administration interface, and install the downloaded plugin using the same method as above, by clicking **Upload Plugin**. Once again, hit **Activate Plugin** to activate the plugin.

You will likely receive a warning about configuring access keys in your `wp-config.php` file. We’ll configure these now.

Log in to your WordPress server using the console or SSH, and navigate to your WordPress root directory (in this tutorial, this is `/var/www/html`). From here, open up `wp-config.php` in your favorite editor:

    sudo nano wp-config.php

Scroll down to the line that says `/* That's all, stop editing! Happy blogging. */`, and before it insert the following lines containing your Spaces Access Key pair and a plugin configuration option (to learn how to generate an access key pair, consult the [Spaces product docs](https://www.digitalocean.com/docs/spaces/how-to/administrative-access/#access-keys)):

wp-config.php

    . . . 
    define('MF_AWS_ACCESS_KEY_ID', 'your_access_key_here');
    define( 'MF_AWS_SECRET_ACCESS_KEY', 'your_secret_key_here');
    define('MF_CLOUD_TYPE', 'do')
    
    /* That's all, stop editing! Happy blogging. */
    . . .

Once you’re done editing, save and close the file.

Now, navigate to your DigitalOcean Space from the [Cloud Control Panel](https://cloud.digitalocean.com/), and create a folder called `wp-content` by clicking on **New Folder**.

From here, navigate back to the WordPress administration interface, and click into **Media Library Folders Pro** and then **S3 & Spaces Settings** in the sidebar.

The warning banner about configuring access keys should now have disappeared. If it’s still present, you should double check your `wp-config.php` file for any typos or syntax errors.

In the **License Key** text box, enter the license key that was emailed to you after purchasing the Spaces addon. Note that this license key is different from the MLFP license key. Hit **Save Changes** and then **Activate License**.

Once activated, you should see the following configuration pane:

![MLFP Spaces Addon Configuration](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/spaces_addon_config.png)

From here, click **Select Image Bucket & Region** to select your DigitalOcean Space. Then select the correct region for your Space and hit **Save Bucket Selection**.

You’ve now successfully connected the Spaces offload plugin to your DigitalOcean Space. You can begin offloading your WordPress Media Library assets.

The **Use files on the cloud server** checkbox allows you to specify where Media Library assets will be served from. If you check the box, assets will be served from DigitalOcean Spaces, and URLs to images and other Media Library objects will be correspondingly rewritten. If you plan on using the Spaces CDN to serve your Media Library assets, **do not** check this box, as the plugin will use the Spaces **Origin** endpoint and not the CDN **Edge** endpoint. We will configure CDN link rewriting in a future step.

Click the **Remove files from local server** box to delete local Media Library assets once they’ve been successfully uploaded to DigitalOcean Spaces.

The **Remove individual downloaded files from the cloud server** checkbox should be used when bulk downloading files from Spaces to your WordPress server. If checked, these files will be deleted from Spaces after successfully downloading to your WordPress server. We can ignore this option for now.

Since we’re configuring the plugin for use with the Spaces CDN, leave the **Use files on the cloud server** box unchecked, and hit **Copy Media Library to the cloud server** to sync your site’s WordPress Media Library to your DigitalOcean Space.

You should see a progress box appear, and then **Upload complete.** indicating the Media Library sync has concluded successfully.

Navigate to your DigitalOcean Space to confirm that your Media Library files have been copied to your Space. They should be available in the `uploads` subdirectory of the `wp-content` directory you created earlier in this step.

Once your files are available in your Space, you’re ready to move on to configuring the Spaces CDN.

### Installing CDN Enabler Plugin to Deliver Assets from Spaces CDN

To use the Spaces CDN to serve your now offloaded files, first [ensure that you’ve enabled the CDN](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#enabling-spaces-cdn) for your Space.

Once the CDN has been enabled for your Space, you can now install and configure the [CDN Enabler](https://wordpress.org/plugins/cdn-enabler/) WordPress plugin to rewrite links to your Media Library assets. The plugin will rewrite links to these assets so that they are served from the Spaces CDN endpoint.

To install CDN Enabler, you can either use the **Plugins** menu from the WordPress administration interface, or install the plugin directly from the command line. We’ll demonstrate the latter procedure here.

First, log in to your WordPress server. Then, navigate to your plugins directory:

    cd /var/www/html/wp-content/plugins

Be sure to replace the above path with the path to your WordPress installation.

From the command line, use the `wp-cli` interface to install the plugin:

    wp plugin install cdn-enabler

Now, activate the plugin:

    wp plugin activate cdn-enabler

You can also install and activate the CDN Enabler plugin using the [built-in plugin installer](https://codex.wordpress.org/Managing_Plugins#Installing_Plugins).

Back in the WordPress Admin Area, under **Settings** , you should see a new link to **CDN Enabler** settings. Click into **CDN Enabler**.

You should see the following settings screen:

![CDN Enabler Settings](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/cdn_enabler_settings.png)

Modify the displayed fields as follows:

- **CDN URL** : Enter the Spaces **Edge** endpoint, which you can find from the Spaces Dashboard. In this tutorial, this is `https://wordpress-offload.nyc3.cdn.digitaloceanspaces.com`. If you’re using a custom subdomain with Spaces CDN, enter that subdomain here. For example, `https://assets.example.com`.
- **Included Directories** : Enter `wp-content/uploads`. We’ll learn how to serve other `wp-content` directories in the [Offload Additional Assets](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#offload-additional-assets) section.
- **Exclusions** : Leave the default `.php`
- **Relative Path** : Leave the box checked
- **CDN HTTPS** : Enable it by checking the box
- Leave the remaining two fields blank

Then, hit **Save Changes** to save these settings and enable them for your WordPress site.

At this point you’ve successfully offloaded your WordPress site’s Media Library to DigitalOcean Spaces and are serving them to end users using the CDN.

In this step, we did _not_ offload the WordPress theme or other `wp-content` assets. To learn how to transfer these assets to Spaces and serve them using the Spaces CDN, skip to [Offload Additional Assets](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#offload-additional-assets-(optional)).

To verify and test that your Media Library uploads are being delivered from the Spaces CDN, skip to [Testing CDN Caching](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#testing-cdn-caching).

## Offloading Additional Assets (Optional)

In previous sections of this guide, we’ve learned how to offload our site’s WordPress Media Library to Spaces and serve these files using the Spaces CDN. In this section, we’ll cover offloading and serving additional WordPress assets like themes, JavaScript files, and fonts.

Most of these static assets live inside of the `wp-content` directory (which contains `wp-themes`). To offload and rewrite URLs for this directory, we’ll use [CDN Enabler](https://wordpress.org/plugins/cdn-enabler/), an open-source plugin developed by KeyCDN.

If you’re using the [WP Offload Media plugin](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#wordpress-offload-media-plugin), you can use the [Asset Pull addon](https://deliciousbrains.com/wp-offload-media/doc/assets-pull-addon/) to serve these files using a pull CDN. Installing and configuring this addon is beyond the scope of this guide. To learn more, consult the DeliciousBrains product [page](https://deliciousbrains.com/wp-offload-media/doc/assets-pull-addon/).

First, we’ll install CDN Enabler. We’ll then copy our WordPress themes over to Spaces, and finally configure CDN Enabler to deliver these using the Spaces CDN.

If you’ve already installed CDN Enabler in a previous step, skip to Step 2.

### Step 1 — Installing CDN Enabler

To install CDN Enabler, log in to your WordPress server. Then, navigate to your plugins directory:

    cd /var/www/html/wp-content/plugins

Be sure to replace the above path with the path to your WordPress installation.

From the command line, use the `wp-cli` interface to install the plugin:

    wp plugin install cdn-enabler

Now, activate the plugin:

    wp plugin activate cdn-enabler

You can also install and activate the CDN Enabler plugin using the [built-in plugin installer](https://codex.wordpress.org/Managing_Plugins#Installing_Plugins).

Back in the WordPress Admin Area, under **Settings** , you should see a new link to **CDN Enabler** settings. Click into **CDN Enabler**.

You should see the following settings screen:

![CDN Enabler Settings](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/cdn_enabler_settings.png)

At this point you’ve successfully installed CDN Enabler. We’ll now upload our WordPress themes to Spaces.

### Step 2 — Uploading Static WordPress Assets to Spaces

In this tutorial, to demonstrate a basic plugin configuration, we’re only going to serve `wp-content/themes`, the WordPress directory containing WordPress themes’ PHP, JavaScript, HTML, and image files. You can optionally extend this process to other WordPress directories, like `wp-includes`, and even the entire `wp-content` directory.

The theme used by the WordPress installation in this tutorial is `twentyseventeen`, the default theme for a fresh WordPress installation at the time of writing. You can repeat these steps for any other theme or WordPress content.

First, we’ll upload our theme to our DigitalOcean Space using `s3cmd`. If you haven’t yet configured `s3cmd`, consult the DigitalOcean [Spaces Product Documentation](https://www.digitalocean.com/docs/spaces/resources/s3cmd/).

Navigate to your WordPress installation’s `wp-content` directory:

    cd /var/www/html/wp-content

From here, upload the `themes` directory to your DigitalOcean Space using `s3cmd`. Note that at this point you can choose to upload only a single theme, but for simplicity and to offload as much content as possible from our server, we will upload all the themes in the `themes` directory to our Space.

We’ll use `find` to build a list of non-PHP (therefore cacheable) files, which we’ll then pipe to `s3cmd` to upload to Spaces. We’ll exclude CSS stylesheets as well in this first command as we need to set the `text/css` MIME type when uploading them.

    find themes/ -type f -not \( -name '*.php' -or -name '*.css' \) | xargs -I{} s3cmd put --acl-public {} s3://wordpress-offload/wp-content/{}

Be sure to replace `wordpress-offload` in the above command with your Space name.

Here, we instruct `find` to search for files within the `themes/` directory, and ignore `.php` and `.css` files. We then use `xargs -I{}` to iterate over this list, executing `s3cmd put` for each file, and set the file’s permissions in Spaces to `public` using `--acl-public`.

Next, we’ll do the same for CSS stylesheets, adding the `--mime-type="text/css"` flag to set the `text/css` MIME type for the stylesheets on Spaces. This will ensure that Spaces serves your theme’s CSS files using the correct `Content-Type: text/css` HTTP header:

    find themes/ -type f -name '*.css' | xargs -I{} s3cmd put --acl-public --mime-type="text/css" {} s3://wordpress-offload/wp-content/{}

Again, be sure to replace `wordpress-offload` in the above command with your Space name.

Now that we’ve uploaded our theme, let’s verify that it can be found at the correct path in our Space. Navigate to your Space using the [DigitalOcean Cloud Control Panel](https://cloud.digitalocean.com/spaces).

Enter the `wp-content` directory, followed by the `themes` directory. You should see your theme’s directory here. If you don’t, verify your `s3cmd` configuration and re-upload your theme to your Space.

### Step 3 — Configuring CDN Enabler to Rewrite Asset Links

Now that our theme lives in our Space, and we’ve set the correct metadata, we can begin serving its files using CDN Enabler and the DigitalOcean Spaces CDN.

Navigate back to the WordPress Admin Area and click into **Settings** and then **CDN Enabler**.

Here, modify the displayed fields as follows:

- **CDN URL** : Enter the Spaces **Edge** endpoint, as done in **Step 1**. In this tutorial, this is `https://wordpress-offload.nyc3.cdn.digitaloceanspaces.com`. If you’re using a custom subdomain with Spaces CDN, enter that subdomain here. For example, `https://assets.example.com`.
- **Included Directories** : If you’re **not** using the MLFP plugin, this should be `wp-content/themes`. If you are, this should be `wp-content/uploads,wp-content/themes`
- **Exclusions** : Leave the default `.php`
- **Relative Path** : Leave the box checked
- **CDN HTTPS** : Enable it by checking the box
- Leave the remaining two fields blank

Your final settings should look something like this:

![CDN Enabler Final Settings](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/cdn_enabler_final.png)

Hit **Save Changes** to save these settings and enable them for your WordPress site.

At this point you’ve successfully offloaded your WordPress site’s theme assets to DigitalOcean Spaces and are serving them to end users using the CDN. We can confirm this using Chrome’s DevTools, following the procedure described [below](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#test-cdn-caching).

Using the CDN Enabler plugin, you can repeat this process for other WordPress directories, like `wp-includes`, and even the entire `wp-content` directory.

## Testing CDN Caching

In this section, we’ll demonstrate how to determine where your WordPress assets are being served from (e.g. your host server or the CDN) using Google Chrome’s DevTools.

### Step 1 — Adding Sample Image to Media Library to Test Syncing

To begin, we’ll first upload a sample image to our Media Library, and verify that it’s being served from the DigitalOcean Spaces CDN servers. You can upload an image using the WordPress Admin web interface, or using the `wp-cli` command-line tool. In this guide, we’ll use `wp-cli` to upload the sample image.

Log in to your WordPress server using the command line, and navigate to the home directory for the non-root user you’ve configured. In this tutorial, we’ll use the user **sammy**.

    cd

From here, use `curl` to download the DigitalOcean logo to your Droplet (if you already have an image you’d like to test with, skip this step):

    curl https://assets.digitalocean.com/logos/DO_Logo_horizontal_blue.png > do_logo.png

Now, use `wp-cli` to import the image to your Media Library:

    wp media import --path=/var/www/html/ /home/sammy/do_logo.png

Be sure to replace `/var/www/html` with the correct path to the directory containing your WordPress files.

You may see some warnings, but the output should end in the following:

    OutputImported file '/home/sammy/do_logo.png' as attachment ID 10.
    Success: Imported 1 of 1 items.

Which indicates that our test image has successfully been copied to the WordPress Media Library, and also uploaded to our DigitalOcean Space, using your preferred offload plugin.

Navigate to your DigitalOcean Space to confirm:

![Spaces Upload Success](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/spaces_upload_confirm.png)

This indicates that your offload plugin is functioning as expected and automatically syncing WordPress uploads to your DigitalOcean Space. Note that the exact path to your Media Library uploads in the Space will depend on the plugin you’re using to offload your WordPress files.

Next, we will verify that this file is being served using the Spaces CDN, and not from the server running WordPress.

### Step 2 — Inspecting Asset URL

From the WordPress admin area (`https://your_domain/wp-admin`), navigate to **Pages** in the left-hand side navigation menu.

We will create a sample page containing our uploaded image to determine where it’s being served from. You can also run this test by adding the image to an existing page on your WordPress site.

From the **Pages** screen, click into **Sample Page** , or any existing page. You can alternatively create a new page.

In the page editor, click on **Add Media** , and select the DigitalOcean logo (or other image you used to test this procedure).

An **Attachment Details** pane should appear on the right-hand side of your screen. From this pane, add the image to the page by clicking on **Insert into page**.

Now, back in the page editor, click on either **Publish** (if you created a new sample page) or **Update** (if you added the image to an existing page) in the **Publish** box on the right-hand side of your screen.

Now that the page has successfully been updated to contain the image, navigate to it by clicking on the **Permalink** under the page title. You’ll be brought to this page in your web browser.

For the purposes of this tutorial, the following steps will assume that you’re using Google Chrome, but you can use most modern web browsers to run a similar test.

From the rendered page preview in your browser, right click on the image and click on **Inspect** :

![Inspect Menu](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/inspect.png)

A DevTools window should pop up, highlighting the `img` asset in the page’s HTML:

![DevTools Output](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/devtools_output.png)

You should see the CDN endpoint for your DigitalOcean Space in this URL (in this tutorial, our Spaces CDN endpoint is `https://wordpress-offload.nyc3.cdn.digitaloceanspaces.com`), indicating that the image asset is being served from the DigitalOcean Spaces CDN edge cache. If you’re using a custom subdomain with Spaces CDN, the asset URL should be using this custom subdomain.

This confirms that your Media Library uploads are being synced to your DigitalOcean Space and served using the Spaces CDN.

### Step 3 — Inspecting Asset Response Headers

From the DevTools window, we’ll run one final test. Click on **Network** in the toolbar at the top of the window.

Once in the blank **Network** window, follow the displayed instructions to reload the page.

The page assets should populate in the window. Locate your test image in the list of page assets:

![Chrome DevTools Asset List](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/devtools_asset_list.png)

Once you’ve located your test image, click into it to open an additional information pane. Within this pane, click on **Headers** to show the response headers for this asset:

![Response Headers](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/response_headers.png)

You should see the `Cache-Control` HTTP header, which is a CDN response header. This confirms that this image was served from the Spaces CDN.

### Step 4 — Inspecting URLs for Theme Assets (Optional)

If you offloaded your `wp-themes` (or other) directory as described in [Offload Additional Assets](how-to-speed-up-wordpress-asset-delivery-using-digitalocean-spaces-cdn#offload-additional-assets), you should perform the following brief check to verify that your theme’s assets are being served from the Spaces CDN.

Navigate to your WordPress site in Google Chrome, and right-click anywhere in the page. In the menu that appears, click on **Inspect**.

You’ll once again be brought to the Chrome DevTools interface.

![Chrome DevTools Interface](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/chrome_devtools_theme_confirm.png)

From here, click into **Sources**.

In the left-hand pane, you should see a list of your WordPress site’s assets. Scroll down to your CDN endpoint (or custom subdomain), and expand the list by clicking the small arrow next to the endpoint name:

![DevTools Site Asset List](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/wordpress_cdn_offload/devtools_sources_assets.png)

Observe that your WordPress theme’s header image, JavaScript, and CSS stylesheet are now being served from the Spaces CDN.

## Conclusion

In this tutorial, we’ve shown how to offload static content from your WordPress server to DigitalOcean Spaces, and serve this content using the Spaces CDN. In most cases, this should reduce bandwidth on your host infrastructure and speed up page loads for end users, especially those located further away geographically from your WordPress server.

We demonstrated how to offload and serve both Media Library and `themes` assets using the Spaces CDN, but these steps can be extended to further unload the entire `wp-content` directory, as well as `wp-includes`.

Implementing a CDN to deliver static assets is just one way to optimize your WordPress installation. Other plugins like [W3 Total Cache](https://en-ca.wordpress.org/plugins/w3-total-cache/) can further speed up page loads and improve the SEO of your site. A helpful tool to measure your page load speed and improve it is Google’s [PageSpeed Insights](https://developers.google.com/speed/pagespeed/insights/). Another helpful tool that provides a waterfall breakdown of request and response times as well as suggested optimizations is [Pingdom](https://www.pingdom.com/).

To learn more about Content Delivery Networks and how they work, consult [Using a CDN to Speed Up Static Content Delivery](using-a-cdn-to-speed-up-static-content-delivery).
