---
author: Erika Heidi
date: 2019-08-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-perform-redis-benchmark-tests
---

# How to Benchmark the Performance of a Redis Server on Ubuntu 18.04

## Introduction

Benchmarking is an important practice when it comes to analyzing the overall performance of database servers. It’s helpful for identifying bottlenecks as well as opportunities for improvement within those systems.

[Redis](https://redis.io/) is an in-memory data store that can be used as database, cache and message broker. It supports from simple to complex data structures including hashes, strings, sorted sets, bitmaps, geospatial data, among other types. In this guide, we’ll demonstrate how to benchmark the performance of a Redis server running on Ubuntu 18.04, using a few different tools and methods.

### Prerequisites

To follow this guide, you’ll need:

- One Ubuntu 18.04 server with a non-root sudo user and a basic firewall configured. To set this up, you can follow our [Initial Server Setup Guide for Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04). 
- Redis installed on your server, as explained in our guide on [How to Install and Secure Redis on Ubuntu 18.04](how-to-install-and-secure-redis-on-ubuntu-18-04). 

**Note:** The commands demonstrated in this tutorial were executed on a dedicated Redis server running on a 4GB DigitalOcean Droplet.

## Using the Included `redis-benchmark` Tool

Redis comes with a benchmark tool called `redis-benchmark`. This program can be used to simulate an arbitrary number of clients connecting at the same time and performing actions on the server, measuring how long it takes for the requests to be completed. The resulting data will give you an idea of the average number of requests that your Redis server is able to handle per second.

The following list details some of the common command options used with `redis-benchmark`:

- `-h`: Redis host. Default is `127.0.0.1`.
- `-p`: Redis port. Default is `6379`.
- `-a`: If your server requires authentication, you can use this option to provide the password.
- `-c`: Number of clients (parallel connections) to simulate. Default value is 50.
- `-n`: How many requests to make. Default is 100000.
- `-d`: Data size for `SET` and `GET` values, measured in bytes. Default is 3.
- `-t`: Run only a subset of tests. For instance, you can use `-t get,set` to benchmark the performance of `GET` and `SET` commands.
- `-P`: Use pipelining for performance improvements.
- `-q`: Quiet mode, shows only the average _requests per second_ information.

For instance, if you want to check the average number of requests per second that your local Redis server can handle, you can use:

    redis-benchmark -q 

You will get output similar to this, but with different numbers:

    OutputPING_INLINE: 85178.88 requests per second
    PING_BULK: 83056.48 requests per second
    SET: 72202.16 requests per second
    GET: 94607.38 requests per second
    INCR: 84961.77 requests per second
    LPUSH: 78988.94 requests per second
    RPUSH: 88652.48 requests per second
    LPOP: 87950.75 requests per second
    RPOP: 80971.66 requests per second
    SADD: 80192.46 requests per second
    HSET: 84317.03 requests per second
    SPOP: 78125.00 requests per second
    LPUSH (needed to benchmark LRANGE): 84175.09 requests per second
    LRANGE_100 (first 100 elements): 52383.45 requests per second
    LRANGE_300 (first 300 elements): 21547.08 requests per second
    LRANGE_500 (first 450 elements): 14471.78 requests per second
    LRANGE_600 (first 600 elements): 9383.50 requests per second
    MSET (10 keys): 71225.07 requests per second
    

You can also limit the tests to a subset of commands of your choice using the `-t` parameter. The following command shows the averages for the `GET` and `SET` commands only:

    redis-benchmark -t set,get -q

    OutputSET: 76687.12 requests per second
    GET: 82576.38 requests per second

The default options will use 50 parallel connections to create 100000 requests to the Redis server. If you want to increase the number of parallel connections to simulate a peak in usage, you can use the `-c` option for that:

    redis-benchmark -t set,get -q -c 1000

Because this will use 1000 concurrent connections instead of the default 50, you should expect a decrease in performance:

    OutputSET: 69444.45 requests per second
    GET: 70821.53 requests per second

If you want detailed information in the output, you can remove the `-q` option. The following command will use 100 parallel connections to run 1000000 SET requests on the server:

    redis-benchmark -t set -c 100 -n 1000000

You will get output similar to this:

    Output====== SET ======
      1000000 requests completed in 11.29 seconds
      100 parallel clients
      3 bytes payload
      keep alive: 1
    
    95.22% <= 1 milliseconds
    98.97% <= 2 milliseconds
    99.86% <= 3 milliseconds
    99.95% <= 4 milliseconds
    99.99% <= 5 milliseconds
    99.99% <= 6 milliseconds
    100.00% <= 7 milliseconds
    100.00% <= 8 milliseconds
    100.00% <= 8 milliseconds
    88605.35 requests per second
    

The default settings use 3 bytes for key values. You can change this with the option `-d`. The following command will benchmark `GET` and `SET` commands using 1MB key values:

    redis-benchmark -t set,get -d 1000000 -n 1000 -q

Because the server is working with a much bigger payload this time, a significant decrease of performance is expected:

    OutputSET: 1642.04 requests per second
    GET: 822.37 requests per second

It is important to realize that even though these numbers are useful as a quick way to evaluate the performance of a Redis instance, they don’t represent the maximum throughput a Redis instance can sustain. By using _[pipelining](https://redis.io/topics/pipelining)_, applications can send multiple commands at once in order to improve the number of requests per second the server can handle. With `redis-benchmark`, you can use the `-P` option to simulate real world applications that make use of this Redis feature.

To compare the difference, first run the `redis-benchmark` command with default values and no pipelining, for the `GET` and `SET` tests:

    redis-benchmark -t get,set -q

    OutputSET: 86281.27 requests per second
    GET: 89847.26 requests per second

The next command will run the same tests, but will pipeline 8 commands together:

    redis-benchmark -t get,set -q -P 8

    OutputSET: 653594.81 requests per second
    GET: 793650.75 requests per second

As you can see from the output, there is a substantial performance improvement with the use of pipelining.

## Checking Latency with `redis-cli`

If you’d like a simple measurement of the average time a request takes to receive a response, you can use the Redis client to check for the average server latency. In the context of Redis, latency is a measure of how long does a `ping` command take to receive a response from the server.

The following command will show real-time latency stats for your Redis server:

    redis-cli --latency

You’ll get output similar to this, showing an increasing number of samples and a variable average latency:

    Outputmin: 0, max: 1, avg: 0.18 (970 samples)

This command will keep running indefinitely. You can stop it with a `CTRL+C`.

To monitor latency over a certain period of time, you can use:

    redis-cli --latency-history

This will track latency averages over time, with a configurable interval that is set to 15 seconds by default. You will get output similar to this:

    Outputmin: 0, max: 1, avg: 0.18 (1449 samples) -- 15.01 seconds range
    min: 0, max: 1, avg: 0.16 (1449 samples) -- 15.00 seconds range
    min: 0, max: 1, avg: 0.17 (1449 samples) -- 15.00 seconds range
    min: 0, max: 1, avg: 0.17 (1444 samples) -- 15.01 seconds range
    min: 0, max: 1, avg: 0.17 (1446 samples) -- 15.01 seconds range
    min: 0, max: 1, avg: 0.17 (1449 samples) -- 15.00 seconds range
    min: 0, max: 1, avg: 0.16 (1444 samples) -- 15.00 seconds range
    min: 0, max: 1, avg: 0.17 (1445 samples) -- 15.01 seconds range
    min: 0, max: 1, avg: 0.16 (1445 samples) -- 15.01 seconds range
    ...

Because the Redis server on our example is idle, there’s not much variation between latency samples. If you have a peak in usage, however, this should be reflected as an increase in latency within the results.

If you’d like to measure the _system_ latency only, you can use `--intrinsic-latency` for that. The intrinsic latency is inherent to the environment, depending on factors such as hardware, kernel, server neighbors and other factors that aren’t controlled by Redis.

You can see the intrinsic latency as a baseline for your overall Redis performance. The following command will check for the intrinsic system latency, running a test for 30 seconds:

    redis-cli --intrinsic-latency 30

You should get output similar to this:

    Output…
    
    498723744 total runs (avg latency: 0.0602 microseconds / 60.15 nanoseconds per run).
    Worst run took 22975x longer than the average latency.

Comparing both latency tests can be helpful for identifying hardware or system bottlenecks that could affect the performance of your Redis server. Considering the total latency for a request to our example server has an average of 0.18 microseconds to complete, an intrinsic latency of 0.06 microseconds means that one third of the total request time is spent by the system in processes that aren’t controlled by Redis.

## Using the Memtier Benchmark Tool

[Memtier](https://github.com/RedisLabs/memtier_benchmark) is a high-throughput benchmark tool for Redis and [Memcached](https://memcached.org/) created by Redis Labs. Although very similar to `redis-benchmark` in various aspects, Memtier has several configuration options that can be tuned to better emulate the kind of load you might expect on your Redis server, in addition to offering cluster support.

To get Memtier installed on your server, you’ll need to compile the software from source. First, install the dependencies necessary to compile the code:

    sudo apt-get install build-essential autoconf automake libpcre3-dev libevent-dev pkg-config zlib1g-dev

Next, go to your home directory and clone the `memtier_benchmark` project from its [Github repository](https://github.com/RedisLabs/memtier_benchmark):

    cd
    git clone https://github.com/RedisLabs/memtier_benchmark.git

Navigate to the project directory and run the `autoreconf` command to generate the application configuration scripts:

    cd memtier_benchmark
    autoreconf -ivf

Run the `configure` script in order to generate the application artifacts required for compiling:

    ./configure

Now run `make` to compile the application:

    make

Once the build is finished, you can test the executable with:

    ./memtier_benchmark --version

This will give you the following output:

    Outputmemtier_benchmark 1.2.17
    Copyright (C) 2011-2017 Redis Labs Ltd.
    This is free software. You may redistribute copies of it under the terms of
    the GNU General Public License <http://www.gnu.org/licenses/gpl.html>.
    There is NO WARRANTY, to the extent permitted by law.

The following list contains some of the most common options used with the `memtier_benchmark` command:

- `-s`: Server host. Default is **localhost**.
- `-p`: Server port. Default is `6379`.
- `-a`: Authenticate requests using the provided password.
- `-n`: Number of requests per client (default is 10000).
- `-c`: Number of clients (default is 50).
- `-t`: Number of threads (default is 4).
- `--pipeline`: Enable pipelining.
- `--ratio`: Ratio between `SET` and `GET` commands, default is 1:10.
- `--hide-histogram`: Hides detailed output information.

Most of these options are very similar to the options present in `redis-benchmark`, but Memtier tests performance in a different way. To simulate common real-world environments better, the default benchmark performed by `memtier_benchmark` will test for `GET` and `SET` requests only, on a ratio of 1 to 10. With 10 GET operations for each SET operation in the test, this arrangement is more representative of a common web application using Redis as a database or cache. You can adjust the ratio value with the option `--ratio`.

The following command runs `memtier_benchmark` with default settings, while providing only high-level output information:

    ./memtier_benchmark --hide-histogram

**Note** : if you have configured your Redis server to require authentication, you should provide the `-a` option along with your Redis password to the `memtier_benchmark` command:

    ./memtier_benchmark --hide-histogram -a your_redis_password

You’ll see output similar to this:

    Output...
    
    4 Threads
    50 Connections per thread
    10000 Requests per client
    
    
    ALL STATS
    =========================================================================
    Type Ops/sec Hits/sec Misses/sec Latency KB/sec 
    -------------------------------------------------------------------------
    Sets 8258.50 --- --- 2.19800 636.05 
    Gets 82494.28 41483.10 41011.18 2.19800 4590.88 
    Waits 0.00 --- --- 0.00000 --- 
    Totals 90752.78 41483.10 41011.18 2.19800 5226.93 

According to this run of `memtier_benchmark`, our Redis server can execute about 90 thousand operations per second in a 1:10 `SET`/`GET` ratio.

It’s important to note that each benchmark tool has its own algorithm for performance testing and data presentation. For that reason, it’s normal to have slightly different results on the same server, even when using similar settings.

## Conclusion

In this guide, we demonstrated how to perform benchmark tests on a Redis server using two distinct tools: the included `redis-benchmark`, and the `memtier_benchmark` tool developed by Redis Labs. We also saw how to check for the server latency using `redis-cli`. Based on the data obtained from these tests, you’ll have a better understanding of what to expect from your Redis server in terms of performance, and what are the bottlenecks of your current setup.
