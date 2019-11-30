---
author: Abdullatif Eymash
date: 2018-04-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-create-and-serve-webp-images-to-speed-up-your-website
---

# How To Create and Serve WebP Images to Speed Up Your Website

_The author selected the [Apache Software Foundation](https://www.brightfunds.org/organizations/apache-software-foundation) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[WebP](https://developers.google.com/speed/webp) is an open image format developed by Google in 2010 based on the VP8 video format. Since then, the number of websites and mobile applications using the WebP format has grown at a fast pace. Both Google Chrome and Opera support the WebP format natively, and since these browsers account for about 74% of web traffic, users can access websites faster if these sites use WebP images. There are also [plans for implementing WebP in Firefox](https://bugzilla.mozilla.org/show_bug.cgi?id=1294490).

The WebP format supports both lossy and lossless image compression, including animation. Its main advantage over other image formats used on the web is its much smaller file size, which makes web pages load faster and reduces bandwidth usage. Using WebP images can lead to [sizeable increases](https://blog.chromium.org/2014/03/webp-improves-while-rolling-out-across.html) in page speed. If your application or website is experiencing performance issues or increased traffic, converting your images may help optimize page performance.

In this tutorial, you will use the command-line tool `cwebp` to convert images to WebP format, creating scripts that will watch and convert images in a specific directory. Finally, you’ll explore two ways to serve WebP images to your visitors.

## Prerequisites

Working with WebP images does not require a particular distribution, but we will demonstrate how to work with relevant software on Ubuntu 16.04 and CentOS 7. To follow this tutorial you will need:

- A server set up with a non-root sudo user. To set up an Ubuntu 16.04 server, you can follow our [Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04). If you would like to use CentOS, you can set up a CentOS 7 server with our [Initial Server Setup with CentOS 7 tutorial](initial-server-setup-with-centos-7). 

- Apache installed on your server. If you are using Ubuntu, you can follow step one of [How To Install Linux, Apache, MySQL, PHP (LAMP) stack on Ubuntu 16.04](how-to-install-linux-apache-mysql-php-lamp-stack-on-ubuntu-16-04). If you are using CentOS, then you should follow step one of [How To Install Linux, Apache, MySQL, PHP (LAMP) stack On CentOS 7](how-to-install-linux-apache-mysql-php-lamp-stack-on-centos-7). Be sure to adjust your firewall settings to allow HTTP and HTTPS traffic.

- `mod_rewrite` installed on your server. If you are using Ubuntu, you can follow our guide on [How To Rewrite URLs with mod\_rewrite for Apache on Ubuntu 16.04](how-to-rewrite-urls-with-mod_rewrite-for-apache-on-ubuntu-16-04). On CentOS 7 `mod_rewrite` is installed and activated by default.

## Step 1 — Installing cwebp and Preparing the Images Directory

In this section, we will install software to convert images and create a directory with images as a testing measure.

On Ubuntu 16.04, you can install `cwebp`, a utility that compresses images to the `.webp` format, by typing:

    sudo apt-get update
    sudo apt-get install webp 

On CentOS 7, type:

    sudo yum install libwebp-tools

To create a new images directory called `webp` in the Apache web root (located by default at `/var/www/html`) type:

    sudo mkdir /var/www/html/webp

Change the ownership of this directory to your non-root user **sammy** :

    sudo chown sammy: /var/www/html/webp

To test commands, you can download free JPEG and PNG images using `wget`. This tool is installed by default on Ubuntu 16.04; if you are using CentOS 7, you can install it by typing:

    sudo yum install wget

Next, download the test images using the following commands:

    wget -c "https://upload.wikimedia.org/wikipedia/commons/2/24/Junonia_orithya-Thekkady-2016-12-03-001.jpg?download" -O /var/www/html/webp/image1.jpg
    wget -c "https://upload.wikimedia.org/wikipedia/commons/5/54/Mycalesis_junonia-Thekkady.jpg" -O /var/www/html/webp/image2.jpg
    wget -c "https://cdn.pixabay.com/photo/2017/07/18/15/39/dental-care-2516133_640.png" -O /var/www/html/webp/logo.png

**Note** : These images are available for use and redistribution under the Creative Commons [Attribution-ShareAlike license](https://creativecommons.org/licenses/by-sa/4.0/deed.en) and the [Public Domain Dedication](https://creativecommons.org/publicdomain/zero/1.0/).

Most of your work in the next step will be in the `/var/www/html/webp` directory, which you can move to by typing:

    cd /var/www/html/webp

With the test images in place, and the Apache web server, `mod_rewrite`, and `cwebp` installed, you are ready to move on to converting images.

## Step 2 — Compressing Image Files with cwebp

Serving `.webp` images to site visitors requires `.webp` versions of image files. In this step, you will convert JPEG and PNG images to the `.webp` format using `cwebp`. The **general** syntax of the command looks like this:

    cwebp image.jpg -o image.webp

The `-o` option specifies the path to the WebP file.

Since you are still in the `/var/www/html/webp` directory, you can run the following command to convert `image1.jpg` to `image1.webp` and `image2.jpg` to `image2.webp`:

    cwebp -q 100 image1.jpg -o image1.webp
    cwebp -q 100 image2.jpg -o image2.webp

Setting the quality factor `-q` to 100 retains 100% of the image quality; if not specified, the default value is 75.

Next, inspect the size of the JPEG and WebP images using the `ls` command. The `-l` option will show the long listing format, which includes the size of the file, and the `-h` option will make sure that `ls` prints human readable sizes:

    ls -lh image1.jpg image1.webp image2.jpg image2.webp

    Output-rw-r--r-- 1 sammy sammy 7.4M Oct 28 23:36 image1.jpg
    -rw-r--r-- 1 sammy sammy 3.9M Feb 18 16:46 image1.webp
    -rw-r--r-- 1 sammy sammy 16M Dec 18 2016 image2.jpg
    -rw-r--r-- 1 sammy sammy 7.0M Feb 18 16:59 image2.webp

The output of the `ls` command shows that the size of `image1.jpg` is 7.4M, while the size of `image1.webp` is 3.9M. The same goes for `image2.jpg` (16M) and `image2.webp` (7M). These files are almost half of their original size!

To save the complete, original data of images during compression, you can use the `-lossless` option in place of `-q`. This is the best option to maintain the quality of PNG images. To convert the downloaded PNG image from step 1, type:

    cwebp -lossless logo.png -o logo.webp

The following command shows that the lossless WebP image size (60K) is approximately half the size of the original PNG image (116K):

    ls -lh logo.png logo.webp

    Output-rw-r--r-- 1 sammy sammy 116K Jul 18 2017 logo.png
    -rw-r--r-- 1 sammy sammy 60K Feb 18 16:42 logo.webp

The converted WebP images in the `/var/www/html/webp` directory are about 50% smaller than their JPEG and PNG counterparts. In practice, compression rates can differ depending on certain factors: the compression rate of the original image, the file format, the type of conversion (lossy or lossless), the quality percentage, and your operating system. As you convert more images, you may see variations in conversion rates related to these factors.

## Step 3 — Converting JPEG and PNG Images in a Directory

Writing a script will simplify the conversion process by eliminating the work of manual conversion. We will now write a conversion script that finds JPEG files and converts them to WebP format with 90% quality, while also converting PNG files to lossless WebP images.

Using `nano` or your favorite editor, create the `webp-convert.sh` script in your user’s home directory:

    nano ~/webp-convert.sh

The first line of the script will look like this:

~/webp-convert.sh

    find $1 -type f -and \( -iname "*.jpg" -o -iname "*.jpeg" \)

This line has the following components:

- [`find`](how-to-use-find-and-locate-to-search-for-files-on-a-linux-vps): This command will search for files within a specified directory.
- `$1`: This positional parameter specifies the path of the images directory, taken from the command line. Ultimately, it makes the location of the directory less dependent on the location of the script. 
- `-type f`: This option tells `find` to look for regular files only.
- `-iname`: This test matches filenames against a specified pattern. The case-insensitive `-iname` test tells `find` to look for any filename that ends with `.jpg` (`*.jpg`) or `.jpeg` (`*.jpeg`).
- `-o`: This logical operator instructs the `find` command to list files that match the first `-iname` test (`-iname "*.jpg"`) **or** the second (`-iname "*.jpeg"`).
- `()`: Parentheses around these tests, along with the `-and` operator, ensure that the first test (i.e. `-type f`) is always executed.

The second line of the script will convert the images to WebP using the `-exec` parameter. The general syntax of this parameter is `-exec command {} \;`. The string `{}` is replaced by each file that the command iterates through, while the `;` tells `find` where the command ends:

~/webp-convert.sh

    find $1 -type f -and \( -iname "*.jpg" -o -iname "*.jpeg" \) \
    -exec bash -c 'commands' {} \;

In this case, the `-exec` parameter will require more than one command to search for and convert images:

- `bash`: This command will execute a small script that will make the `.webp` version of the file if it doesn’t exist. This script will get passed to `bash` as a string thanks to the `-c` option. 
- `'commands'`: This placeholder is the script that will make `.webp` versions of your files. 

The script inside `'commands'` will do the following things:

- Create a `webp_path` variable.
- Test whether or not the `.webp` version of the file exists.
- Make the file if it does not exist. 

The smaller script looks like this:

~/webp-convert.sh

    ...
    webp_path=$(sed 's/\.[^.]*$/.webp/' <<< "$0");
    if [! -f "$webp_path"]; then 
      cwebp -quiet -q 90 "$0" -o "$webp_path";
    fi;

The elements in this smaller script include:

- `webp_path`: This variable will be generated using [`sed`](the-basics-of-using-the-sed-stream-editor-to-manipulate-text-in-linux) and the matched file name from the `bash` command, denoted by the positional parameter `$0`. A _here string_ (`<<<`) will pass this name to `sed`. 
- `if [! -f "$webp_path"]`: This test will establish whether or not a file named `"$webp_path"` already exists, using the logical `not` operator (`!`).
- `cwebp`: This command will create the file if it doesn’t exist, using the `-q` option so as not to print output.

With this smaller script in place of the `'commands'` placeholder, the full script to convert JPEG images will now look like this:

~/webp-convert.sh

    # converting JPEG images
    find $1 -type f -and \( -iname "*.jpg" -o -iname "*.jpeg" \) \
    -exec bash -c '
    webp_path=$(sed 's/\.[^.]*$/.webp/' <<< "$0");
    if [! -f "$webp_path"]; then 
      cwebp -quiet -q 90 "$0" -o "$webp_path";
    fi;' {} \;

To convert PNG images to WebP, we’ll take the same approach, with two differences: First, the `-iname` pattern in the `find` command will be `"*.png"`. Second, the conversion command will use the `-lossless` option instead of the quality `-q` option.

The completed script looks like this:

~/webp-convert.sh

    #!/bin/bash
    
    # converting JPEG images
    find $1 -type f -and \( -iname "*.jpg" -o -iname "*.jpeg" \) \
    -exec bash -c '
    webp_path=$(sed 's/\.[^.]*$/.webp/' <<< "$0");
    if [! -f "$webp_path"]; then 
      cwebp -quiet -q 90 "$0" -o "$webp_path";
    fi;' {} \;
    
    # converting PNG images
    find $1 -type f -and -iname "*.png" \
    -exec bash -c '
    webp_path=$(sed 's/\.[^.]*$/.webp/' <<< "$0");
    if [! -f "$webp_path"]; then 
      cwebp -quiet -lossless "$0" -o "$webp_path";
    fi;' {} \;

Save the file and exit the editor.

Next, let’s put the `webp-convert.sh` script into practice using the files in the `/var/www/html/webp` directory. Make sure that the script file is executable by running the following command:

    chmod a+x ~/webp-convert.sh

Run the script on the images directory:

    ./webp-convert.sh /var/www/html/webp

Nothing happened! That’s because we already converted these images in step 2. Moving forward, the `webp-convert` script will convert images when we add new files or remove the `.webp` versions. To see how this works, delete the `.webp` files we created in step 2:

    rm /var/www/html/webp/*.webp

After deleting all of the `.webp` images, run the script again to make sure it works:

    ./webp-convert.sh /var/www/html/webp

The `ls` command will confirm that the script has converted the images successfully:

    ls -lh /var/www/html/webp

    Output-rw-r--r-- 1 sammy sammy 7.4M Oct 28 23:36 image1.jpg
    -rw-r--r-- 1 sammy sammy 3.9M Feb 18 16:46 image1.webp
    -rw-r--r-- 1 sammy sammy 16M Dec 18 2016 image2.jpg
    -rw-r--r-- 1 sammy sammy 7.0M Feb 18 16:59 image2.webp
    -rw-r--r-- 1 sammy sammy 116K Jul 18 2017 logo.png
    -rw-r--r-- 1 sammy sammy 60K Feb 18 16:42 logo.webp

The script in this step is the foundation of using WebP images in your site, as you will need a working version of all images in WebP format to serve to visitors. The next step will cover how to automate the conversion of new images.

## Step 4 — Watching Image Files in a Directory

In this step, we will create a new script to watch our images directory for changes and automatically convert newly created images.

Creating a script that watches our images directory can address certain issues with the `webp-convert.sh` script as it’s written. For example, this script will not identify if we have renamed an image. If we had an image called `foo.jpg`, ran `webp-convert.sh`, renamed that file `bar.jpg`, and then ran `webp-convert.sh` again, we would have duplicate `.webp` files (`foo.webp` and `bar.webp`). To solve this issue, and to avoid running the script manually, we will add _watchers_ to another script. Watchers watch specified files or directories for changes and run commands in response to those changes.

The `inotifywait` command will set up watchers in our script. This command is part of the `inotify-tools` package, a set of command line tools that provide a simple interface to the inotify kernel subsystem. To install it on Ubuntu 16.04 type:

    sudo apt-get install inotify-tools

With CentOS 7, the `inotify-tools` package is available on the EPEL repository. Install the EPEL repository and `inotify-tools` package using the following commands:

    sudo yum install epel-release
    sudo yum install inotify-tools

Next, create the `webp-watchers.sh` script in your user’s home directory using `nano`:

    nano ~/webp-watchers.sh

The first line in the script will look like this:

~/webp-watchers.sh

    inotifywait -q -m -r --format '%e %w%f' -e close_write -e moved_from -e moved_to -e delete $1

This line includes the following elements:

- `inotifywait`: This command watches for changes to a certain directory.
- `-q`: This option will tell `inotifywait` to be quiet and not produce a lot of output. 
- `-m`: This option will tell `inotifywait` to run indefinitely and not exit after receiving a single event.
- `-r`: This option will set up watchers recursively, watching a specified directory and all its sub-directories.
- `--format`: This option tells `inotifywait` to monitor changes using the event name followed by the file path. The events we want to monitor are `close_write` (triggered when a file is created and completely written to the disk), `moved_from` and `moved_to` (triggered when a file is moved), and `delete` (triggered when a file is deleted).
- `$1`: This positional parameter holds the path of the changed files.

Next, let’s add a `grep` command to establish whether or not our files are JPEG or PNG images. The `-i` option will tell `grep` to ignore case, `-E` will specify that `grep` should use extended regular expressions, and `--line-buffered` will tell `grep` to pass the matched lines to a `while` loop:

~/webp-watchers.sh

    inotifywait -q -m -r --format '%e %w%f' -e close_write -e moved_from -e moved_to -e delete $1 | grep -i -E '\.(jpe?g|png)$' --line-buffered

Next, we will build a `while` loop with the `read` command. `read` will process the event `inotifywait` has detected, assigning it to a variable called `$operation` and the processed file path to a variable named `$path`:

~/webp-watchers.sh

    ...
    | while read operation path; do
      # commands
    done;

Let’s combine this loop with the rest of our script:

~/webp-watchers.sh

    inotifywait -q -m -r --format '%e %w%f' -e close_write -e moved_from -e moved_to -e delete $1 \
    | grep -i -E '\.(jpe?g|png)$' --line-buffered \
    | while read operation path; do
      # commands
    done;

After the `while` loop has checked the event, the commands inside the loop will take the following actions, depending on the result:

- Create a new WebP file if a new image file was created or moved to the target directory.
- Delete the WebP file if the associated image file was deleted or moved from the target directory.

There are three main sections inside the loop. A variable called `webp_path` will hold the path to the `.webp` version of the subject image:

~/webp-watchers.sh

    ...
    webp_path="$(sed 's/\.[^.]*$/.webp/' <<< "$path")";

Next, the script will test which event has happened:

~/webp-watchers.sh

    ...
    if [$operation = "MOVED_FROM"] || [$operation = "DELETE"]; then
      # commands to be executed if the file is moved or deleted
    elif [$operation = "CLOSE_WRITE,CLOSE"] || [$operation = "MOVED_TO"]; then
      # commands to be executed if a new file is created
    fi;

If the file has been moved or deleted, the script will check if the `.webp` version exists. If it does, the script will remove it using `rm`:

~/webp-watchers.sh

    ...
    if [-f "$webp_path"]; then
      $(rm -f "$webp_path");
    fi;

For newly created files, compression will happen as follows:

- If the matched file is a PNG image, the script will use lossless compression.
- If it’s not, the script will use lossy compression with the `-quality` option.

Let’s add the `cwebp` commands that will do this work to the script:

~/webp-watchers.sh

    ...
    if [$(grep -i '\.png$' <<< "$path")]; then
      $(cwebp -quiet -lossless "$path" -o "$webp_path");
    else
      $(cwebp -quiet -q 90 "$path" -o "$webp_path");
    fi;

In full, the `webp-watchers.sh` file will look like this:

~/webp-watchers.sh

    #!/bin/bash
    echo "Setting up watches.";
    
    # watch for any created, moved, or deleted image files
    inotifywait -q -m -r --format '%e %w%f' -e close_write -e moved_from -e moved_to -e delete $1 \
    | grep -i -E '\.(jpe?g|png)$' --line-buffered \
    | while read operation path; do
      webp_path="$(sed 's/\.[^.]*$/.webp/' <<< "$path")";
      if [$operation = "MOVED_FROM"] || [$operation = "DELETE"]; then # if the file is moved or deleted
        if [-f "$webp_path"]; then
          $(rm -f "$webp_path");
        fi;
      elif [$operation = "CLOSE_WRITE,CLOSE"] || [$operation = "MOVED_TO"]; then # if new file is created
         if [$(grep -i '\.png$' <<< "$path")]; then
           $(cwebp -quiet -lossless "$path" -o "$webp_path");
         else
           $(cwebp -quiet -q 90 "$path" -o "$webp_path");
         fi;
      fi;
    done;

Save and close the file. Do not forget to make it executable:

    chmod a+x ~/webp-watchers.sh

Let’s run this script on the `/var/www/html/webp` directory in the background, using `&`. Let’s also redirect standard output and standard error to an `~/output.log`, to store output in an readily available location:

    ./webp-watchers.sh /var/www/html/webp > output.log 2>&1 &

At this point, you have converted the JPEG and PNG files in `/var/www/html/webp` to the WebP format, and set up watchers to do this work using the `webp-watchers.sh` script. It is now time to explore options to deliver WebP images to your website visitors.

## Step 5 — Serving WebP Images to Visitors Using HTML Elements

In this step, we will explain how to serve WebP images with HTML elements. At this point there should be `.webp` versions of each of the test JPEG and PNG images in the `/var/www/html/webp` directory. We can now serve them to supporting browsers using either HTML5 elements (`<picture>`) or the `mod_rewrite` Apache module. We’ll use HTML elements in this step.

The `<picture>` element allows you to include images directly in your web pages and to define more than one image source. If your browser supports the WebP format, it will download the `.webp` version of the file instead of the original one, resulting in web pages being served faster. It is worth mentioning that the `<picture>` element is well-supported in modern browsers that support the WebP format.

The `<picture>` element is a container with `<source>` and `<img>` elements that point to particular files. If we use `<source>` to point to a `.webp` image, the browser will see if it can handle it; otherwise, it will fall back to the image file specified in the `src` attribute in the `<img>` element.

Let’s use the `logo.png` file from our `/var/www/html/webp` directory, which we converted to `logo.webp`, as an example with `<source>`. We can use the following HTML code to display `logo.webp` to any browser that supports WebP format, and `logo.png` to any browser that does not support WebP or the `<picture>` element.

Create an HTML file located at `/var/www/html/webp/picture.html`:

    nano /var/www/html/webp/picture.html

Add the following code to the web page to display `logo.webp` to supporting browsers using the `<picture>` element:

/var/www/html/webp/picture.html

    <picture>
      <source srcset="logo.webp" type="image/webp">
      <img src="logo.png" alt="Site Logo">
    </picture>

Save and close the file.

To test that everything is working, navigate to `http://your_server_ip/webp/picture.html`. You should see the test PNG image.

Now that you know how to serve `.webp` images directly from HTML code, let’s look at how to automate this process using Apache’s `mod_rewrite` module.

## Step 6 — Serving WebP Images Using mod\_rewrite

If we want to optimize the speed of our site, but have a large number of pages or too little time to edit HTML code, then Apache’s `mod_rewrite` module can help us automate the process of serving `.webp` images to supporting browsers.

First, create an `.htaccess` file in the `/var/www/html/webp` directory using the following command:

    nano /var/www/html/webp/.htaccess

The `ifModule` directive will test if `mod_rewrite` is available; if it is, it can be activated by using `RewriteEngine On`. Add these directives to the `.htaccess`:

/var/www/html/webp/.htaccess

    <ifModule mod_rewrite.c>
      RewriteEngine On 
      # further directives
    </IfModule>

The web server will make several tests to establish when to serve `.webp` images to the user. When a browser makes a request, it includes a header to indicate to the server what the browser is capable of handling. In the case of WebP, the browser will send an `Accept` header containing `image/webp`. We will check if the browser sent that header using `RewriteCond`, which specifies the criteria that should be matched in order to carry out the `RewriteRule`:

/var/www/html/webp/.htaccess

    ...
    RewriteCond %{HTTP_ACCEPT} image/webp

Everything should be filtered out but JPEG and PNG images. Using `RewriteCond` again, add a regular expression (similar to what we used in the previous sections) to match the requested URI:

/var/www/html/webp/.htaccess

    ...
    RewriteCond %{REQUEST_URI} (?i)(.*)(\.jpe?g|\.png)$ 

The `(?i)` modifier will make the match case-insensitive.

To check if the `.webp` version of the file exists, use `RewriteCond` again as follows:

/var/www/html/webp/.htaccess

    ...
    RewriteCond %{DOCUMENT_ROOT}%1.webp -f

Finally, if all previous conditions were met, `RewriteRule` will redirect the requested JPEG or PNG file to its associated WebP file. Notice that this will _redirect_ using the `-R` flag, rather than _rewrite_ the URI. The difference between rewriting and redirecting is that the server will serve the rewritten URI without telling the browser. For example, the URI will show that the file extension is `.png`, but it will actually be a `.webp` file. Add `RewriteRule` to the file:

/var/www/html/webp/.htaccess

    ...
    RewriteRule (?i)(.*)(\.jpe?g|\.png)$ %1\.webp [L,T=image/webp,R] 

At this point, the `mod_rewrite` section in the `.htaccess` file is complete. But what will happen if there is an intermediate caching server between your server and the client? It could serve the wrong version to the end user. That is why it is worth checking to see if `mod_headers` is enabled, in order to send the `Vary: Accept` header. The `Vary` header indicates to caching servers (like proxy servers) that the content type of the document varies depending on the capabilities of the browser which requests the document. Moreover, the response will be generated based on the `Accept` header in the request. A request with a different `Accept` header might get a different response. This header is important because it prevents cached WebP images from being served to non-supporting browsers:

/var/www/html/webp/.htaccess

    ...
    <IfModule mod_headers.c>
      Header append Vary Accept env=REDIRECT_accept
    </IfModule>

Finally, at the end of the `.htaccess` file, set the MIME type of the `.webp` images to `image/webp` by using the `AddType` directive. This will serve the images using the right MIME type:

/var/www/html/webp/.htaccess

    ...
    AddType image/webp .webp

This is the final version of our `.htaccess` file:

/var/www/html/webp/.htaccess

    <ifModule mod_rewrite.c>
      RewriteEngine On 
      RewriteCond %{HTTP_ACCEPT} image/webp
      RewriteCond %{REQUEST_URI} (?i)(.*)(\.jpe?g|\.png)$ 
      RewriteCond %{DOCUMENT_ROOT}%1.webp -f
      RewriteRule (?i)(.*)(\.jpe?g|\.png)$ %1\.webp [L,T=image/webp,R] 
    </IfModule>
    
    <IfModule mod_headers.c>
      Header append Vary Accept env=REDIRECT_accept
    </IfModule>
    
    AddType image/webp .webp

**Note** : You can merge this `.htaccess` with another `.htaccess` file, if it exists. If you are using WordPress, for instance, you should copy this `.htaccess` file and paste it at the **top** of the existing file.

Let’s put what we have done in this step into practice. If you have followed the instructions in the previous steps, you should have `logo.png` and `logo.webp` images in `/var/www/html/webp`. Let’s use a simple `<img>` tag to include `logo.png` in our web page. Create a new HTML file to test the setup:

    nano /var/www/html/webp/img.html

Enter the following HTML code in the file:

/var/www/html/webp/img.html

    <img src="logo.png" alt="Site Logo">

Save and close the file.

When you visit the web page using Chrome by visiting `http://your_server_ip/webp/img.html`, you will notice that the served image is the `.webp` version (try opening the image in a new tab). If you use Firefox, you will get a `.png` image automatically.

## Conclusion

In this tutorial, we have covered basic techniques for working with WebP images. We have explained how to use `cwebp` to convert files, as well as two options to serve these images to users: HTML5’s `<picture>` element and Apache’s `mod_rewrite`.

In order to customize the scripts from this tutorial, you can look at some of these resources:

- To learn more about the features of the WebP format and how to use the conversion tools, see the [WebP documentation](https://developers.google.com/speed/webp/).
- To see more details about the usage of `<picture>` element, see its [documentation on MDN](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/picture).
- To fully understand how to use `mod_rewrite`, see its [documentation](https://httpd.apache.org/docs/current/mod/mod_rewrite.html).

Using the WebP format for your images will reduce file sizes by a considerable amount. This can lower bandwidth usage and make page loads faster, particularly if your web site uses a lot of images.
