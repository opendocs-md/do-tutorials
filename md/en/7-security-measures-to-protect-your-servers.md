---
author: Justin Ellingwood
date: 2015-03-05
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/7-security-measures-to-protect-your-servers
---

# 7 Security Measures to Protect Your Servers

## Introduction

When setting up infrastructure, getting your applications up and running will often be your primary concern. However, making your applications to function correctly without addressing the security needs of your infrastructure could have devastating consequences down the line.

In this guide, we will talk about some basic security practices that are best to configure before or as you set up your applications.

## SSH Keys

SSH keys are a pair of cryptographic keys that can be used to authenticate to an SSH server as an alternative to password-based logins. A private and public key pair are created prior to authentication. The private key is kept secret and secure by the user, while the public key can be shared with anyone.

![SSH Keys diagram](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/7_security_measures/1-ssh-key-auth.png)

To configure the SSH key authentication, you must place the user’s public key on the server in a special directory. When the user connects to the server, the server will ask for proof that the client has the associated private key. The SSH client will use the private key to respond in a way that proves ownership of the private key. The server will then let the client connect without a password. To learn more about how SSH keys work, check out our article [here](understanding-the-ssh-encryption-and-connection-process).

### How Do They Enhance Security?

With SSH, any kind of authentication, including password authentication, is completely encrypted. However, when password-based logins are allowed, malicious users can repeatedly attempt to access the server. With modern computing power, it is possible to gain entry to a server by automating these attempts and trying combination after combination until the right password is found.

Setting up SSH key authentication allows you to disable password-based authentication. SSH keys generally have many more bits of data than a password, meaning that there are significantly more possible combinations that an attacker would have to run through. Many SSH key algorithms are considered uncrackable by modern computing hardware simply because they would require too much time to run through possible matches.

### How Difficult Is This to Implement?

SSH keys are very easy to set up and are the recommended way to log into any Linux or Unix server environment remotely. A pair of SSH keys can be generated on your machine and you can transfer the public key to your servers within a few minutes.

To learn about how to set up keys, follow [this guide](how-to-set-up-ssh-keys--2). If you still feel that you need password authentication, consider implementing a solution like [fail2ban](how-to-install-and-use-fail2ban-on-ubuntu-14-04) on your servers to limit password guesses.

## Firewalls

A firewall is a piece of software (or hardware) that controls what services are exposed to the network. This means blocking or restricting access to every port except for those that should be publicly available.

![Firewall diagram](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/7_security_measures/2-firewall.png)

On a typical server, a number services may be running by default. These can be categorized into the following groups:

- Public services that can be accessed by anyone on the internet, often anonymously. A good example of this is a web server that might allow access to your site.
- Private services that should only be accessed by a select group of authorized accounts or from certain locations. An example of this may be a database control panel.
- Internal services that should be accessible only from within the server itself, without exposing the service to the outside world. For example, this may be a database that only accepts local connections.

Firewalls can ensure that access to your software is restricted according to the categories above. Public services can be left open and available to everyone and private services can be restricted based on different criteria. Internal services can be made completely inaccessible to the outside world. For ports that are not being used, access is blocked entirely in most configurations.

### How Do They Enhance Security?

Firewalls are an essential part of any server configuration. Even if your services themselves implement security features or are restricted to the interfaces you’d like them to run on, a firewall serves as an extra layer of protection.

A properly configured firewall will restrict access to everything except the specific services you need to remain open. Exposing only a few pieces of software reduces the attack surface of your server, limiting the components that are vulnerable to exploitation.

### How Difficult Is This to Implement?

There are many firewalls available for Linux systems, some of which have a steeper learning curve than others. In general though, setting up the firewall should only take a few minutes and will only need to happen during your server’s initial setup or when you make changes in what services are offered on your computer.

A simple choice is the [UFW firewall](how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server). Other options are to use [iptables](how-to-set-up-a-firewall-using-iptables-on-ubuntu-14-04) or the [CSF firewall](how-to-install-and-configure-config-server-firewall-csf-on-ubuntu).

## VPNs and Private Networking

Private networks are networks that are only available to certain servers or users. For example, DigitalOcean private networks enable [isolated communication between servers in the same account or team within the same region](digitalocean-private-networking-faq).   
A VPN, or virtual private network, is a way to create secure connections between remote computers and present the connection as if it were a local private network. This provides a way to configure your services as if they were on a private network and connect remote servers over secure connections.

![VPN diagram](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/7_security_measures/3-vpn.png)

### How Do They Enhance Security?

Utilizing private instead of public networking for internal communication is almost always preferable given the choice between the two. However, since other users within the data center are able to access the same network, you still must implement additional measures to secure communication between your servers.

Using a VPN is, effectively, a way to map out a private network that only your servers can see. Communication will be fully private and secure. Other applications can be configured to pass their traffic over the virtual interface that the VPN software exposes. This way, only services that are meant to be consumable by clients on the public internet need to be exposed on the public network.

### How Difficult Is This to Implement?

Utilizing private networks in a datacenter that has this capability is as simple as enabling the interface during your server’s creation and configuring your applications and firewall to use the private network. Keep in mind that data center-wide private networks share space with other servers that use the same network.

As for VPN, the initial setup is a bit more involved, but the increased security is worth it for most use-cases. Each server on a VPN must have the shared security and configuration data needed to establish the secure connection installed and configured. After the VPN is up and running, applications must be configured to use the VPN tunnel. To learn about setting up a VPN to securely connect your infrastructure, check out our [OpenVPN tutorial](how-to-secure-traffic-between-vps-using-openvpn).

## Public Key Infrastructure and SSL/TLS Encryption

Public key infrastructure, or PKI, refers to a system that is designed to create, manage, and validate certificates for identifying individuals and encrypting communication. SSL or TLS certificates can be used to authenticate different entities to one another. After authentication, they can also be used to established encrypted communication.

![SSL diagram](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/7_security_measures/4-ssl-tls.png)

### How Do They Enhance Security?

Establishing a certificate authority and managing certificates for your servers allows each entity within your infrastructure to validate the other members identity and encrypt their traffic. This can prevent man-in-the-middle attacks where an attacker imitates a server in your infrastructure to intercept traffic.

Each server can be configured to trust a centralized certificate authority. Afterwards, any certificate that the authority signs can be implicitly trusted. If the applications and protocols you are using to communicate support TLS/SSL encryption, this is a way of encrypting your system without the overhead of a VPN tunnel (which also often uses SSL internally).

### How Difficult Is This to Implement?

Configuring a certificate authority and setting up the rest of the public key infrastructure can involve quite a bit of initial effort. Furthermore, managing certificates can create an additional administration burden when new certificates need to be created, signed, or revoked.

For many users, implementing a full-fledged public key infrastructure will make more sense as their infrastructure needs grow. Securing communications between components using VPN may be a good stop gap measure until you reach a point where PKI is worth the extra administration costs.

## Service Auditing

Up until now, we have discussed some technology that you can implement to improve your security. However, a big portion of security is analyzing your systems, understanding the available attack surfaces, and locking down the components as best as you can.

Service auditing is a process of discovering what services are running on the servers in your infrastructure. Often, the default operating system is configured to run certain services at boot. Installing additional software can sometimes pull in dependencies that are also auto-started.

![Service auditing diagram](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/7_security_measures/5-service-audit.png)

Service auditing is a way of knowing what services are running on your system, which ports they are using for communication, and what protocols are accepted. This information can help you configure your firewall settings.

### How Does It Enhance Security?

Servers start many processes for internal purposes and to handle external clients. Each of these represents an expanded attack surface for malicious users. The more services that you have running, the greater chance there is of a vulnerability existing in your accessible software.

Once you have a good idea of what network services are running on your machine, you can begin to analyze these services. Some questions that you will want to ask yourself for each one are:

- Should this service be running?
- Is the service running on interfaces that it doesn’t needs to? Should it be bound to a single IP?
- Are your firewall rules structured to allow legitimate traffic pass to this service?
- Are your firewall rules blocking traffic that is not legitimate?
- Do you have a method of receiving security alerts about vulnerabilities for each of these services?

This type of service audit should be standard practice when configuring any new server in your infrastructure.

### How Difficult Is This to Implement?

Doing a basic service audit is incredibly simple. You can find out which services are listening to ports on each interface by using the `netstat` command. A simple example that shows the program name, PID, and addresses being used for listening for TCP and UDP traffic is:

    sudo netstat -plunt

You will see output that looks like this:

    Active Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address Foreign Address State PID/Program name
    tcp 0 0 0.0.0.0:22 0.0.0.0:* LISTEN 887/sshd        
    tcp 0 0 0.0.0.0:80 0.0.0.0:* LISTEN 919/nginx       
    tcp6 0 0 :::22 :::* LISTEN 887/sshd        
    tcp6 0 0 :::80 :::* LISTEN 919/nginx

The main columns you need to stay attention to are `Proto`, `Local Address`, and `PID/Program name`. If the address is `0.0.0.0`, then the service is accepting connections on all interfaces.

## File Auditing and Intrusion Detection Systems

File auditing is the process of comparing the current system against a record of the files and file characteristics of your system when it is a known-good state. This is used to detect changes to the system that may have been authorized.

![File audit diagram](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/7_security_measures/6-file-audit.png)

An intrusion detection system, or IDS, is a piece of software that monitors a system or network for unauthorized activity. Many host-based IDS implementations use file auditing as a method of checking whether the system has changed.

### How Do They Enhance Security?

Similar to the above service-level auditing, if you are serious about ensuring a secure system, it is very useful to be able to perform file-level audits of your system. This can be done periodically by the administrator or as part of an automated processes in an IDS.

These strategies are some of the only ways to be absolutely sure that your filesystem has not been altered by some user or process. For many reasons, intruders often wish to remain hidden so that they can continue to exploit the server for an extended period of time. They might replace binaries with compromised versions. Doing an audit of the filesystem will tell you if any of the files have been altered, allowing you to be confident in the integrity of your server environment.

### How Difficult Is This to Implement?

Implementing an IDS or conducting file audits can be quite an intensive process. The initial configuration involves telling the auditing system about any non-standard changes you’ve made to the server and defining paths that should be excluded to create a baseline reading.

It also makes day-to-day operations more involved. It complicates updating procedures as you will need to re-check the system prior to running updates and then recreate the baseline after running the update to catch changes to the software versions. You will also need to offload the reports to another location so that an intruder cannot alter the audit to cover their tracks.

While this may increase your administration load, being able to check your system against a known-good copy is one of the only ways of ensuring that files have not been altered without your knowledge. Some popular file auditing / intrusion detection systems are [Tripwire](how-to-use-tripwire-to-detect-server-intrusions-on-an-ubuntu-vps) and [Aide](how-to-install-aide-on-a-digitalocean-vps).

## Isolated Execution Environments

Isolating execution environments refers to any method in which individual components are run within their own dedicated space.

![Isolated environments diagram](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/7_security_measures/7-isolation.png)

This can mean separating out your discrete application components to their own servers or may refer to configuring your services to operate in `chroot` environments or containers. The level of isolation depends heavily on your application’s requirements and the realities of your infrastructure.

### How Do They Enhance Security?

Isolating your processes into individual execution environments increases your ability to isolate any security problems that may arise. Similar to how [bulkheads](http://en.wikipedia.org/wiki/Bulkhead_(partition)) and compartments can help contain hull breaches in ships, separating your individual components can limit the access that an intruder has to other pieces of your infrastructure.

### How Difficult Is This to Implement?

Depending on the type of containment you choose, isolating your applications can be relatively simple. By packaging your individual components in containers, you can quickly achieve some measure of isolation, but note that Docker does not consider its containerization a security feature.

Setting up a `chroot` environment for each piece can provide some level of isolation as well, but this also is not foolproof method of isolation as there are often ways of breaking out of a `chroot` environment. Moving components to dedicated machines is the best level of isolation, and in many cases may be the easiest, but may cost more for the additional machines.

## Conclusion

The strategies outlined above are only some of the enhancements you can make to improve the security of your systems. It is important to recognize that, while it’s better late than never, security measures decrease in their effectiveness the longer you wait to implement them. Security cannot be an afterthought and must be implemented from the start alongside the services and applications you are providing.
