---
author: Hazel Virdó, Brian Hogan
date: 2016-07-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/digitalocean-s-technical-writing-guidelines
---

# DigitalOcean's Technical Writing Guidelines

DigitalOcean is excited to continue building out its collection of technical articles related to server administration and software engineering. To ensure that DigitalOcean articles have consistent quality and style, we have developed the following guidelines.

There are three sections in this guide:

- **[Style](digitalocean-s-writing-guidelines#style)**, our high-level approach to writing technical tutorials
- **[Structure](digitalocean-s-writing-guidelines#structure)**, an explanation of our layout and content
- **[Formatting](digitalocean-s-writing-guidelines#formatting) and [Terminology](https://digitalocean.com/community/tutorials/digitalocean-s-writing-guidelines#terminology)**, a Markdown and terminology reference

To get published quickly, DigitalOcean community authors should read the style and structure sections in their entirety. Our [templates](https://github.com/do-community/do-article-templates) are useful as a starting point for an article, and the formatting section of this guide along with our [Markdown previewer](https://www.digitalocean.com/community/markdown) can be used as references while writing. We also have a [technical best practices guide](technical-recommendations-and-best-practices-for-digitalocean-s-tutorials) for our tech-focused recommendations.

* * *

## Style

DigitalOcean articles should be:

- **Comprehensive and written for all experience levels**

Our articles are written to be as clear and detailed as possible without making assumptions about the reader’s background knowledge.

We explicitly include every command a reader needs to go from their first SSH connection on a brand new server to the final, working setup. We also provide readers with all of the explanations and background information they need to understand the tutorial. The goal is for our readers to learn, not just copy and paste.

- **Technically detailed and correct**

All of our tutorials are tested on new servers to ensure they work from scratch. Every command should have a detailed explanation, including options and flags as necessary. When you ask the reader to execute a command or modify a configuration file, first explain what it does or why they’re making those changes.

- **Practical, useful, and self-contained**

Once a reader has finished a DigitalOcean article, they should have installed or set up something from start to finish. We emphasize a practical approach: at the end of an article, we should leave the reader with a usable environment or an example to build upon.

What this means for the writer is that their article should cover their topic thoroughly and, where necessary, should link to another DigitalOcean article to set up prerequisites. Authors shouldn’t send readers offsite to gather information that could easily be added to the article.

- **Friendly but formal**

Our tutorials aim for a friendly but formal tone. This means that articles do not include jargon, memes, or excessive jokes. This also means that, unlike blog posts, we do not use the first person singular (e.g. “I think …”). Instead, we use the first person plural (e.g. “We will install …) or second person (e.g. "You will configure …”).

* * *

## Structure

DigitalOcean tutorials have a consistent structure comprised of the following sections:

- Title
- Introduction
- Goals (Optional)
- Prerequisites
- Step 1 — Doing the First Thing
- Step 2 — Doing the Next Thing
- …
- Step n — Doing the Last Thing
- Conclusion

Our [article templates](https://github.com/do-community/do-article-templates) have this layout in Markdown, which you can use as a starting point for your own articles. The [Formatting section of this guide](http://do.co/style#formatting) has more detail about our formatting conventions.

### Title

A typical title follows this format: **How To \<Accomplish a Task\> with \<Software\> on \<Distro\>**.

When you write your title, think carefully about what the reader will accomplish by following your tutorial. Try to include the goal of the tutorial in the title, not just the tool(s) the reader will use to accomplish that goal.

For example, if your tutorial is about installing Caddy, the goal is likely to [host a website](how-to-host-a-website-with-caddy-on-ubuntu-16-04). If your tutorial is about installing FreeIPA, the goal might be to [set up centralized Linux authentication](how-to-set-up-centralized-linux-authentication-with-freeipa-on-centos-7). Titles that include the goal (like “[How To Create a Status Page with Cachet on Debian 8](how-to-create-a-status-page-with-cachet-on-debian-8)”) are generally more informative for the reader than titles that don’t (like “How To Install and Set Up Cachet on Debian 8”).

## Introduction and Goals

The first section of every tutorial is the **Introduction** , which is usually 1 to 3 paragraphs long.  
The purpose of the introduction is to answer the following questions for the reader:

- What is the goal of the tutorial? What will the reader accomplish if they follow it?
- What software is involved, and what does each component do (briefly)?
- What are the benefits of using this particular software in this configuration? What are some practical reasons why the reader should follow this tutorial?

Some tutorials use the optional **Goals** section to separate the tutorial’s context, background explanation, and motivation from the details of the final configuration. You should only use this section if your tutorial requires multiple servers, has a large software stack, or otherwise has a particularly complicated purpose, method, or result.

Some good examples include [this Prometheus tutorial’s introduction](how-to-install-prometheus-on-ubuntu-16-04#introduction) and [this Pydio tutorial’s goals](how-to-host-a-file-sharing-server-with-pydio-on-ubuntu-14-04#goals).

### Prerequisites

The **Prerequisites** sections of DigitalOcean tutorials have a very specific format and purpose.

The purpose is to spell out _exactly_ what the reader should have or do before they follow the current tutorial. The format is a bulleted list that the reader can use as a checklist. Each bullet point must link to an existing DigitalOcean tutorial that covers the necessary content. This allows you to rely on existing content known to work instead of starting from scratch.

Common prerequisite bullet points include:

- The number of servers necessary, including distribution, initial server setup, and any additional necessary options (like memory requirements, DO API keys, IPv6, or private networking).

- Software installation and configuration.

- Required DNS settings or SSL certificates.

- Additional user accounts like GitHub, Facebook, Twitter, or other services your reader will need.

When you test your tutorial, make sure you follow all of the prerequisite tutorials exactly as written, so that everyone uses the same starting point. If you changed a variable or completed an optional step from one of the prerequisites, make sure to note that.

Our system administration tutorials take the reader from a fresh deployment of a vanilla distribution image to a working setup, so they should start with the first SSH connection to the server or include a prerequisite tutorial that does.

You can see good prerequisites examples for:

- Ubuntu 16.04 servers, software installation, and DNS records in [this Minio tutorial’s prerequisites](how-to-set-up-an-object-storage-server-using-minio-on-ubuntu-16-04#prerequisites).

- CentOS 7 servers and DNS records in [this FreeIPA tutorial’s prerequisites](how-to-set-up-centralized-linux-authentication-with-freeipa-on-centos-7#prerequisites).

- Debian 8 servers with memory requirements and software setup using partial steps from other tutorials in [this Cachet tutorial’s prerequisites](how-to-create-a-status-page-with-cachet-on-debian-8#prerequisites).

- Handling multiple servers with software installation in [this Nagios and Alerta tutorial’s prerequisites](how-to-monitor-nagios-alerts-with-alerta-on-centos-7#prerequisites).

### Steps

The **Step** sections are the parts of your tutorial where you describe what the reader needs to do.

Begin each step with an introductory sentence that describes what the step covers and what role it plays in achieving the overall goal of the tutorial. End each step with a transition sentence that describes what the reader accomplished and where they are going next. Avoid repeating the step title in these introductions and transitions, and don’t start or end steps with contextless instructions, commands, or output.

All commands in a step should be on their own line in their own code block, and each command should be preceded by a description. Similarly, always introduce a file or script by describing its general purpose, then explain any changes that the reader will be making in the file. Without these explanations, readers won’t be able to customize, update, or troubleshoot their server in the long run.

DigitalOcean’s [custom Markdown and formatting guidelines](http://do.co/style#formatting) are designed to help make our tutorials’ instructions as easy to read as possible. [This Docker Swarm tutorial](how-to-create-a-cluster-of-docker-containers-with-docker-swarm-and-digitalocean-on-ubuntu-16-04) is a good example of how to use our custom Markdown to distinguish between commands run on several different servers, as well as locally.

### Conclusion

The **Conclusion** should summarize what the reader has accomplished by following your tutorial. It should also describe what the reader can do next. This can include a description of use cases or features the reader can explore, links to other DigitalOcean tutorials with additional setup or configuration, and external documentation.

Some good examples include [this LXD tutorial’s conclusion](how-to-set-up-and-use-lxd-on-ubuntu-16-04#conclusion),[this CPU monitoring tutorial’s conclusion](how-to-monitor-cpu-use-on-digitalocean-droplets#conclusion), and [this Mosquitto tutorial’s conclusion](how-to-install-and-secure-the-mosquitto-mqtt-messaging-broker-on-ubuntu-16-04#conclusion).

* * *

## Formatting

DigitalOcean tutorials are formatted in the Markdown markup language. [Daring Fireball](http://daringfireball.net/projects/markdown/syntax) publishes a comprehensive Markdown guide if you’re unfamiliar with it. DigitalOcean also uses some [custom Markdown](https://www.digitalocean.com/community/markdown). Examples of our custom Markdown are in the appropriate sections below.

### Headers

Each section of our tutorials has a corresponding header: the title should be an H1 header; the introduction should be an H3 header; the goals, prerequisites, steps, and conclusion should have H2 headers. You can see this format in our [Markdown article templates](https://github.com/do-community/do-article-templates).

For procedural tutorials, step headers should include step numbers (numerical) followed by an em dash ( **—** ). Step headers should also use the gerund, which are **-ing** words. An example step header is **Step 1 — Installing Nginx**.

Use H3 headers sparingly, and avoid H4 headers. If you need to use subheaders, make sure there are two or more headers of that level within that section of the tutorial. Alternatively, consider making multiple steps instead.

### Line-level Formatting

**Bold text** should be used for:

- Visible GUI text
- Hostnames and usernames, like **wordpress-1** or **sammy**
- Term lists
- Emphasis when changing context for a command, like switching to a new server or user

_Italics_ should only be used when introducing technical terms. For example, the Nginx server will be our _load balancer_.

In-line code formatting should be used for:

- Command names, like `unzip`
- Package names, like `mysql-server`
- Optional commands
- File names and paths, like `~/.ssh/authorized_keys`
- Example URLs, like `http://your_domain`
- Ports, like `:3000`
- Key presses, which should be in ALL CAPS and use a plus symbol, **+** , if keys need to be pressed simultaneously, like `ENTER` or `CTRL+C`

### Code Blocks

Code blocks should be used for:

- Commands the reader needs to execute to complete the tutorial
- Files and scripts
- Terminal output
- Interactive dialogues that are in text

Excerpts and omissions in files can be indicated with ellipses ( **…** ). If most of a file can be left with the default settings, it’s usually better to show just the section that needs to be changed.

#### Code Block Prefixes

Do not include the command prompt in the code block. Instead, use DigitalOcean’s custom Markdown for non-root user commands, root user commands, and custom prefixes, respectively:

    ```command
    sudo apt-get update
    ```
    
    ```super_user
    adduser sammy
    ```
    
    ```custom_prefix(mysql>)
    FLUSH PRIVILEGES;
    ```

This is how the preceding examples look when rendered:

> sudo apt-get update
> 
> adduser sammy
> 
> FLUSH PRIVILEGES;

#### Code Block Labels

DigitalOcean’s Markdown also includes labels and secondary labels. You can add labels to code blocks by adding a line with `[label Label text]` or `[secondary_label Secondary label text]` anywhere in the block.

Use labels to mark code blocks containing the contents of a file with a filename. Use secondary labels to mark terminal output.

Labels look like this when rendered:

This is the label text

    This is one line of the file
    This is another line of the file
    . . .
    This is a line further down the file

Secondary label example:

    This is the secondary label textThis is some output from a command

#### Code Block Environment Colors

DigitalOcean’s Markdown allows you to color the background of a code block by adding a line with `[environment name]` anywhere in the block. The options for `name` are `local`, `second`, `third`, `fourth`, and `fifth`.

This is a local server command example:

    ssh root@your_server_ip

These are non-primary server command examples, useful for multi-server setups:

    echo "Secondary server"

    echo "Third server"

    echo "Fourth server"

    echo "Fifth server

### Notes and Warnings

The DigitalOcean Markdown parser allows for custom **note** and **warning** code blocks to be used to display very important text.

Here’s a Markdown example of a note and a warning (this is an image):

![Notes and Warnings](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/do_formatting/note_warning.png)

Here’s the rendered result:

**Note:** This is a note.

**Warning:** This is a warning.

### Variables

Highlight any items that need to be changed by the reader, like example URLs or modified lines in configuration files. You can do this by surrounding the word or line with our custom **\<^\>** Markdown. Note that you cannot highlight multiple lines with one pair of symbols, so you need to highlight each line individually.

If you reference a variable in a context where you would normally also use `in-line code` formatting, you should use `both styles`. Make sure your tutorial is as accessible as possible by using language like “highlighted in the preceding code block” instead of “highlighted in red above”.

Avoid language like “highlighted in red below”

### Images and Other Assets

Images can quickly illustrate a point or provide additional clarification in a step. Use images for screenshots of GUIs, interactive dialogue, and diagrams of server setups. Don’t use images for screenshots of code, configuration files, output, or anything that can be copied and pasted into the article.

If you’re including images in your tutorial, please follow these guidelines:

- Include descriptive alt text so readers using a screen reader can rely on the alt text rather than the image.
- Use the `.png` file format
- Host images on [imgur](http://imgur.com/)
- Make the image with as short a height as possible

If you make a mockup of a diagram for your tutorial, we will create a diagram in the DigitalOcean style. We’ll also upload all images to DigitalOcean servers at publication time.

Here’s a Markdown example for including images in your tutorial:

    ![Alt text for screen readers](http://imgur.com/your_image_url)

Occasionally, you will want the reader to have access to a configuration file that is too long to display in the main body of the tutorial. DigitalOcean will host this file on our assets server. You can use standard link formatting to link to the file.

## Terminology

### Users, Hostnames, and Domains

Our default example username is **sammy**. You can also choose something descriptive where helpful, like **webdav-kai** or **nsd**.

**your\_server** is the default hostname, though you are encouraged to choose something descriptive, especially in multi-server setups, like **django\_replica\_1**.

**your\_domain** is the default domain. For multi-server setups, you can choose something like **primary-1.your\_domain** or **replica-1.your\_domain**. While **example.com** is a valid domain for documentation, using **your\_domain** in tutorials makes it more clear that the reader should change the domain in examples.

Use highlighting when using these in configuration files, like this:

example configuration file

    ip: your_server_ip
    domain: primary-1.your_domain

This makes it clear to readers that there’s something they should change.

### IP Addresses and URLs

`your_server_ip`, with in-line code formatting and variable highlighting, is the default way to show an IP address. You can show multiple IP addresses with names like `primary_private_ip` and `replica_private_ip`. If you need to illustrate more realistic IP addresses, use an address in the [one of the two blocks reserved for documentation as per RFC-5737](https://tools.ietf.org/html/rfc5737). Specifically, we recommend `203.0.113.0/24` for example public addresses and `198.51.100.0/24` for example private addresses.

Example URLs that contain a variable the reader needs to customize should use code formatting with the variable highlighted. We default to using `your_domain`. like `https://your_domain:3000/simple/` or `http://your_server_ip/`. However, live links should instead use the standard Markdown link style with no extra formatting.

### Software

Use the official website’s capitalization of the name of their software. If the product website is not consistent with their capitalization, just be consistent within a single article.

Link to the software’s home page when you first mention the software.

### Multi-server Setups

For technical clarity, use the project’s terminology for multi-server setups. Please be clear that the terms are coming from the project. For example: “The Django project refers to the original server as the **primary** and the secondary server as the **replica**. The MySQL project refers to the original server as the **master** and the secondary server as the **slave**.”

When discussing multi-server architectures more abstractly, use the terms **primary** and **replica** or **manager** and **worker**.

### Technical Best Practices

Our [technical best practices guide](technical-recommendations-and-best-practices-for-digitalocean-s-tutorials) guide contains more guidance that will help you create consistent, quality tutorials that help our readers.

Follow this link to [become a DigitalOcean author](https://www.digitalocean.com/community/write-for-digitalocean).
