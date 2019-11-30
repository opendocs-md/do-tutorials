---
author: Justin Ellingwood
date: 2015-08-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-test-your-firewall-configuration-with-nmap-and-tcpdump
---

# How To Test your Firewall Configuration with Nmap and Tcpdump

## Introduction

Setting up a firewall for your infrastructure is a great way to provide some basic security for your services. Once you’ve developed a policy you are happy with, the next step is to test your firewall rules. It is important to get a good idea of whether your firewall rules are doing what you think they are doing and to get an impression of what your infrastructure looks like to the outside world.

In this guide, we’ll go over some simple tools and techniques that you can use to validate your firewall rules. These are some of the same tools that malicious users may use, so you will be able to see what information they can find by making requests of your servers.

## Prerequisites

In this guide, we will assume that you have a firewall configured on at least one server. You can get started building your firewall policy by following one or more of these guides:

- Iptables
  - [How To Set Up a Firewall Using Iptables on Ubuntu 14.04](how-to-set-up-a-firewall-using-iptables-on-ubuntu-14-04)
  - [Iptables Essentials: Common Firewall Rules and Commands](iptables-essentials-common-firewall-rules-and-commands)
  - [How To Migrate from FirewallD to Iptables on CentOS 7](how-to-migrate-from-firewalld-to-iptables-on-centos-7)
  - [How To Implement a Basic Firewall Template with Iptables on Ubuntu 14.04](how-to-implement-a-basic-firewall-template-with-iptables-on-ubuntu-14-04)
- UFW
  - [How To Set Up a Firewall with UFW on Ubuntu 14.04](how-to-set-up-a-firewall-with-ufw-on-ubuntu-14-04)
  - [UFW Essentials: Common Firewall Rules and Commands](ufw-essentials-common-firewall-rules-and-commands)
- FirewallD
  - [How To Set Up a Firewall Using FirewallD on CentOS 7](how-to-set-up-a-firewall-using-firewalld-on-centos-7)

In this guide, we will call the server containing the firewall policies you wish to test the **target**. In addition to your target, you will also need to have access to a server to test from, located outside of the network that your firewall protects. In this guide, we will use an Ubuntu 14.04 server as our auditing machine.

Once you have a server to test from and the targets you wish to evaluate, you can continue with this guide.

Warning
You should only perform the activities outlined in this guide on infrastructure that you control, for the purpose of security auditing. The laws surrounding port scanning are uncertain in many jurisdictions. ISPs and other providers have been known to ban users who are found port scanning.  

## The Tools We Will Use to Test Firewall Policies

There are quite a few different tools that we can use to test our firewall policies. Some of them have overlapping functionality. We will not cover every possible tool. Instead, we will cover some general categories of auditing tools and go over the tools we will be using in this guide.

### Packet Analyzers

Packet analyzers can be used to watch all of the network traffic that goes over an interface in great detail. Most packet analyzers have the option of operating in real time, displaying the packets as they are sent or received, or of writing packet information to a file and processing it at a later time. Packet analysis gives us the ability to see, at a granular level, what types of responses our target machines are sending back to hosts on the open network.

For the purposes of our guide, we will be using the `tcpdump` tool. This is a good option because it is powerful, flexible, and rather ubiquitous on Linux systems. We will use it to capture the raw packets as we run our tests in case we need the transcript for later analysis. Some other popular options are Wireshark (or `tshark`, its command line cousin) and `tcpflow` which can piece together entire TCP conversations in an organized fashion.

### Port Scanners

In order to generate the traffic and responses for our packet analyzer to capture, we will use a port scanner. Port scanners can be used to craft and send various types of packets to remote hosts in order to discover type of traffic the server accepts. Malicious users often use this as a discovery tool to try to find vulnerable services to exploit (part of the reason to use a firewall in the first place), so we will use this to try to see what an attacker could discover.

For this guide, we will use the `nmap` network mapping and port scanning tool. We can use `nmap` to send packets of different types to try to figure out which services are on our target machine and what firewall rules protect it.

## Setting Up the Auditing Machine

Before we get started, we should make sure we have the tools discussed above. We can get `tcpdump` from Ubuntu’s repositories. We can also get `nmap` with this method, but the repository version is likely out of date. Instead, we will install some packages to assist us in software compilation and then build it ourselves from source.

Update the local package index and install the software if it is not already available. We will also purge `nmap` from our system if it is already installed to avoid conflicts:

    sudo apt-get update
    sudo apt-get purge nmap
    sudo apt-get install tcpdump build-essential libssl-dev

Now that we have our compilation tools and the SSL development library, we can get the latest version of `nmap` from the download page on the [official site](https://nmap.org/download.html). Open the page in your web browser.

Scroll down to the “Source Code Distribution” section. At the bottom, you will see a link to the source code for the latest version of `nmap`. At the time of this writing, it looks like this:

![Nmap latest version](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/firewall_testing/nmap_latest.png)

Right-click on the link and copy the link address.

Back on your auditing machine, move into your home directory and use `wget` to download the link you pasted. Make sure to update the link below to reflect the most recent version you copied from the site:

    cd ~
    wget https://nmap.org/dist/nmap-6.49BETA4.tar.bz2

Decompress the file you downloaded and move into the resulting directory by typing:

    tar xjvf nmap*
    cd nmap*

Configure and compile the source code by typing:

    ./configure
    make

Once the compilation is complete, you can install the resulting executables and supporting files on your system by typing:

    sudo make install

Confirm your installation by typing:

    nmap -V

The output should match the version you downloaded from the `nmap` website:

    OutputNmap version 6.49BETA4 ( https://nmap.org )
    Platform: x86_64-unknown-linux-gnu
    Compiled with: nmap-liblua-5.2.3 openssl-1.0.1f nmap-libpcre-7.6 nmap-libpcap-1.7.3 nmap-libdnet-1.12 ipv6
    Compiled without:
    Available nsock engines: epoll poll select

Next, we will create a directory where we can store our scan results:

    mkdir ~/scan_results

To make sure that you get clean results, exit out of any sessions you might have open between your auditing system and the target system. This includes SSH sessions, any HTTP(S) connections you may have established in a web browser, etc.

## Scan your Target for Open TCP Ports

Now that we have our server and files ready, we will begin by scanning our target host for open TCP ports.

There are actually a few TCP scans that `nmap` knows how to do. The best one to usually start off with is a SYN scan, also known as a “half-open scan” because it never actually negotiates a full TCP connection. This is often used by attackers because it fails to register on some intrusion detection systems because it never completes a full handshake.

### Setting Up the Packet Capture

Before we scan, we will set up `tcpdump` to capture the traffic generated by the test. This will help us analyze the packets sent and received in more depth later on if we need to. Let’s create a directory within `~/scan_results` so that we can keep the files related to our SYN scan together:

    mkdir ~/scan_results/syn_scan

We can start a `tcpdump` capture and write the results to a file in our `~/scan_results/syn_scan` directory with the following command:

    sudo tcpdump host target_ip_addr -w ~/scan_results/syn_scan/packets

By default, `tcpdump` will run in the foreground. In order to run our `nmap` scan in the same window, we’ll need to pause the `tcpdump` process and then restart it in the background.

We can pause the running process by hitting `CTRL-Z`:

    CTRL-Z

This will pause the running process:

    Output^Z
    [1]+ Stopped sudo tcpdump host target_ip_addr -w ~/scan_results/syn_scan/packets

Now, you can restart the job in the background by typing `bg`:

    bg

You should see a similar line of output, this time without the “Stopped” label and with an ampersand at the end to indicate that the process will be run in the background:

    Output[1]+ sudo tcpdump host target_ip_addr -w ~/scan_results/syn_scan/packets &

The command is now running in the background, watching for any packets going between our audit and target machines. We can now run our SYN scan.

### Run the SYN Scan

With `tcpdump` recording our traffic to the target machine, we are ready to run `nmap`. We will use the following flags to get `nmap` to perform the actions we require:

- **`-sS`** : This starts a SYN scan. This is technically the default scan that `nmap` will perform if no scan type is given, but we will include it here to be explicit.
- **`-Pn`** : This tells `nmap` to skip the host discovery step, which would abort the test early if the host doesn’t respond to a ping. Since we know that the target is online, we can skip this.
- **`-p-`** : By default, SYN scans will only try the 1000 most commonly used ports. This tells `nmap` to check every available port.
- **`-T4`** : This sets a timing profile for `nmap`, telling it to speed up the test at the risk of slightly less accurate results. 0 is the slowest and 5 is the fastest. Since we’re scanning every port, we can use this as our baseline and re-check any ports later that might have been reported incorrectly.
- **`-vv`** : This increases the verbosity of the output.
- **`--reason`** : This tells `nmap` to provide the reason that a port’s state was reported a certain way.
- **`-oN`** : This writes the results to a file that we can use for later analysis.

Note
One thing to keep in mind is that in order to check IPv6, you will need to add the `-6` flag to your commands. Because most of the prerequisite tutorials do not accept IPv6 traffic, we will be skipping IPv6 for this guide. Add this flag if your firewall accepts IPv6 traffic.  

Together, the command will look something like this:

    sudo nmap -sS -Pn -p- -T4 -vv --reason -oN ~/scan_results/syn_scan/nmap.results target_ip_addr

Even with the timing template set at 4, the scan will likely take quite some time as it runs through 65,535 ports (my test run lasted about forty minutes). You will see results begin to print that look something like this:

    OutputStarting Nmap 6.49BETA4 ( https://nmap.org ) at 2015-08-26 16:54 EDT
    Initiating Parallel DNS resolution of 1 host. at 16:54
    Completed Parallel DNS resolution of 1 host. at 16:54, 0.12s elapsed
    Initiating SYN Stealth Scan at 16:54
    Scanning 198.51.100.15 [65535 ports]
    Discovered open port 22/tcp on 198.51.100.15
    Discovered open port 80/tcp on 198.51.100.15
    SYN Stealth Scan Timing: About 6.16% done; ETC: 17:02 (0:07:52 remaining)
    SYN Stealth Scan Timing: About 8.60% done; ETC: 17:06 (0:10:48 remaining)
    
    . . .

### Stop the tcpdump Packet Capture

Once the scan is complete, we can bring our `tcpdump` process back into the foreground and stop it.

Bring it out of the background by typing:

    fg

Stop the process by holding the control key and hitting “c”:

    CTRL-C

### Analyzing the Results

You should now have two files in your `~/scan_results/syn_scan` directory. One called `packets`, generated by the `tcpdump` run, and one generated by `nmap` called `nmap.results`.

Let’s look at the `nmap.results` file first:

    less ~/scan_results/syn_scan/nmap.results

~/scan\_results/syn\_scan/nmap.results

    # Nmap 6.49BETA4 scan initiated Wed Aug 26 17:05:13 2015 as: nmap -sS -Pn -p- -T4 -vv --reason -oN /home/user/scan_results/syn_scan/nmap.results 198.51.100.15
    Increasing send delay for 198.51.100.15 from 0 to 5 due to 9226 out of 23064 dropped probes since last increase.
    Increasing send delay for 198.51.100.15 from 5 to 10 due to 14 out of 34 dropped probes since last increase.
    Nmap scan report for 198.51.100.15
    Host is up, received user-set (0.00097s latency).
    Scanned at 2015-08-26 17:05:13 EDT for 2337s
    Not shown: 65533 closed ports
    Reason: 65533 resets
    PORT STATE SERVICE REASON
    22/tcp open ssh syn-ack ttl 63
    80/tcp open http syn-ack ttl 63
    
    Read data files from: /usr/local/bin/../share/nmap
    # Nmap done at Wed Aug 26 17:44:10 2015 -- 1 IP address (1 host up) scanned in 2336.85 seconds

The highlighted area above contains the main results of the scan. We can see that port 22 and port 80 are open on the scanned host in order to allow SSH and HTTP traffic. We can also see that 65,533 ports were closed. Another possible result would be “filtered”. Filtered means that these ports were identified as being stopped by something along the network path. It could be a firewall on the target, but it could also be filtering rules on any of the intermediate hosts between the audit and target machines.

If we want to see the actual packet traffic that was sent to and received from the target, we can read the `packets` file back into `tcpdump`, like this:

    sudo tcpdump -nn -r ~/scan_results/syn_scan/packets | less

This file contains the entire conversation that took place between the two hosts. You can filter in a number of ways.

For instance, to view only the traffic _sent_ to the target, you can type:

    sudo tcpdump -nn -r ~/scan_results/syn_scan/packets 'dst target_ip_addr' | less

Likewise, to view only the response traffic, you can change the “dst” to “src”:

    sudo tcpdump -nn -r ~/scan_results/syn_scan/packets 'src target_ip_addr' | less

Open TCP ports would respond to these requests with a SYN packet. We can search directly for responses for this type with a filter like this:

    sudo tcpdump -nn -r ~/scan_results/syn_scan/packets 'src target_ip_addr and tcp[tcpflags] & tcp-syn != 0' | less

This will show you only the successful SYN responses, and should match the ports that you saw in the `nmap` run:

    Outputreading from file packets, link-type EN10MB (Ethernet)
    17:05:13.557597 IP 198.51.100.15.22 > 198.51.100.2.63872: Flags [S.], seq 2144564104, ack 4206039348, win 29200, options [mss 1460], length 0
    17:05:13.558085 IP 198.51.100.15.80 > 198.51.100.2.63872: Flags [S.], seq 3550723926, ack 4206039348, win 29200, options [mss 1460], length 0

You can do more analysis of the data as you see fit. It has all been captured for asynchronous processing and analysis.

## Scan your Target for Open UDP Ports

Now that you have a good handle on how to run these tests, we can complete a similar process to scan for open UDP ports.

### Setting Up the Packet Capture

Once again, let’s create a directory to hold our results:

    mkdir ~/scan_results/udp_scan

Start a `tcpdump` capture again. This time, write the file to the new `~/scan_results/udp_scan` directory:

    sudo tcpdump host target_ip_addr -w ~/scan_results/udp_scan/packets

Pause the process and put it into the background:

    CTRL-Z

    bg

### Run the UDP Scan

Now, we are ready to run the UDP scan. Due to the nature of the UDP protocol, this scan will typically take **significantly** longer than the SYN scan. In fact, it could take over a day if you are scanning every port on the system. UDP is a connectionless protocol, so receiving no response could mean that the target’s port is blocked, that it was accepted, or that the packet was lost. To try to distinguish between these, `nmap` must retransmit additional packets to try to get a response.

Most of the flags will be the same as we used for the SYN scan. In fact, the only new flag is:

- **`-sU`** : This tells `nmap` to perform a UDP scan.

#### Speeding up the UDP Test

If you are worried about the amount of time this test takes, you may only want to test a subset of your UDP ports at first. You can test only the 1000 most common ports by leaving out the `-p-` flag. This can shorten your scan time considerably. If you want a complete picture though, you’ll have to go back later and scan your entire port range.

Because you are scanning your own infrastructure, perhaps the best option to speed up the UDP scans is to temporarily disable ICMP rate limiting on the target system. Typically, Linux hosts limit ICMP responses to 1 per second (this is typically a good thing, but not for our auditing), which means that a full UDP scan would take over 18 hours. You can check this setting on your target machine by typing:

    sudo sysctl net.ipv4.icmp_ratelimit

    Outputnet.ipv4.icmp_ratelimit = 1000

The “1000” is the number of milliseconds between responses. We can temporarily disable this rate limiting on the target system by typing:

    sudo sysctl -w net.ipv4.icmp_ratelimit=0

It is very important to revert this value after your test.

#### Running the Test

Be sure to write the results to the `~/scan_results/udp_scan` directory. All together, the command should look like this:

    sudo nmap -sU -Pn -p- -T4 -vv --reason -oN ~/scan_results/udp_scan/nmap.results target_ip_addr

Even with disabling ICMP rate limiting on the target, this scan took about 2 hours and 45 minutes during our test run. After the scan is complete, you should revert your ICMP rate limit (if you modified it) on the target machine:

    sudo sysctl -w net.ipv4.icmp_ratelimit=1000

### Stop the tcpdump Packet Capture

Bring the `tcpdump` process back into the foreground on your audit machine by typing:

    fg

Stop the packet capture by holding control and hitting “c”:

    CTRL-c

### Analyzing the Results

Now, we can take a look at the generated files.

The resulting `nmap.results` file should look fairly similar to the one we saw before:

    less ~/scan_results/udp_scan/nmap.results

~/scan\_results/udp\_scan/nmap.results

    # Nmap 6.49BETA4 scan initiated Thu Aug 27 12:42:42 2015 as: nmap -sU -Pn -p- -T4 -vv --reason -oN /home/user/scan_results/udp_scan/nmap.results 198.51.100.15
    Increasing send delay for 198.51.100.15 from 0 to 50 due to 10445 out of 26111 dropped probes since last increase.
    Increasing send delay for 198.51.100.15 from 50 to 100 due to 11 out of 23 dropped probes since last increase.
    Increasing send delay for 198.51.100.15 from 100 to 200 due to 3427 out of 8567 dropped probes since last increase.
    Nmap scan report for 198.51.100.15
    Host is up, received user-set (0.0010s latency).
    Scanned at 2015-08-27 12:42:42 EDT for 9956s
    Not shown: 65532 closed ports
    Reason: 65532 port-unreaches
    PORT STATE SERVICE REASON
    22/udp open|filtered ssh no-response
    80/udp open|filtered http no-response
    443/udp open|filtered https no-response
    
    Read data files from: /usr/local/bin/../share/nmap
    # Nmap done at Thu Aug 27 15:28:39 2015 -- 1 IP address (1 host up) scanned in 9956.97 seconds

A key difference between this result and the SYN result earlier will likely be the amount of ports marked `open|filtered`. This means that `nmap` couldn’t determine whether the lack of a response meant that a service accepted the traffic or whether it was dropped by some firewall or filtering mechanism along the delivery path.

Analyzing the `tcpdump` output is also significantly more difficult because there are no connection flags and because we must match up ICMP responses to UDP requests.

We can see how `nmap` had to send out many packets to the ports that were reported as `open|filtered` by asking to see the UDP traffic to one of the reported ports:

    sudo tcpdump -nn -Q out -r ~/scan_results/udp_scan/packets 'udp and port 22'

You will likely see something that looks like this:

    Outputreading from file /home/user/scan_results/udp_scan/packets, link-type EN10MB (Ethernet)
    14:57:40.801956 IP 198.51.100.2.60181 > 198.51.100.15.22: UDP, length 0
    14:57:41.002364 IP 198.51.100.2.60182 > 198.51.100.15.22: UDP, length 0
    14:57:41.202702 IP 198.51.100.2.60183 > 198.51.100.15.22: UDP, length 0
    14:57:41.403099 IP 198.51.100.2.60184 > 198.51.100.15.22: UDP, length 0
    14:57:41.603431 IP 198.51.100.2.60185 > 198.51.100.15.22: UDP, length 0
    14:57:41.803885 IP 198.51.100.2.60186 > 198.51.100.15.22: UDP, length 0

Compare this to the results we see from one of the scanned ports that was marked as “closed”:

    sudo tcpdump -nn -Q out -r ~/scan_results/udp_scan/packets 'udp and port 53'

    Outputreading from file /home/user/scan_results/udp_scan/packets, link-type EN10MB (Ethernet)
    13:37:24.219270 IP 198.51.100.2.60181 > 198.51.100.15.53: 0 stat [0q] (12)

We can try to manually reconstruct the process that `nmap` goes through by first compiling a list of all of the ports that we’re sending UDP packets to using something like this:

    sudo tcpdump -nn -Q out -r ~/scan_results/udp_scan/packets "udp" | awk '{print $5;}' | awk 'BEGIN { FS = "." } ; { print $5 +0}' | sort -u | tee outgoing

Then, we can see which ICMP packets we received back saying the port was unreachable:

    sudo tcpdump -nn -Q in -r ~/scan_results/udp_scan/packets "icmp" | awk '{print $10,$11}' | grep unreachable | awk '{print $1}' | sort -u | tee response

We can see then take these two responses and see which UDP packets never received an ICMP response back by typing:

    comm -3 outgoing response

This should mostly match the list of ports that `nmap` reported (it may contain some false positives from lost return packets).

## Host and Service Discovery

We can run some additional tests on our target to see if it is possible for `nmap` to identify the operating system running or any of the service versions.

Let’s make a directory to hold our versioning results:

    mkdir ~/scan_results/versions

### Discovering the Versions of Services on the Server

We can attempt to guess the versions of services running on the target through a process known as fingerprinting. We retrieve information from the server and compare it to known versions in our database.

A `tcpdump` wouldn’t be too useful in this scenario, so we can skip it. If you want to capture it anyways, follow the process we used last time.

The `nmap` scan we need to use is triggered by the `-sV` flag. Since we already did SYN and UDP scans, we can pass in the exact ports we want to look at with the `-p` flag. Here, we’ll look at 22 and 80 (the ports that were shown in our SYN scan):

    sudo nmap -sV -Pn -p 22,80 -vv --reason -oN ~/scan_results/versions/service_versions.nmap target_ip_addr

If you view the file that results, you may get information about the service running, depending on how “chatty” or even how unique the service’s response is:

    less ~/scan_results/versions/service_versions.nmap

~/scan\_results/versions/service\_versions.nmap

    # Nmap 6.49BETA4 scan initiated Thu Aug 27 15:46:12 2015 as: nmap -sV -Pn -p 22,80 -vv --reason -oN /home/user/scan_results/versions/service_versions.nmap 198.51.100.15
    Nmap scan report for 198.51.100.15
    Host is up, received user-set (0.0011s latency).
    Scanned at 2015-08-27 15:46:13 EDT for 8s
    PORT STATE SERVICE REASON VERSION
    22/tcp open ssh syn-ack ttl 63 OpenSSH 6.6.1p1 Ubuntu 2ubuntu2 (Ubuntu Linux; protocol 2.0)
    80/tcp open http syn-ack ttl 63 nginx 1.4.6 (Ubuntu)
    Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel
    
    Read data files from: /usr/local/bin/../share/nmap
    Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
    # Nmap done at Thu Aug 27 15:46:21 2015 -- 1 IP address (1 host up) scanned in 8.81 seconds

Here, you can see that the test was able to identify the SSH server version and the Linux distribution that packaged it as well as the SSH protocol version accepted. It also recognized the version of Nginx and again identified it as matching an Ubuntu package.

### Discovering the Host Operating System

We can try to have `nmap` guess the host operating system based on characteristics of its software and responses as well. This works much in the same way as service versioning. Once again, we will omit the `tcpdump` run from this test, but you can perform it if you’d like.

The flag we need in order to perform operating system detection is `-O` (the capitalized letter “O”). A full command may look something like this:

    sudo nmap -O -Pn -vv --reason -oN ~/scan_results/versions/os_version.nmap target_ip_addr

If you view the output file, you might see something that looks like this:

    less ~/scan_results/versions/os_version.nmap

~/scan\_results/versions/os\_versions.nmap

    # Nmap 6.49BETA4 scan initiated Thu Aug 27 15:53:54 2015 as: nmap -O -Pn -vv --reason -oN /home/user/scan_results/versions/os_version.nmap 198.51.100.15
    Increasing send delay for 198.51.100.15 from 0 to 5 due to 65 out of 215 dropped probes since last increase.
    Increasing send delay for 198.51.100.15 from 5 to 10 due to 11 out of 36 dropped probes since last increase.
    Increasing send delay for 198.51.100.15 from 10 to 20 due to 11 out of 35 dropped probes since last increase.
    Increasing send delay for 198.51.100.15 from 20 to 40 due to 11 out of 29 dropped probes since last increase.
    Increasing send delay for 198.51.100.15 from 40 to 80 due to 11 out of 31 dropped probes since last increase.
    Nmap scan report for 198.51.100.15
    Host is up, received user-set (0.0012s latency).
    Scanned at 2015-08-27 15:53:54 EDT for 30s
    Not shown: 998 closed ports
    Reason: 998 resets
    PORT STATE SERVICE REASON
    22/tcp open ssh syn-ack ttl 63
    80/tcp open http syn-ack ttl 63
    No exact OS matches for host (If you know what OS is running on it, see https://nmap.org/submit/ ).
    TCP/IP fingerprint:
    OS:SCAN(V=6.49BETA4%E=4%D=8/27%OT=22%CT=1%CU=40800%PV=N%DS=2%DC=I%G=Y%TM=55
    OS:DF6AF0%P=x86_64-unknown-linux-gnu)SEQ(SP=F5%GCD=1%ISR=106%TI=Z%CI=Z%TS=8
    OS:)OPS(O1=M5B4ST11NW8%O2=M5B4ST11NW8%O3=M5B4NNT11NW8%O4=M5B4ST11NW8%O5=M5B
    OS:4ST11NW8%O6=M5B4ST11)WIN(W1=7120%W2=7120%W3=7120%W4=7120%W5=7120%W6=7120
    OS:)ECN(R=Y%DF=Y%T=40%W=7210%O=M5B4NNSNW8%CC=Y%Q=)T1(R=Y%DF=Y%T=40%S=O%A=S+
    OS:%F=AS%RD=0%Q=)T2(R=N)T3(R=N)T4(R=Y%DF=Y%T=40%W=0%S=A%A=Z%F=R%O=%RD=0%Q=)
    OS:T5(R=Y%DF=Y%T=40%W=0%S=Z%A=S+%F=AR%O=%RD=0%Q=)T6(R=Y%DF=Y%T=40%W=0%S=A%A
    OS:=Z%F=R%O=%RD=0%Q=)T7(R=N)U1(R=Y%DF=N%T=40%IPL=164%UN=0%RIPL=G%RID=G%RIPC
    OS:K=G%RUCK=G%RUD=G)U1(R=N)IE(R=N)
    
    Uptime guess: 1.057 days (since Wed Aug 26 14:32:23 2015)
    Network Distance: 2 hops
    TCP Sequence Prediction: Difficulty=245 (Good luck!)
    IP ID Sequence Generation: All zeros
    
    Read data files from: /usr/local/bin/../share/nmap
    OS detection performed. Please report any incorrect results at https://nmap.org/submit/ .
    # Nmap done at Thu Aug 27 15:54:24 2015 -- 1 IP address (1 host up) scanned in 30.94 seconds

We can see that in this case, `nmap` has no guesses for the operating system based on the signature it saw. If it had received more information, it would likely show various percentages which indicate how the target machine’s signature matches the operating system signatures in its databases. You can see the fingerprint signature that `nmap` received from the target below the `TCP/IP fingerprint:` line.

Operating system identification can help an attacker determine which exploits may be useful on the system. Configuring your firewall to respond to fewer inquiries can help to hinder the accuracy of some of these detection methods.

## Conclusion

Testing your firewall and building an awareness of what your internal network looks like to an outside attacker can help minimize your risk. The information you find from probing your own infrastructure may open up a conversation about whether any of your policy decisions need to be revisited in order to increase security. It may also illuminate any gaps in your security that may have occurred due to incorrect rule ordering or forgotten test policies. It is recommended that you test your policies with the latest scanning databases regularity in order improve, or at least maintain, your current level of security.

To get an idea of some policy improvements for your firewall, check out [this guide](how-to-choose-an-effective-firewall-policy-to-secure-your-servers).
