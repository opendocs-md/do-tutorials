---
author: András Magyar
date: 2018-03-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/automatically-deploy-laravel-applications-deployer-ubuntu
---

# How to Automatically Deploy Laravel Applications with Deployer on Ubuntu 16.04

## Introduction

[Laravel](https://laravel.com/) is an open-source PHP web framework designed to make common web development tasks, such as authentication, routing, and caching, easier. [Deployer](https://deployer.org/) is an open-source PHP deployment tool with out-of-the-box support for a number of popular frameworks, including Laravel, CodeIgniter, Symfony, and Zend Framework.

Deployer automates deployments by cloning an application from a Git repository to a server, installing dependencies with [Composer](https://getcomposer.org/), and configuring the application so you don’t have to do so manually. This allows you to spend more time on development, instead of uploads and configurations, and lets you deploy more frequently.

In this tutorial, you will deploy a Laravel application automatically without any downtime. To do this, you will prepare the local development environment from which you’ll deploy code and then configure a production server with Nginx and a MySQL database to serve the application.

## Prerequisites

Before you begin this guide you’ll need the following:

- One Ubuntu 16.04 server with a non-root user with sudo privileges as described in the [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) tutorial.

- A LEMP stack installed as described in the [How To Install Linux, Nginx, MySQL, PHP (LEMP stack) in Ubuntu 16.04](how-to-install-linux-nginx-mysql-php-lemp-stack-in-ubuntu-16-04) tutorial.

- PHP, Composer, and Git installed on your server by following Steps 1 and 2 of [How To Install and Use Composer on Ubuntu 16.04](how-to-install-and-use-composer-on-ubuntu-16-04).

- The `php-xml` and `php-mbstring` packages installed on your server. Install these by running: `sudo apt-get install php7.0-mbstring php7.0-xml`.

- A Git server. You can use services like [GitLab](https://about.gitlab.com/), [Bitbucket](https://bitbucket.org/) or [GitHub](https://github.com/). GitLab and Bitbucket offer private repositories for free, and [GitHub offers private repositories starting at $7/month](https://github.com/pricing). Alternatively, you could set up a private Git server by following the tutorial [How To Set Up a Private Git Server on a VPS](how-to-set-up-a-private-git-server-on-a-vps).

- A domain name that points to your server. The [How To Set Up a Host Name with DigitalOcean](how-to-set-up-a-host-name-with-digitalocean) tutorial can help you configure this.

- Composer and Git installed on your local machine as well. The precise installation method depends on your local operating system. Instructions for installing Git are available on the [Git project’s Downloads page](https://git-scm.com/) and you can download Composer directly from the [Composer project website](https://getcomposer.org/).

## Step 1 — Setting up your Local Development Environment

Since you will be creating and deploying your application from your local machine, begin by configuring your local development environment. Deployer will control the entire deployment process from your local machine, so start off by installing it.

**Note:** If you use Windows on your local machine you should use a BASH emulator (like Git bash) to run all local commands.

On your **local machine** , open the terminal and download the Deployer installer using `curl`:

    curl -LO https://deployer.org/deployer.phar

Next, run a short PHP script to verify that the installer matches the SHA-1 hash for the latest installer found on the [Deployer - download page](https://deployer.org/download). Replace the highlighted value with the latest hash:

    php -r "if (hash_file('sha1', 'deployer.phar') === '35e8dcd50cf7186502f603676b972065cb68c129') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('deployer.phar'); } echo PHP_EOL;"

    OutputInstaller verified

Make Deployer available system wide. Note that if you’re running Windows or macOS on your local machine, you may need to create the `/usr/local/bin/dep` directory before running this command:

    sudo mv deployer.phar /usr/local/bin/dep

Make it executable:

    sudo chmod +x /usr/local/bin/dep

Next, create a Laravel project on your **local machine** :

    composer create-project --prefer-dist laravel/laravel laravel-app "5.5.*"

You have installed all the required software on your local machine. With that in place, we will move on to creating a Git repository for the application.

## Step 2 — Connecting to Your Remote Git Repository

Deployer was designed to enable users to deploy code from anywhere. To allow this functionality, it requires users to push code to a repository on the Internet from which Deployer then copies the code over to the production server. We will use Git, an open-source version control system, to manage the source code of the Laravel application. You can connect to the Git server using SSH protocol, and to do this securely you need to generate SSH keys. This is more secure than password-based authentication and let’s you avoid typing the password before each deployment.

Run the following command on your **local machine** to generate the SSH key. Note that the `-f` specifies the filename of the key file, and you can replace gitkey with your own filename. It will generate an SSH key pair (named `gitkey` and `gitkey.pub`) to the `~/.ssh/` folder.

    ssh-keygen -t rsa -b 4096 -f ~/.ssh/gitkey

It is possible that you have more SSH keys on your local machine, so configure the SSH client to know which SSH private key to use when it connects to your Git server.

Create an SSH config file **on your local machine** :

    touch ~/.ssh/config

Open the file and add a shortcut to your Git server. This should contain the `HostName` directive (pointing to your Git server’s hostname) and the `IdentityFile` directive (pointing to the file path of the SSH key you just created:

~/.ssh/config

    Host mygitserver.com
        HostName mygitserver.com
        IdentityFile ~/.ssh/gitkey

Save and close the file, and then restrict its permissions:

    chmod 600 ~/.ssh/config

Now your SSH client will know which private key use to connect to the Git server.

Display the content of your public key file with the following command:

    cat ~/.ssh/gitkey.pub

Copy the output and add the public key to your Git server.

If you use a Git hosting service, consult its documentation on how to add SSH keys to your account:

- [Add SSH keys to GitHub](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/)

- [Add SSH keys to GitLab](https://docs.gitlab.com/ee/gitlab-basics/create-your-ssh-keys.html)

- [Add SSH keys to Bitbucket](https://confluence.atlassian.com/bitbucket/set-up-an-ssh-key-728138079.html)

Now you will be able to connect to your Git server with your local machine. Test the connection with the following command:

    ssh -T git@mygitserver.com

If this command results in an error, check that you added your SSH keys correctly by referring to your Git hosting service’s documentation and try connecting again.

Before pushing the application to the remote Git repository and deploying it, let’s first configure the production server.

## Step 3 — Configuring the Deployer User

Deployer uses the SSH protocol to securely execute commands on the server. For this reason, the first step we will take toward configuring the production server will be to create a user which Deployer can use to log in and execute commands on your server via SSH.

Log in to your LEMP server with a sudo non-root user and create a new user called “ **deployer** ” with the following command:

    sudo adduser deployer

Laravel needs some writable directories to store cached files and uploads, so the directories created by the **deployer** user must be writable by the Nginx web server. Add the user to the **www-data** group to do this:

    sudo usermod -aG www-data deployer

The default permission for files created by the **deployer** user should be `644` for files and `755` for directories. This way, the **deployer** user will be able to read and write the files, while the group and other users will be able to read them.

Do this by setting **deployer** ’s default umask to `022`:

    sudo chfn -o umask=022 deployer

We’ll store the application in the `/var/www/html/` directory, so change the ownership of the directory to the **deployer** user and **www-data** group.

    sudo chown deployer:www-data /var/www/html

The **deployer** user needs to be able to modify files and folders within the `/var/www/html` directory. Given that, all new files and subdirectories created within the `/var/www/html` directory should inherit the folder’s group id ( **www-data** ). To achieve this, set the group id on this directory with the following command:

    sudo chmod g+s /var/www/html

Deployer will clone the Git repo to the production server using SSH, so you want to ensure that the connection between your LEMP server and the Git server is secure. We’ll use the same approach we used for our local machine, and we’ll generate an SSH key for the **deployer** user.

Switch to the **deployer** user on your server:

    su - deployer

Next, generate an SSH key pair as the **deployer** user. This time, you can accept the default filename of the SSH keys:

    ssh-keygen -t rsa -b 4096

Display the public key:

    cat ~/.ssh/id_rsa.pub

Copy the public key and add it to your Git server as you did in the previous step.

Your local machine will communicate with the server using SSH as well, so you should generate SSH keys for the **deployer** user on your local machine and add the public key to the server.

On your **local machine** run the following command. Feel free to replace deployerkey with a filename of your choice:

    ssh-keygen -t rsa -b 4096 -f ~/.ssh/deployerkey

Copy the following command’s output which contains the public key:

    cat ~/.ssh/deployerkey.pub

On **your server** as the **deployer** user run the following:

    nano ~/.ssh/authorized_keys

Paste the public key to the editor and hit `CTRL-X`, `Y`, then `ENTER` to save and exit.

Restrict the permissions of the file:

    chmod 600 ~/.ssh/authorized_keys

Now switch back to the sudo user:

    exit

Now your server can connect to the Git server and you can log in to the server with the **deployer** user from your local machine.

Log in from your local machine to your server as the **deployer** user to test the connection:

    ssh deployer@your_server_ip -i ~/.ssh/deployerkey

After you have logged in as **deployer** , test the connection between your server and the Git server as well:

    ssh -T git@mygitserver.com

Finally, exit the server:

    exit

From here, we can move on to configuring Nginx and MySQL on our web server.

## Step 4 — Configuring Nginx

We’re now ready to configure the web server which will serve the application. This will involve configuring the document root and directory structure that we will use to hold the Laravel files. We will set up Nginx to serve our files from the `/var/www/laravel` directory.

First, we need to create a [server block configuration file](how-to-set-up-nginx-server-blocks-virtual-hosts-on-ubuntu-16-04) for the new site.

Log in to the server as your sudo user and create a new config file. Remember to replace example.com with your own domain name:

    sudo nano /etc/nginx/sites-available/example.com 

Add a `server` block to the top of the configuration file:

example.com ’\>/etc/nginx/sites-available/example.com 

    server {
            listen 80;
            listen [::]:80;
    
            root /var/www/html/laravel-app/current/public;
            index index.php index.html index.htm index.nginx-debian.html;
    
            server_name example.com www.example.com;
    }

The two `listen` directives at the top tell Nginx which ports to listen to, and the `root` directive defines the document root where Laravel will be installed. The `current/public` in the path of the root directory is a symbolic link that points to the latest release of the application. By adding the `index` directive, we are telling Nginx to serve any `index.php` files first before looking for their HTML counterparts when requesting a directory location. The `server_name` directive should be followed by your domain and any of its aliases.

We should also modify the way that Nginx will handle requests. This is done through the `try_files` directive. We want it to try to serve the request as a file first and, if it cannot find a file with the correct name, it should attempt to serve the default index file for a directory that matches the request. Failing this, it should pass the request to the `index.php` file as a query parameter.

example.com ’\>/etc/nginx/sites-available/example.com 

    server {
            listen 80;
            listen [::]:80;
    
            root /var/www/html/laravel-app/current/public;
            index index.php index.html index.htm index.nginx-debian.html;
    
            server_name example.com www.example.com;
    
            location / {
                    try_files $uri $uri/ /index.php?$query_string;
            }

Next, we need to create a block that handles the actual execution of any PHP files. This will apply to any files that end in .php. It will try the file itself and then try to pass it as a parameter to the `index.php` file.

We will set the `fastcgi` directives to tell Nginx to use the actual path of the application (resolved after following the symbolic link), instead of the symbolic link. If you don’t add these lines to the configuration, the path where the symbolic link points will be cached, meaning that an old version of your application will be loaded after the deployment. Without these directives, you would have to manually clear the cache after each deployment and requests to your application could potentially fail. Additionally, the `fastcgi_pass` directive will make sure that Nginx uses the socket that php7-fpm is using for communication and that the `index.php` file is used as the index for these operations.

example.com ’\>/etc/nginx/sites-available/example.com 

    server {
            listen 80;
            listen [::]:80;
    
            root /var/www/html/laravel-app/current/public;
            index index.php index.html index.htm index.nginx-debian.html;
    
            server_name example.com www.example.com;
    
            location / {
                    try_files $uri $uri/ /index.php?$query_string;
            }
    
    
            location ~ \.php$ {
                    include snippets/fastcgi-php.conf;
    
                    fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
                    fastcgi_param DOCUMENT_ROOT $realpath_root;
    
                    fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    
            }

Finally, we want to make sure that Nginx does not allow access to any hidden `.htaccess` files. We will do this by adding one more location block called `location ~ /\.ht` and, within that block, a directive specifying `deny all;`.

After adding this last location block, the configuration file will look like this:

example.com ’\>/etc/nginx/sites-available/example.com 

    server {
            listen 80;
            listen [::]:80;
    
            root /var/www/html/laravel-app/current/public;
            index index.php index.html index.htm index.nginx-debian.html;
    
            server_name example.com www.example.com;
    
            location / {
                    try_files $uri $uri/ /index.php?$query_string;
            }
    
    
            location ~ \.php$ {
                    include snippets/fastcgi-php.conf;
    
                    fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
                    fastcgi_param DOCUMENT_ROOT $realpath_root;
    
                    fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    
            }
    
            location ~ /\.ht {
                    deny all;
            }
    
    }

Save and close the file (`CTRL-X`, `Y`, then `ENTER`), and then enable the new server block by creating a symbolic link to the `sites-enabled` directory:

    sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/

Test your configuration file for syntax errors:

    sudo nginx -t

If you see any errors, go back and recheck your file before continuing.

Restart Nginx to push the necessary changes:

    sudo systemctl restart nginx

The Nginx server is now configured. Next, we will configure the application’s MySQL database.

## Step 5 — Configuring MySQL

After the installation, MySQL creates a **root** user by default. This user has unlimited privileges, though, so it is a bad security practice to use the **root** user for your application’s database. Instead, we will create the database for the application with a dedicated user.

Log in to the MySQL console as **root** :

    mysql -u root -p

This will prompt you for the **root** password.

Next, create a new database for the application:

    CREATE DATABASE laravel_database DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

Then, create a new database user. For the purposes of this tutorial, we will call this user `laravel_user` with the password `password`, although you should replace the password with a strong password of your choosing.

    CREATE USER 'laravel_user'@'localhost' IDENTIFIED BY 'password';

Grant privileges on the database to the user:

    GRANT ALL ON laravel_database.* TO 'laravel_user'@'localhost';

Next, reload the privileges:

    FLUSH PRIVILEGES;

And, finally, exit from the MySQL console:

    EXIT;

Your application’s database and user are now configured, and you’re almost ready to run your first deployment.

## Step 6 — Deploying the Application

So far, you’ve configured all the tools and programs needed for Deployer to function. All that’s left to do before running your first deployment is to finish configuring your Laravel app and Deployer itself, and to initialize and push the app to your remote Git repository.

Open the terminal on your **local machine** and change the working directory to the application’s folder with the following command:

    cd /path/to/laravel-app

From this directory, run the following command which creates a file called `deploy.php` within the `laravel-app` folder, which will contain configuration information and tasks for deployment:

    dep init -t Laravel

Next, open the `deploy.php` file with your preferred text editor or IDE. The third line includes a PHP script which contains the necessary tasks and configurations to deploy a Laravel application:

deploy.php

    <?php
    namespace Deployer;
    
    require 'recipe/laravel.php';
    
    . . .

Below this are some fields which you should edit to align with your configuration:

- Under `// Project Name`, add the name of your Laravel project.
- Under `// Project Repository`, add the link to your Git repository.
- In the `// Hosts` section, add your server’s IP address or domain name to the `host()` directive, the name of your Deployer user ( **deployer** in our examples) to the `user()` directive. You should also add the SSH key you created in Step 3 to the `identifyFile()` directive. Finally, you should add file path of the folder containing your application.

When you’ve finished editing these fields, they should look like this:

deploy.php

    ...
    // Project name
    set('application', 'laravel-app');
    
    // Project repository
    set('repository', 'git@mygitserver.com:username/repository.git');
    
    . . .
    
    // Hosts
    
    host('your_server_ip')
        ->user('deployer')
        ->identityFile('~/.ssh/deployerkey')
        ->set('deploy_path', '/var/www/html/laravel-app');
    

Next, comment out the last line of the file, `before('deploy:symlink', 'artisan:migrate');`. This line instructs Deployer to run the database migrations automatically, and by commenting it out we are disabling it. If you don’t comment it out, the deployment will fail as this line requires appropriate database credentials to be on the server, which can only be added using a file which will be generated during the first deployment:

deploy.php

    ...
    // Migrate database before symlink new release.
    
    //before('deploy:symlink', 'artisan:migrate');

Before we can deploy the project, we must first push it to the remote Git repository.

On your **local machine** change the working directory to your application’s folder:

    cd /path/to/laravel-app

Run the following command in your `laravel-app` directory to initialize a Git repository in the project folder:

    git init

Next, add all the project files to the repository:

    git add .

Commit the changes:

    git commit -m 'Initial commit for first deployment.'

Add your Git server to the local repository with the following command. Be sure to replace the highlighted text with your own remote repository’s URL:

    git remote add origin git@mygitserver.com:username/repository.git

Push the changes to the remote Git repository:

    git push origin master

Finally, run your first deployment using the `dep` command:

    dep deploy

If everything goes well you should see an output like this with `Successfully deployed!` at the end:

    Deployer's output✈︎ Deploying master on your_server_ip
    ✔ Executing task deploy:prepare
    ✔ Executing task deploy:lock
    ✔ Executing task deploy:release
    ➤ Executing task deploy:update_code
    ✔ Ok
    ✔ Executing task deploy:shared
    ✔ Executing task deploy:vendors
    ✔ Executing task deploy:writable
    ✔ Executing task artisan:storage:link
    ✔ Executing task artisan:view:clear
    ✔ Executing task artisan:cache:clear
    ✔ Executing task artisan:config:cache
    ✔ Executing task artisan:optimize
    ✔ Executing task deploy:symlink
    ✔ Executing task deploy:unlock
    ✔ Executing task cleanup
    Successfully deployed!

The following structure will be created on your server, inside the `/var/www/html/laravel-app` directory:

    ├── .dep
    ├── current -> releases/1
    ├── releases
    │ └── 1
    └── shared
        ├── .env
        └── storage

Verify this by running the following command **on your server** which will list the files and directories in the folder:

    ls /var/www/html/laravel-app

    Outputcurrent .dep releases shared

Here’s what each of these files and directories contain:

- The `releases` directory contains deploy releases of the Laravel application.

- `current` is a symlink to the last release.

- The `.dep` directory contains special metadata for Deployer.

- The `shared` directory contains the `.env` configuration file and the `storage` directory which will be symlinked to each release. 

However, the application will not work yet because the `.env` file is empty. This file is used to hold important configurations like the application key — a random string used for encryptions. If it is not set, your user sessions and other encrypted data will not be secure. The app has a `.env` file on your **local machine** , but Laravel’s `.gitignore` file excludes it from the Git repo because storing sensitive data like passwords in a Git repository is not a good idea and, also, the application requires different settings on your server. The `.env` file contains the database connection settings as well, which is why we disabled the database migrations for the first deployment.

Let’s configure the application on your server.

Log in to your server as the **deployer** user:

    ssh deployer@your_server_ip -i ~/.ssh/deployerkey

Run the following command **on your server** , and copy and paste your local `.env` file to the editor:

    nano /var/www/html/laravel-app/shared/.env

Before you can save it, there are some changes that you should make. Set `APP_ENV` to `production`, `APP_DEBUG` to `false`, `APP_LOG_LEVEL` to `error` and don’t forget to replace the database, the database user, and password with your own. You should replace `example.com` with your own domain as well:

/var/www/html/laravel-app/shared/.env

    APP_NAME=Laravel
    APP_ENV=production
    APP_KEY=base64:cA1hATAgR4BjdHJqI8aOj8jEjaaOM8gMNHXIP8d5IQg=
    APP_DEBUG=false
    APP_LOG_LEVEL=error
    APP_URL=http://example.com
    
    DB_CONNECTION=mysql
    DB_HOST=127.0.0.1
    DB_PORT=3306
    DB_DATABASE=laravel_database
    DB_USERNAME=laravel_user
    DB_PASSWORD=password
    
    BROADCAST_DRIVER=log
    CACHE_DRIVER=file
    SESSION_DRIVER=file
    QUEUE_DRIVER=sync
    
    REDIS_HOST=127.0.0.1
    REDIS_PASSWORD=null
    REDIS_PORT=6379

Save the file and close the editor.

Now uncomment the last line of the `deploy.php` file on your local machine:

deploy.php

    ...
    // Migrate database before symlink new release.
    
    before('deploy:symlink', 'artisan:migrate');

**Warning:** This will cause your database migrations to run automatically on every deployment. This will let you avoid migrating the databases manually, but don’t forget to back up your database before you deploy.

To check that this configuration is working, deploy the application once more. Run the following command **on your local machine** :

    dep deploy

Now, your application will work correctly. If you visit your server’s domain name([http://example.com](http://example.com)) you will see the following landing page:

![Laravel's landing page](https://assets.digitalocean.com/laraveldeployer/deployerimg.png)

You don’t have to edit the `.env` file on your server before all deployments. A typical deployment is not as complicated as the first and is done with just a few commands.

## Step 7 — Running a Typical Deployment

As a final step, this section will cover a simple deployment process you can use on a daily basis.

Start by modifying the application before you deploy again. For example, you can add a new route in the `routes/web.php` file:

/routes/web.php

    <?php
    
    . . .
    
    Route::get('/', function () {
        return view('welcome');
    });
    
    Route::get('/greeting', function(){
        return 'Welcome!';
    });

Commit these changes:

    git commit -am 'Your commit message.'

Push the changes to the remote Git repository:

    git push origin master

And, finally, deploy the application:

    dep deploy

You have successfully deployed the application to your server.

## Conclusion

You have configured your local computer and your server to easily deploy your Laravel application with zero downtime. The article covers only the basics of Deployer, and it has many useful functions. You can deploy to more servers at once and create tasks; for example, you can specify a task to back up the database before the migration. If you’d like to learn more about Deployer’s features, you can find more information in the [Deployer documentation](https://deployer.org/docs/tasks).
