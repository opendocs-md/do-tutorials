---
author: Mark Drake
date: 2019-03-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-access-mysql-error-logs
---

# How to Access MySQL Error Logs

 **Part of the Series: [How To Troubleshoot Issues in MySQL](/community/tutorial_series/how-to-troubleshoot-issues-in-mysql)**

This guide is intended to serve as a troubleshooting resource and starting point as you diagnose your MySQL setup. We’ll go over some of the issues that many MySQL users encounter and provide guidance for troubleshooting specific problems. We will also include links to DigitalOcean tutorials and the official MySQL documentation that may be useful in certain cases.

Oftentimes, the root cause of slowdowns, crashes, or other unexpected behavior in MySQL can be determined by analyzing its error logs. On Ubuntu systems, the default location for the MySQL is `/var/log/mysql/error.log`. In many cases, the error logs are most easily read with the `less` program, a command line utility that allows you to view files but not edit them:

    sudo less /var/log/mysql/error.log

If MySQL isn’t behaving as expected, you can obtain more information about the source of the trouble by running this command and diagnosing the error based on the log’s contents.
