---
author: Sharon Campbell
date: 2016-03-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-find-redis-logs-on-ubuntu
---

# How To Find Redis Logs on Ubuntu

Logs are essential to troubleshooting your Redis installation. You may ask yourself “Where are my Redis logs?” or “Where does Redis store log files on Ubuntu 14.04?”

With a default `apt-get` installation on Ubuntu 14.04, Redis log files are located at `/var/log/redis/redis-server.log`.

To view the last 10 lines:

    sudo tail /var/log/redis/redis-server.log

With a default from-source installation on Ubuntu 14.04, Redis log files are located at `/var/log/redis_6379.log`.

To view the last 10 lines:

    sudo tail /var/log/redis_6379.log

The [DigitalOcean Redis one-click](how-to-use-the-redis-one-click-application) log files are located at `/var/log/redis/redis_6379.log`.

To view the last 10 lines:

    sudo tail /var/log/redis/redis_6379.log

## Checking Archived Log Files

Redis also archives older log files. See a list of the archived logs with:

    ls /var/log/redis

Output

    redis-server.log redis-server.log.1.gz

You can gunzip an older file:

    sudo gunzip /var/log/redis/redis-server.log.1.gz

Then view its last 10 lines:

    sudo tail /var/log/redis/redis-server.log.1

## Using find to Search for Logs

If your logs aren’t in either of those locations, you can conduct a more general search using `find` in the `/var/logs` directory:

    find /var/log/* -name *redis*

Or, search your entire system. This might take a while if you have a lot of files. It will turn up a few permission warnings, which is normal, although we’re avoiding the worst of them in `/proc` and `/sys` with the two `-prune` flags. It will also turn up every file with `redis` in the name, which includes installation files:

    find / -path /sys -prune -o -path /proc -prune -o -name *redis*

## Setting the Log Location in redis.conf

The Redis log location is specified in Redis’s configuration file, `redis.conf`, often located at `/etc/redis/redis.conf`.

Open that file for editing:

    sudo nano /etc/redis/redis.conf

Locate the `logfile` line:

/etc/redis/redis.conf

    logfile /var/log/redis/redis-server.log

Note the location of the log files. You can edit this file path if you want to rename the log file or change its location.

## Ubuntu 15.04 and Higher: Checking systemd Logs with journalctl

You may also want to check the logs collected for Redis by systemd. (Ubuntu 15.04 and higher use systemd, although Ubuntu 14.04 defaults to Upstart.) To learn how to use the `journalctl` command for this purpose, please read this [article about journalctl](how-to-use-journalctl-to-view-and-manipulate-systemd-logs).

## Conclusion

If you want to learn more about setting up Redis, please read this article about [setting up a Redis cluster](how-to-configure-a-redis-cluster-on-ubuntu-14-04).
