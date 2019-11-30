---
author: Brian Boucheron
date: 2017-07-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-let-s-encrypt
---

# An Introduction to Let's Encrypt

## Introduction

[Let’s Encrypt](https://letsencrypt.org/) is an open and automated certificate authority that uses the [ACME (Automatic Certificate Management Environment )](https://ietf-wg-acme.github.io/acme/draft-ietf-acme-acme.html) protocol to provide free TLS/SSL certificates to any compatible client. These certificates can be used to encrypt communication between your web server and your users. There are dozens of clients available, written in various programming languages, and many integrations with popular administrative tools, services, and servers.

The most popular ACME client, [Certbot](https://certbot.eff.org/), is now developed by [the Electronic Frontier Foundation](https://www.eff.org/). In addition to verifying domain ownership and fetching certificates, Certbot can automatically configure TLS/SSL on both [Apache](https://httpd.apache.org/) and [Nginx](https://nginx.org/) web servers.

This tutorial will briefly discuss certificate authorities and how Let’s Encrypt works, then review a few popular ACME clients.

## What is a Certificate Authority?

Certificate authorities (CAs) are entities that cryptographically sign TLS/SSL certificates to vouch for their authenticity. Browsers and operating systems have a list of trusted CAs that they use to verify site certificates.

Until recently, most CAs were commercial operations that charged money for their verification and signing services. Let’s Encrypt has made this process free for users by completely automating the procedure, and by relying on sponsorship and donations to fund the necessary infrastructure.

For more information on certificates and the different types of certificate authorities, you can read “[A Comparison of Let’s Encrypt, Commercial and Private Certificate Authorities, and Self-Signed SSL Certificates](a-comparison-of-let-s-encrypt-commercial-and-private-certificate-authorities-and-self-signed-ssl-certificates).”

Next, we’ll look at how Let’s Encrypt does automated domain verification.

## How Let’s Encrypt Works

Let’s Encrypt’s ACME protocol defines how clients communicate with its servers to request certificates, verify domain ownership, and download certificates. It is currently in the process of becoming an official [IETF](https://www.ietf.org/) standard.

Let’s Encrypt offers _domain-validated_ certificates, meaning they have to check that the certificate request comes from a person who actually controls the domain. They do this by sending the client a unique token, and then making a web or DNS request to retrieve a key derived from that token.

For example, with the HTTP-based challenge, the client will compute a key from the unique token and an account token, then place the results in a file to be served by the web server. The Let’s Encrypt servers then retrieve the file at `http://example.com/.well-known/acme-challenge/token`. If the key is correct, the client has proven it can control resources on `example.com`, and the server will sign and return a certificate.

The ACME protocol defines multiple challenges your client can use to prove domain ownership. The HTTPS challenge is similar to HTTP, except instead of a text file, the client will provision a self-signed certificate with the key included. The DNS challenge looks for the key in a DNS TXT record.

## The Certbot Let’s Encrypt Client

Certbot is by far the most popular Let’s Encrypt client. It is included in most major Linux distributions, and includes convenient automatic configuration capabilities for Apache and Nginx. Once installed, fetching a certificate and updating your Apache configuration can be done like so:

    sudo certbot --apache -d www.example.com

Certbot will ask a few questions, run the challenge, download certificates, update your Apache config, and reload the server. You should then be able to navigate to `https://www.example.com` with your web browser. A green lock will appear indicating that the certificate is valid and the connection is encrypted.

Because Let’s Encrypt certificates are only valid for ninety days, it’s important to set up an automated renewal process. The following command will renew all certificates on a machine:

    sudo certbot renew

Put the above command in a crontab to run it every day, and certificates will be automatically renewed thirty days before they expire. If a certificate was initially created with the `--apache` or `--nginx` options, Certbot will reload the server after a successful renewal.

If you’d like to learn more about cron and crontabs, please refer to the tutorial “[How To Use Cron To Automate Tasks](how-to-use-cron-to-automate-tasks-on-a-vps).”

## Other Clients

Because the ACME protocol is open and well-documented, many alternate clients have been developed. Let’s Encrypt maintains a [list of ACME clients](https://letsencrypt.org/docs/client-options/) on their website. Most of the other clients don’t have the automatic web server configuration features of Certbot, but they have other features that may appeal to you:

- There is a client written in most every programming language, including shell scripts, Go, and Node.js. This could be important if you’re creating certificates in a constrained environment and would rather not include Python and other Certbot dependencies
- Some clients can run without **root** privileges. It’s generally a good idea to run the least amount of privileged code possible
- Many clients can automate the DNS-based challenge by using your DNS provider’s API to create the appropriate TXT record automatically. The DNS challenge enables some trickier use-cases such as encrypting web servers that are not publicly accessible.
- Some clients are actually integrated into web servers, reverse proxies, or load balancers, making it extra easy to configure and deploy

Some of the more popular clients are:

- [lego](https://github.com/xenolf/lego): Written in Go, lego is a one-file binary install, and supports many DNS providers when using the DNS challenge
- [acme.sh](https://github.com/Neilpang/acme.sh): acme.sh is a simple shell script that can run in unprivileged mode, and also interact with 30+ DNS providers
- [Caddy](https://caddyserver.com/): Caddy is a full web server written in Go with built-in support for Let’s Encrypt.

Many more clients are available, and many other servers and services are automating TLS/SSL setup by integrating Let’s Encrypt support.

## Conclusion

We’ve gone over the basics of how Let’s Encrypt works, and discussed some of the client software available. If you’d like more detailed instructions on using Let’s Encrypt with various software, the following tutorials are a good place to start:

- [How To Secure Apache with Let’s Encrypt on Ubuntu 16.04](how-to-secure-apache-with-let-s-encrypt-on-ubuntu-16-04)
- [How To Secure Nginx with Let’s Encrypt on Ubuntu 16.04](how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-16-04)
- [How To Host a Website with Caddy on Ubuntu 16.04](how-to-host-a-website-with-caddy-on-ubuntu-16-04)
