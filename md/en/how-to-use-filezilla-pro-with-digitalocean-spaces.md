---
author: Josue Andrade Gomes
date: 2018-06-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-filezilla-pro-with-digitalocean-spaces
---

# How To Use FileZilla Pro with DigitalOcean Spaces

## Introduction

[FileZilla Pro](https://filezillapro.com/) is a file transfer solution that works with FTP, SFTP, FTPS, and WebDAV protocols. In 2001, the original FileZilla project brought an open-source, cross-platform file access and transfer application to users. Today, FileZilla Pro offers support for a growing number of network and cloud protocols.

[DigitalOcean Spaces](how-to-create-and-manage-your-first-digitalocean-space) is an object storage solution that allows users to store and serve large amounts of data. Because its API is interoperable with the AWS S3 API, you can use FileZilla Pro to transfer files to and access files from your DigitalOcean Space.

In this tutorial, we’ll walk you through configuring FileZilla Pro to connect to a DigitalOcean Spaces repository.

## Prerequisites

In order to complete this tutorial, you should have access to the following:

- FileZilla Pro downloaded and installed on your local machine. You can purchase FileZilla Pro for Windows or MacOs from [filezillapro.com](https://filezillapro.com/).
- A DigitalOcean Space and API key, created by following [How To Create a DigitalOcean Space and API Key](how-to-create-a-digitalocean-space-and-api-key). Be sure to note the following credentials for your Space: 
  - Access Key
  - Secret Key
  - Space URL
  - Bucket Name 

With these prerequisites in place, we can begin setting up FileZilla Pro to work with DigitalOcean Spaces.

## Step 1 — Configuring Spaces Endpoints

To connect to your DigitalOcean Spaces repository with FileZilla Pro, you will need to configure the FileZilla providers list with DigitalOcean endpoints. Open FileZilla Pro and follow these steps:

- Choose **Edit** from the menu at the top of the screen, and select **Settings**. You will see a dialog box, where you should see a **Transfers** heading. Select **S3: Providers** under that heading. 
- In the **S3: Providers** page, you will see a box for **Providers** , with an **Add** button below it. Click this button to add **DigitalOcean** to the list of providers:

![Add DigitalOcean to providers list](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/filezilla_pro_spaces/pro_digital_ocean_1_updated.png)

- Below the **Providers** box, you will see a **Regions** box and another **Add** button. Click on it and add the following regions and endpoints: 

| Name | Description | Endpoints |
| --- | --- | --- |
| nyc3 | New York 3 | nyc3.digitaloceanspaces.com |
| sgp1 | Singapore 1 | sgp1.digitaloceanspaces.com |
| ams3 | Amsterdam 3 | ams3.digitaloceanspaces.com |

You can add other regions later. The completed **Regions** list will look like this:

![DigitalOcean Endpoints](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/filezilla_pro_spaces/pro_digital_ocean_2_updated.png)

- Below the **Regions** box, you will see a **Catch All** box. Enter **`.digitaloceanspaces.com`** into this box. Be sure to include the leading dot before the text.
- In the **Format** box enter: **`{region}.digitaloceanspaces.com`**. Your **Settings** page should now look like this:

![Complete Settings Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/filezilla_pro_spaces/pro_digital_ocean_3_updated.png)

- Press the **OK** button located on the left-hand side of the screen to finish.

From here, we’ll connect our Spaces buckets to FileZilla.

## Step 2 — Adding a DigitalOcean Spaces Repository

Now we can add our Spaces bucket information — including our repository URL and Access and Secret Keys — to FileZilla in order to connect to each of our Spaces.

- Select **File** from the top menu, and choose **Site Manager**.
- In the **Site Manager** dialog box, click the **New Site** button, located on the bottom left-hand side of the screen.
- Enter the name of the new site. It may make sense to call this **`DigitalOcean`**.
- In the **Host** text box, located to the right of the site list, enter your Space URL. This could look something like the following: **`sammys-bucket.nyc3.digitaloceanspaces.com`** , with **`sammys-bucket`** being your Space Bucket Name, and **`nyc3.digitaloceanspaces.com`** being your endpoint.
- Using the **Protocol** dropdown menu located below the **Host** box, select **S3 - Amazon Simple Storage Service**.
- In the **Logon Type** box, select **Normal** from the dropdown menu. 
- In the **Access Key ID** box, enter your _Access Key_.
- In the **Secret Access Key** box, enter your _Secret Key_.

With these information fields complete, your **Site Manager** page should now look like this:

![Complete Site Manager Page](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/filezilla_pro_spaces/pro_digital_ocean_4_updated.png)

When you have finished and ensured that everything appears to be correctly filled in, press the **OK** button at the bottom of the screen to complete the setup.

## Step 3 — Connecting to Your Spaces Repository

With the setup complete, you can now connect to DigitalOcean Spaces with FileZilla Pro.

- Navigate to the **File** header again, and select **Site Manager**. Within the **Sites** dialog box, select your DigitalOcean Spaces site. 
- Press **Connect**.

You have now successfully integrated DigitalOcean Spaces with FileZilla Pro and can now transfer files to your Spaces bucket.

## Conclusion

With FileZilla Pro, you can transfer files seamlessly between your local machine and remote servers, managing all of your transfers without needing to worry about how many files are in your source directory. Optimized for speed, FileZilla Pro allows you to adjust the pace of your transfers to best suit your needs, providing you with considerable flexibility.

To learn more about how to use FileZilla, you can read the [FileZilla Client Tutorial](https://wiki.filezilla-project.org/FileZilla_Client_Tutorial_(en)).
