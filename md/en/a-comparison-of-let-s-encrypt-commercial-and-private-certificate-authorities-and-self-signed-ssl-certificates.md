---
author: Brian Boucheron
date: 2017-06-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/a-comparison-of-let-s-encrypt-commercial-and-private-certificate-authorities-and-self-signed-ssl-certificates
---

# A Comparison of Let's Encrypt, Commercial and Private Certificate Authorities, and Self-Signed SSL Certificates

## Introduction

The push to get more and more web traffic secured with SSL encryption means that an increasing number of services and use-cases need a solution for obtaining the proper certificates. Whether it’s a public website, intranet traffic, or a staging server for your web app, you’ll need a certificate to protect your data and meet the modern security expectations of your users.

The main benefits of SSL connections revolve around _privacy_ and _data integrity_. Connections are private because the encryption prevents eavesdropping. Data integrity is ensured by cryptographically verifying that you’re connecting to the correct server (and not an imposter), and by verifying that individual messages are not tampered with in transit.

There are a few different ways you can obtain SSL certificates, and depending on your budget, audience, and a few other factors, you may choose between a commercial certificate authority, a new automated and free certificate authority, self-signed certificates, and your own private certificate authority. Let’s run through a comparison of these options, and discuss when it might be best to use each.

## Glossary

Before we begin, we’ll define some common terms used when discussing SSL security:

### Transport Layer Security (TLS)

Transport Layer Security is a new security protocol that replaces Secure Sockets Layer (SSL). Though it is more likely that a modern encrypted connection is using TLS, the SSL name has stuck around in popular language and is what we’ll use here.

### Certificate

In this article we’ll be referring to SSL _server certificates_ exclusively. Server certificates are presented by a web server whenever a new SSL connection is requested. They contain the name of the host the certificate is issued to (which should match the server you’re attempting to connect to) and are signed by a Certificate Authority to establish trust.

### Certificate Authority (CA)

Certificate authorities verify details about a domain owner’s request for SSL certificates, then – if everything checks out – issue and sign server certificates. Browsers and operating systems maintain a list of trusted certificate authorities. If a server certificate is signed by one of these trusted CAs, it will also be trusted.

### Domain Validation (DV)

A domain validated certificate will be issued to somebody who has proven they control the domain name requested for the certificate. This proof often takes the form of serving a unique token from your web server or DNS records, which the CA will check for before issuing the certificate.

### Organization Validation (OV)

An organization validated certificate means that the certificate authority also verified the company name and address in public databases. This information is put into the certificate, and is typically displayed only when the user clicks the green padlock icon to investigate further.

### Extended Validation (EV)

Extended validation is more thorough than domain or organization validation. EV certificates are issued after checking not only domain ownership, but also verifying the existence and location of the legal entity requesting the certificate, and that said entity controls the domain being verified.

Unlike DV and OV certificates, EV cannot be issued as a wildcard certificate.

EV certificates also get special treatment in web browsers. Whereas browsers typically denote a DV certificate with a green padlock icon, EV certificates also show a larger green bar containing the name of the organization it was issued to. This is intended to reduce phishing attacks, though some studies show that users tend not to notice when this green bar is missing.

### Wildcard Certificate

Instead of being issued for a specific fully qualified domain name ( **app.example.com** , for instance), wildcard certs are valid for a whole range of subdomain names. So a cert issued to **\*.example.com** would cover any subdomain of example.com such as **app.example.com** and **database.example.com**. The asterisk character is the _wildcard_, and can be substituted with any valid hostname.

### Certificate Revocation List (CRL)

SSL certificates can include information on how to access a certificate revocation list. Clients will download and check this list to make sure the certificate has not been revoked. CRLs have largely been replaced by OCSP responders.

### Online Certificate Status Protocol (OCSP)

The OCSP protocol is a replacement for CRLs, with the benefits of being more real-time and requiring less bandwidth. The general operation is similar: clients are to query the OCSP responder to check if a certificate has been revoked.

## Commercial Certificate Authorities

Commercial certificate authorities allow you to purchase DV, OV, and EV certificates. Some offer free Domain Validated certificates with certain restrictions (no wildcards, for instance).

- **Process:** Manual process for initial setup and renewal
- **Cost:** roughly $10–$1000
- **Validation:** DV, OV, and EV
- **Trust:** Trusted by default in most browsers and operating systems
- **Wildcard Certificates:** Yes
- **IP-only Certificates:** Some will issue certificates for **public** IP addresses
- **Expiration Period:** 1–3 years

Most commercial certificate authorities are trusted by default in most browsers. The process to renew is typically manual, so you must note your certificates’ expiration dates and remind yourself to renew on time.

Commercial CAs have traditionally been the only real option for obtaining certificates trusted by most major browsers. This has changed with new automated certificate authorities like Let’s Encrypt. Still, commercial CAs are the only way to get an EV certificate, and the only way to get a wildcard certificate that is automatically trusted by most browsers. They are also a good option if you need a certificate for a device that can’t run the automated Let’s Encrypt client (due to software incompatibility, or perhaps being a low-power embedded device).

Commercial certificate authorities often provide the option of additional support contracts, guarantees, and certification, which is important to some companies and industries.

## Let’s Encrypt

Let’s Encrypt provides an automated mechanism to request and renew free domain validated certificates. They’ve created a standard protocol – ACME – for interacting with the service to retrieve and renew certificates automatically. The official ACME client is called [Certbot](https://certbot.eff.org/), though many alternative clients exist.

- **Process:** Initial setup and renewal is automated. Only Apache and Nginx setup is automated with the official client, but certificates can be downloaded and used independent of any particular server software.
- **Cost:** Free
- **Validation:** DV only
- **Default:** Trusted by default in most browsers and operating systems
- **Wildcard Certificates:** No ([Planned for January 2018](https://letsencrypt.org/2017/07/06/wildcard-certificates-coming-jan-2018.html))
- **IP-only Certificates:** No
- **Expiration Period:** 90 days

Let’s Encrypt certificates are short-lived to encourage automated renewal and to reduce the time any compromised certificates could be abused by an attacker.

If you have a server that’s publicly accessible and has a valid domain name pointing to it, Let’s Encrypt could be a good option. Let’s Encrypt’s servers need to contact your web server or fetch a public DNS record to verify that you control the domain, so using it for a private server behind a firewall on your local network can be a little trickier. It’s still possible using Let’s Encrypt’s DNS-based authorization challenge though.

Let’s Encrypt will not provide certificates for a bare IP address.

If you need an EV certificate, or a wildcard certificate, Let’s Encrypt is not an option. Note that Let’s Encrypt can create a certificate with up to 100 hostnames on it, so it’s possible you don’t actually need a wildcard for your use case, you may just need a certificate that covers all of your existing subdomains.

Still, due to rate limits on the Let’s Encrypt API, if you have lots of subdomains, or dynamic subdomains that can be created on the fly, Let’s Encrypt may not be suitable.

## Self-Signed Certificates

It’s possible to use an SSL certificate that has been signed by its own private key, bypassing the need for a certificate authority altogether. This is called a self-signed certificate and is quite commonly suggested when setting up web apps for testing or for use by a limited number of tech-savvy users.

- **Process:** Manual certificate creation, no renewal mechanism
- **Cost:** Free
- **Validation:** DV and OV
- **Trust:** None by default. Each certificate must be manually marked as trusted, as there is no common CA involved
- **Wildcard Certificates:** Yes
- **IP-only Certificates:** Yes, any IP
- **Expiration Period:** Any

Self-signed certificates can be made with the `openssl` command that ships with the OpenSSL library. You can find the exact commands necessary, and more background on OpenSSL, in our tutorial [OpenSSL Essentials: Working with SSL Certificates, Private Keys and CSRs](openssl-essentials-working-with-ssl-certificates-private-keys-and-csrs).

Because a self-signed certificate is not signed by any trusted CA, you’ll need to manually mark the certificate as trusted, a process which is different in each browser and operating system. Thereafter, the certificate will act like any normal CA-signed certificate.

Self-signed certificates are good for one-off use when you only need to manually manage trust on a few clients, and don’t mind the fact that it can’t be revoked or renewed without more manual effort. This is often good enough for development and testing purposes, or for self-hosted web apps that only a few people will ever use.

## Private Certificate Authorities

It’s possible to make your own private certificate authority and use it to sign certificates. Your users will need to manually install and trust your private CA before any of its certificates are trusted.

- **Process:** Manual certificate creation and renewal, plus manual setup of the CA itself
- **Cost:** Free
- **Validation:** DV and OV
- **Trust:** None by default. You must manually distribute your private CA certificate to clients to establish trust
- **Wildcard Certificates:** Yes
- **IP-only Certificates:** Yes, any IP
- **Expiration Period:** Any

As with self-signed certificates you can create a private CA using the command line tools that come with the OpenSSL library, but some alternative interfaces have been developed to make the process easier. [tinyCA](https://tinyca.alioth.debian.org/) is a graphical interface for this process, and [caman](https://github.com/radiac/caman) is a command line program. Both make it easier to create a CA and then issue, renew, and revoke certificates.

A private CA is a good option if you have multiple certificates to create and can distribute and install your CA for your users manually. This probably limits you to internal use within an organization or small group of technically savvy users who can install the CA properly. Larger IT departments often have means to deploy CAs to their users automatically, making this solution more attractive to them.

Unlike self-signed certificates, where each certificate must be marked as trusted manually, you only have to install the private CA once. All certificates issued from that CA will then inherit that trust.

One downside is there’s a bit of overhead to running the CA, and it takes some know how to set up and maintain in a secure manner.

If proper revocation is important for your use, you’ll also need to maintain an HTTP server for the certificate revocation list, or an OCSP responder.

## Conclusion

We’ve reviewed a few different options for obtaining or creating SSL certificates. Whichever works best for your situation, adding SSL protection to is good for protecting the data, privacy, and security of your service and your users.

If you want to dive deeper into SSL and the options we’ve discussed, the following links may be helpful:

- The [OpenSSL documentation](https://www.openssl.org/docs/) describes the library and its commands in detail
- The [CA/Browser Forum](https://cabforum.org/) is where certificate authorities and browser vendors work out requirements and best practices for how CAs operate. This includes rules such as how long certificates should be valid for, and whether they should be issued for non-public domain names
- The [Let’s Encrypt CA](https://letsencrypt.org/) has more information about the ACME protocol
