---
author: Mark Drake
date: 2019-03-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-address-crashes-in-mysql
---

# How To Address Crashes in MySQL

 **Part of the Series: [How To Troubleshoot Issues in MySQL](/community/tutorial_series/how-to-troubleshoot-issues-in-mysql)**

This guide is intended to serve as a troubleshooting resource and starting point as you diagnose your MySQL setup. We’ll go over some of the issues that many MySQL users encounter and provide guidance for troubleshooting specific problems. We will also include links to DigitalOcean tutorials and the official MySQL documentation that may be useful in certain cases.

The most common cause of crashes in MySQL is that it stopped or failed to start due to insufficient memory. To check this, you will need to review the MySQL error log after a crash.

First, attempt to start the MySQL server by typing:

    sudo systemctl start mysql

Then review the error logs to see what’s causing MySQL to crash. You can use `less` to review your logs, one page at a time:

    sudo less /var/log/mysql/error.log

Some common messages that would indicate an insufficient amount of memory are `Out of memory` or `mmap can't allocate`.

Potential solutions to an inadequate amount of memory are:

- **Optimizing your MySQL configuration**. A great open-source tool for this is [MySQLtuner](https://github.com/major/MySQLTuner-perl). Running the MySQLtuner script will output a set of recommended adjustments to your MySQL configuration file (`mysqld.cnf`). Note that the longer your server has been running before using MySQLTuner, the more accurate its suggestions will be. To get a memory usage estimate of both your current settings and those proposed by MySQLTimer, use this [MySQL Calculator](http://www.mysqlcalculator.com/).

- **Reducing your web application’s reliance on MySQL for page loads**. This can usually be done by adding static caching to your application. Examples for this include Joomla, which has caching as a built-in feature that can be enabled, and [WP Super Cache](https://wordpress.org/plugins/wp-super-cache/), a WordPress plugin that adds this kind of functionality.

- **Upgrading to a larger VPS**. At minimum, we recommend a server with at least 1GB of RAM for any server using a MySQL database, but the size and type of your data can significantly affect memory requirements.

Take note that even though upgrading your server is a potential solution, it’s only recommended after you investigate and weigh all of your other options. An upgraded server with more resources will likewise cost more money, so you should only go through with resizing if it truly ends up being your best option. Also note that the MySQL documentation includes [a number of other suggestions](https://dev.mysql.com/doc/refman/5.7/en/crashing.html) for diagnosing and preventing crashes.
