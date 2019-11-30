---
author: Justin Ellingwood
date: 2014-03-04
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-securing-your-linux-vps
---

# An Introduction to Securing your Linux VPS

## Introduction

* * *

Taking control of your own Linux server is an opportunity to try new things and leverage the power and flexibility of a great platform. However, Linux server administrators must take the same caution that is appropriate with any network-connected machine to keep it secure and safe.

There are many different security topics that fall under the general category of “Linux security” and many opinions as to what an appropriate level of security looks like for a Linux server.

The main thing to take away from this is that you will have to decide for yourself what security protections will be necessary. Before you do this, you should be aware of the risks and the trade offs, and decide on the balance between usability and security that makes sense for you.

This article is meant to help orient you with some of the most common security measures to take in a Linux server environment. This is not an exhaustive list, and does not cover recommended configurations, but it will provide links to more thorough resources and discuss why each component is an important part of many systems.

## Blocking Access with Firewalls

* * *

One of the easiest steps to recommend to all users is to enable and configure a firewall. Firewalls act as a barrier between the general traffic of the internet and your machine. They look at traffic headed in and out of your server, and decide if it should allow the information to be delivered.

They do this by checking the traffic in question against a set of rules that are configured by the user. Usually, a server will only be using a few specific networking ports for legitimate services. The rest of the ports are unused, and should be safely protected behind a firewall, which will deny all traffic destined for these locations.

This allows you to drop data that you are not expecting and even conditionalize the usage of your real services in some cases. Sane firewall rules provide a good foundation to network security.

There are quite a few firewall solutions available. We’ll briefly discuss some of the more popular options below.

### UFW

* * *

UFW stands for uncomplicated firewall. Its goal is to provide good protection without the complicated syntax of other solutions.

UFW, as well as most Linux firewalls, is actually a front-end to control the netfilter firewall included with the Linux kernel. This is usually a simple firewall to use for people not already familiar with Linux firewall solutions and is generally a good choice.

You can learn [how to enable and configure the UFW firewall](https://www.digitalocean.com/community/articles/how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server) and find out more by clicking this link.

### IPTables

* * *

Perhaps the most well-known Linux firewall solution is iptables. IPTables is another component used to administer the netfilter firewall included in the Linux kernel. It has been around for a long time and has undergone intense security audits to ensure its safety. There is a version of iptables called ip6tables for creating IPv6 restrictions.

You will likely come across iptables configurations during your time administering Linux machines. The syntax can be complicated to grasp at first, but it is an incredibly powerful tool that can be configured with very flexible rule sets.

You can learn more about [how to implement some iptables firewall rules on Ubuntu or Debian systems](https://www.digitalocean.com/community/articles/how-to-set-up-a-firewall-using-ip-tables-on-ubuntu-12-04) here, or learn [how to use iptables on CentOS/Fedora/RHEL-based distros](https://www.digitalocean.com/community/articles/how-to-setup-a-basic-ip-tables-configuration-on-centos-6) here.

### IP6Tables

As mentioned above, the `iptables` is used to manipulate the tables that contain IPv4 rules. If you have IPv6 enabled on your server, you will need to also pay attention to the IPv6 equivalent: `ip6tables`.

The netfilter firewall that is included in the Linux kernel keeps IPv4 and IPv6 traffic completely separate. These are stored in different tables. The rules that dictate the ultimate fate of a packet are determined by the protocol version that is being used.

What this means to the server’s administer is that a separate ruleset must be maintained when version 6 is enabled. The `ip6tables` command shares the same syntax as the `iptables` command, so implementing the same set of restrictions in the version 6 table is usually straight forward. You must be sure match traffic directed at your IPv6 addresses however, for this to work correctly.

### NFTables

* * *

Although iptables has long been the standard for firewalls in a Linux environment, a new firewall called nftables has recently been added into the Linux kernel. This is a project by the same team that makes iptables, and is intended to eventually replace iptables.

The nftables firewall attempts to implement more readable syntax than that found its iptables predecessor, and implements IPv4 and IPv6 support into the same tool. While most versions of Linux at this time do not ship with a kernel new enough to implement nftables, it will soon be very commonplace, and you should try to familiarize yourself with its usage.

## Using SSH to Securely Login Remotely

* * *

When administering a server where you do not have local access, you will need to log in remotely. The standard, secure way of accomplishing this on a Linux system is through a protocol known called SSH, which stands for secure shell.

SSH provides end-to-end encryption, the ability to tunnel insecure traffic over a secure connection, X-forwarding (graphical user interface over a network connection), and much more. Basically, if you do not have access to a local connection or out-of-band management, SSH should be your primary way of interacting with your machine.

While the protocol itself is very secure and has undergone extensive research and code review, your configuration choices can either aid or hinder the security of the service. We will discuss some options below.

### Password vs SSH-Key Logins

* * *

SSH has a flexible authentication model that allows you to sign in using a number of different methods. The two most popular choices are password and SSH-key authentication.

While password authentication is probably the most natural model for most users, it is also the less secure of these two choices. Password logins allow a potential intruder to continuously guess passwords until a successful combination is found. This is known as brute-forcing and can easily be automated by would-be attackers with modern tools.

SSH-keys, on the other hand, operate by generating a secure key pair. A public key is created as a type of test to identify a user. It can be shared publicly without issues, and cannot be used for anything other than identifying a user and allowing a login to the user with the matching private key. The private key should be kept secret and is used to pass the test of its associated public key.

Basically, you can add your public SSH key on a server, and it will allow you to login by using the matching private key. These keys are so complex that brute-forcing is not practical. Furthermore, you can optionally add long passphrases to your key that adds even more security.

To learn more about [how to use SSH](https://www.digitalocean.com/community/articles/how-to-use-ssh-to-connect-to-a-remote-server-in-ubuntu) click here, and check out this link to learn [how to set up SSH keys on your server](https://www.digitalocean.com/community/articles/how-to-set-up-ssh-keys--2).

### Implement fail2ban to Ban Malicious IP Addresses

* * *

One step that will help with the general security of your SSH configuration is to implement a solution like fail2ban. Fail2ban is a service that monitors log files in order to determine if a remote system is likely not a legitimate user, and then temporarily ban future traffic from the associated IP address.

Setting up a sane fail2ban policy can allow you to flag computers that are continuously trying to log in unsuccessfully and add firewall rules to drop traffic from them for a set period of time. This is an easy way of hindering often used brute force methods because they will have to take a break for quite a while when banned. This usually is enough to discourage further brute force attempts.

You can learn [how to implement a fail2ban policy on Ubuntu](https://www.digitalocean.com/community/articles/how-to-protect-ssh-with-fail2ban-on-ubuntu-12-04) here. There are similar guides for [Debian](https://www.digitalocean.com/community/articles/how-to-protect-ssh-with-fail2ban-on-debian-7) and [CentOS](https://www.digitalocean.com/community/articles/how-to-protect-ssh-with-fail2ban-on-centos-6) here.

## Implement an Intrusion Detection System to Detect Unauthorized Entry

* * *

One important consideration to keep in mind is developing a strategy for detecting unauthorized usage. You may have preventative measures in place, but you also need to know if they’ve failed or not.

An intrusion detection system, also known as an IDS, catalogs configuration and file details when in a known-good state. It then runs comparisons against these recorded states to find out if files have been changed or settings have been modified.

There are quite a few intrusion detection systems. We’ll go over a few below.

### Tripwire

* * *

One of the most well-known IDS implementations is tripwire. Tripwire compiles a database of system files and protects its configuration files and binaries with a set of keys. After configuration details are chosen and exceptions are defined, subsequent runs notify of any alterations to the files that it monitors.

The policy model is very flexible, allowing you to shape its properties to your environment. You can then configure tripwire runs via a cron job and even implement email notifications in the event of unusual activity.

Learn more about [how to implement tripwire](https://www.digitalocean.com/community/articles/how-to-use-tripwire-to-detect-server-intrusions-on-an-ubuntu-vps) here.

### Aide

* * *

Another option for an IDS is Aide. Similar to tripwire, Aide operates by building a database and comparing the current system state to the known-good values it has stored. When a discrepancy arises, it can notify the administrator of the problem.

Aide and tripwire both offer similar solutions to the same problem. Check out the documentation and try out both solutions to find out which you like better.

For a guide on [how to use Aide as an IDS](https://www.digitalocean.com/community/articles/how-to-install-aide-on-a-digitalocean-vps), check here.

### Psad

* * *

The psad tool is concerned with a different portion of the system than the tools listed above. Instead of monitoring system files, psad keeps an eye on the firewall logs to try to detect malicious activity.

If a user is trying to probe for vulnerabilities with a port scan, for instance, psad can detect this activity and dynamically alter the firewall rules to lock out the offending user. This tool can register different threat levels and base its response on the severity of the problem. It can also optionally email the administrator.

To learn [how to use psad as a network IDS](https://www.digitalocean.com/community/articles/how-to-use-psad-to-detect-network-intrusion-attempts-on-an-ubuntu-vps), follow this link.

### Bro

* * *

Another option for a network-based IDS is Bro. Bro is actually a network monitoring framework that can be used as a network IDS or for other purposes like collecting usage stats, investigating problems, or detecting patterns.

The Bro system is divided into two layers. The first layer monitors activity and generates what it considers events. The second layer runs the generated events through a policy framework that dictates what should be done, if anything, with the traffic. It can generate alerts, execute system commands, simply log the occurrence, or take other paths.

To find out [how to use Bro as an IDS](https://www.digitalocean.com/community/articles/how-to-install-bro-ids-2-2-on-ubuntu-12-04), click here.

### RKHunter

* * *

While not technically an intrusion detection system, rkhunter operates on many of the same principles as host-based intrusion detection systems in order to detect rootkits and known malware.

While viruses are rare in the Linux world, malware and rootkits are around that can compromise your box or allow continued access to a successful exploiter. RKHunter downloads a list of known exploits and then checks your system against the database. It also alerts you if it detects unsafe settings in some common applications.

You can check out this article to learn [how to use RKHunter on Ubuntu](https://www.digitalocean.com/community/articles/how-to-use-rkhunter-to-guard-against-rootkits-on-an-ubuntu-vps).

## General Security Advice

* * *

While the above tools and configurations can help you secure portions of your system, good security does not come from just implementing a tool and forgetting about it. Good security manifests itself in a certain mindset and is achieved through diligence, scrutiny, and engaging in security as a process.

There are some general rules that can help set you in the right direction in regards to using your system securely.

### Pay Attention to Updates and Update Regularly

* * *

Software vulnerabilities are found all of the time in just about every kind of software that you might have on your system. Distribution maintainers generally do a good job of keeping up with the latest security patches and pushing those updates into their repositories.

However, having security updates available in the repository does your server no good if you have not downloaded and installed the updates. Although many servers benefit from relying on stable, well-tested versions of system software, security patches should not be put off and should be considered critical updates.

Most distributions provide security mailing lists and separate security repositories to only download and install security patches.

### Take Care When Downloading Software Outside of Official Channels

* * *

Most users will stick with the software available from the official repositories for their distribution, and most distributions offer signed packages. Users generally can trust the distribution maintainers and focus their concern on the security of software acquired outside of official channels.

You may choose to trust packages from your distribution or software that is available from a project’s official website, but be aware that unless you are auditing each piece of software yourself, there is risk involved. Most users feel that this is an acceptable level of risk.

On the other hand, software acquired from random repositories and PPAs that are maintained by people or organizations that you don’t recognize can be a huge security risk. There are no set rules, and the majority of unofficial software sources will likely be completely safe, but be aware that you are taking a risk whenever you trust another party.

Make sure you can explain to yourself why you trust the source. If you cannot do this, consider weighing your security risk as more of a concern than the convenience you’ll gain.

### Know your Services and Limit Them

* * *

Although the entire point of running a server is likely to provide services that you can access, limit the services running on your machine to those that you use and need. Consider every enabled service to be a possible threat vector and try to eliminate as many threat vectors as you can without affecting your core functionality.

This means that if you are running a headless (no monitor attached) server and don’t run any graphical (non-web) programs, you should disable and probably uninstall your X display server. Similar measures can be taken in other areas. No printer? Disable the “lp” service. No Windows network shares? Disable the “samba” service.

You can discover which services you have running on your computer through a variety of means. This article covers [how to detect enabled services](https://www.digitalocean.com/community/articles/how-to-migrate-linux-servers-part-1-system-preparation) under the “create a list of requirements” section.

### Do Not Use FTP; Use SFTP Instead

* * *

This might be a hard one for many people to come to terms with, but FTP is a protocol that is inherently insecure. All authentication is sent in plain-text, meaning that anyone monitoring the connection between your server and your local machine can see your login details.

There are only very few instances where FTP is probably okay to implement. If you are running an anonymous, public, read-only download mirror, FTP is a decent choice. Another case where FTP is an okay choice is when you are simply transferring files between two computers that are behind a NAT-enabled firewall, and you trust your network is secure.

In almost all other cases, you should use a more secure alternative. The SSH suite comes complete with an alternative protocol called SFTP that operates on the surface in a similar way, but it based on the same security of the SSH protocol.

This allows you to transfer information to and from your server in the same way that you would traditionally use FTP, but without the risk. Most modern FTP clients can also communicate with SFTP servers.

To learn [how to use SFTP to transfer files securely](https://www.digitalocean.com/community/articles/how-to-use-sftp-to-securely-transfer-files-with-a-remote-server), check out this guide.

### Implement Sensible User Security Policies

* * *

There are a number of steps that you can take to better secure your system when administering users.

One suggestion is to disable root logins. Since the root user is present on any POSIX-like systems and it is an all-powerful account, it is an attractive target for many attackers. Disabling root logins is often a good idea after you have configured sudo access, or if you are comfortable using the su command. Many people disagree with this suggestion, but examine if it is right for you.

It is possible to disable remote root logins within the SSH daemon or to disable local logins, you can make restrictions in the `/etc/securetty` file. You can also set the root user’s shell to a non-shell to disable root shell access and set up PAM rules to restrict root logins as well. RedHat has a great article on [how to disable root logins](https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_Linux/4/html/Security_Guide/s2-wstation-privileges-noroot.html).

Another good policy to implement with user accounts is creating unique accounts for each user and service, and give them only the bare minimum permissions to get their job done. Lock down everything that they don’t need access to and take away all privileges short of crippling them.

This is an important policy because if one user or service gets compromised, it doesn’t lead to a domino affect that allows the attacker to gain access to even more of the system. This system of compartmentalization helps you to isolate problems, much like a system of bulkheads and watertight doors can help prevent a ship from sinking when there is a hull breach.

In a similar vein to the services policies we discussed above, you should also take care to disable any user accounts that are no longer necessary. This may happen when you uninstall software, or if a user should no longer have access to the system.

### Pay Attention to Permission Settings

* * *

File permissions are a huge source of frustration for many users. Finding a balance for permissions that allow you to do what you need to do while not exposing yourself to harm can be difficult and demands careful attention and thought in each scenario.

Setting up a sane umask policy (the property that defines default permissions for new files and directories) can go a long way in creating good defaults. You can learn about [how permissions work and how to adjust your umask value](https://www.digitalocean.com/community/articles/linux-permissions-basics-and-how-to-use-umask-on-a-vps) here.

In general, you should think twice before setting anything to be world-writeable, especially if it is accessible in any way to the internet. This can have extreme consequences. Additionally, you should not set the SGID or SUID bit in permissions unless you absolutely know what you are doing. Also, check that your files have an owner and a group.

Your file permissions settings will vary greatly based on your specific usage, but you should always try to see if there is a way to get by with fewer permissions. This is one of the easiest things to get wrong and an area where there is a lot of bad advice floating around on the internet.

### Regularly Check for Malware on your Servers

* * *

While Linux is generally less targeted by Malware than Windows, it is by no means immune to malicious software. In conjunction with implementing an IDS to detect intrusion attempts, scanning for malware can help identify traces of activity that indicate that illegitimate software is installed on your machine.

There are a number of malware scanners available for Linux systems that can be used to regularly validate the integrity of your servers. Linux Malware Detect, also known as `maldet` or LMD, is one popular option that can be easily installed and configured to scan for known malware signatures. It can be run manually to perform one-off scans and can also be daemonized to run regularly scheduled scans. Reports from these scans can be emailed to the server administrators.

## How To Secure the Specific Software you are Using

* * *

Although this guide is not large enough to go through the specifics of securing every kind of service or application, there are many tutorials and guidelines available online. You should read the security recommendations of every project that you intend to implement on your system.

Furthermore, popular server software like web servers or database management systems have entire websites and databases devoted to security. In general, you should read up on and secure every service before putting it online.

You can check our [security section](https://www.digitalocean.com/community/community_tags/security) for more specific advice for the software you are using.

## Conclusion

* * *

You should now have a decent understanding of general security practices you can implement on your Linux server. While we’ve tried hard to mention many areas of high importance, at the end of the day, you will have to make many decisions on your own. When you administer a server, you have to take responsibility for your server’s security.

This is not something that you can configure in one quick spree in the beginning, it is a process and an ongoing exercise in auditing your system, implementing solutions, evaluating logs and alerts, reassessing your needs, etc. You need to be vigilant in protecting your system and always be evaluating and monitoring the results of your solutions.

By Justin Ellingwood
