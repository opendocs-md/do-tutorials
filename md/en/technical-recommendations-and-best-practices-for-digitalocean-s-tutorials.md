---
author: The DigitalOcean Content Team
date: 2017-02-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/technical-recommendations-and-best-practices-for-digitalocean-s-tutorials
---

# Technical Recommendations and Best Practices for DigitalOcean's Tutorials

## Introduction

This guide is an effort to summarize established best practices and strong recommendations for authors of DigitalOcean tutorials. It is intended to provide a foundation for consistency, technical correctness, and ease of use in DigitalOcean’s instructional material.

This is by nature both a work in progress and an opinionated document, based on the growing experience of in-house technical writers and editors, community managers, and engineers. &nbsp;Its recommendations are subject to change, and are written specifically for educational content with a broad range of readers and end-users in mind.

## Software Sources and Installation

### Preferred Sources

In rough, descending order of preference, use the following installation mechanisms:

1. The **project recommended method** , when evaluated to be best. Many projects change quickly and recommend going beyond the official repositories, but some installations (like `curl | bash` patterns) require a judgement call on whether or not to use them.
2. The **official package repositories** for the current distribution and release.
3. **Language-specific official packages** (NPM, CPAN, PIP, RubyGems, Composer, etc.)
4. **Project-specific package repositories** (e.g. Nginx provides its own repos for up-to-date versions) or, on Ubuntu, a trusted PPA. Make sure these are from a well-trusted source, like the project’s developers or the Debian/Ubuntu package maintainers.
5. **Binaries from the project’s GitHub releases page** or a similar official web source.
6. **`wget` or `curl` install scripts** piped to the shell, with an appropriate warning about inspecting scripts.

### Preferred Installation Locations

In general, avoid unnecessary complication. For unpackaged software installed from source or binaries, you should generally accept the default installation prefix unless it’s very unusual or introduces conflicts.

An init script, conforming to official recommendations for the distribution, should be given for service-oriented software, if not provided by the package or other installation method.

On Linux systems, put self-contained binaries or directories in `/opt` and standalone scripts in `/usr/local/bin`.

## Software and System Maintenance

Ubuntu and Debian systems should have `unattended-upgrades` with at least security updates installed and configured. We recommend no auto-reboot or auto-update all, given context.

We generally recommend `sudo apt-get dist-upgrade` over `sudo apt-get upgrade`, given a close look at the proposed changes to make sure nothing destructive is going through. The two commands are very similar, but using `upgrade` can be less predictable because some changes are held back. Holding certain packages back can lead to version mismatches that might cause issues with production systems.  
We’ll continue to use `apt-get` on Ubuntu 16.04 because of a lack of documentation for `apt` and some turbulence about the distribution’s preferred package manager.

## Service Management

Make sure to use native init system commands, even when legacy compatibility commands are available. For instance, use `sudo systemctl start [service_name]` even though `sudo service [service_name] start` will work.

Provide information about how to enable or disable the service from starting at boot. Indicate how to inspect outcome of service-related commands when not clearly indicated by the interface (`journalctl -u`, `systemctl status`, etc).

Prefer restarts over reloads for services as a rule of thumb. In most cases, it’s more important to ensure a known state than avoid a split-second service interruption, and restarts are also more useful in the case of a complete service failure.

## Bootstrapping systems

Unless it’s part of a config management workflow, prefer user-data scripts, and prefer cloudinit scripts to bash scripts in user-data in most cases.

## Logging and Troubleshooting

Explain where and how to access logs for installed services. &nbsp;Where relevant, explain `systemctl` and `journalctl` commands for checking service status and log output. Where possible, offer concise suggestions for diagnosing common failure cases.

Make sure to handle log rotation for any cases where it’s not handled by packages or other installation mechanisms.

For following plaintext log files, use `tail -F`, not `tail -f`, as the latter will not track a file across renames and might cause confusion if logs are rotated while a user is watching them.

## User and Group Management

Create `sudo` users instead of using root directly. &nbsp;Reference the appropriate initial server setup guides which explain this task as a prerequisite.

On Debian-based distributions, add and remove users with `adduser sammy` and `deluser --remove-home sammy` respectively; on RHEL-based distributions, use `adduser sammy` (set a password with `passwd sammy` if necessary) and `userdel -r sammy`.

Grant `sudo` privileges with `usermod -aG sudo sammy` on Ubuntu. CentOS is a little more complicated. Modern versions use `usermod -aG wheel sammy`, but some versions require `visudo` to uncomment `wheel` group permissions first. Specifically, on CentOS 5, `sudo` needs to be installed and the **wheel** group needs to be uncommented with `visudo`; on CentOS 6, `sudo` is already installed, but **wheel** needs to be uncommented; CentOS 7 has `sudo` and the **wheel** group is already set up.

When using privilege escalated commands, make sure to test them as written. To pass environment variables through `sudo`, use `sudo -E command_to_run` (if trusted with entire environment) or `sudo FOO=BAR command_to_run`. For instances that require a root shell, use `sudo -i`. For instances that require redirection, use `tee -a` to append to rather than replace the destination file: `[sudo] command_to_run | sudo tee [-a] file_to_change`.

## Preferred Tools

For interactive shells, assume Bash on GNU/Linux systems, mentioned explicitly when relevant. On FreeBSD, use tcsh, as it’s available out of the box and has useful features.

For text editors, we include the copy “use [preferred] or your favorite text editor”, and include the following beginner-friendly editors in commands for those copy and pasting. On Linux, we default to `nano`; on FreeBSD, we default to `ee`. vi(m) is permissible, but avoid it in introductory topics where it might present a stumbling block for beginners.

For file transfer, we generally recommend `sftp` in most cases for its interactive and scp-alike uses, though it lacks push functionality, so `scp` is acceptable as well. `rsync` is useful for backups and large transfers (or many small files). Do not use FTP under any circumstances. We also make an effort to standardize on `curl` over `wget` because of its robustness. `wget`’s advantage is mostly recursive download (i.e. a special use case which is not common for our kind of content).

On machines that ship with `iproute2` utilities, we prefer them to the `net-tools` suite, which is [considered obsolete](http://lartc.org/howto/lartc.iproute2.html). In general, `iproute2` utilities like `ss` will have better support for multiple interfaces, IPv6, new kernel functionality, etc. So likewise, we should use `ip route` over `route`, `ip addr show` over `ifconfig`, etc. Sometimes the older utilities output is a bit cleaner by default, but the output itself is a bit less trustworthy since they don’t handle edge cases as well. When possible, we will control the more verbose output using available flags.

## Scripting

Within the context of systems administration tutorials, generally avoid lengthy custom scripts and long shell scripts.

Author-written scripts (and possibly other resources) should live in a per-article repository in the do-community GitHub account with a link back to the published tutorial. Follow good scripting practices in general. For example, put any variables the user will have to fill in at the top of the script, preferably in a well marked section. Also make sure to comment assiduously; the body of a script inlined in a DO tutorial shouldn’t function as a black box. Users should be able to suss out meaning by reading it through.

Prefer `/bin/sh` to `bash` and avoid Bash-specific features when portability or cross-platform reuse are a concern. Use the shell and coreutils/standard Unix tools for small tasks; avoid introducing new dependencies purely for glue-language tasks unless the benefits are substantial. Prefer `#!/usr/bin/env interpreter` to `#!/path/to/interpreter`.

In general, use `cron` for scheduling recurring tasks, but systemd timers are also acceptable.

## Filesystem Locations

When downloading scripts or data, ensure that the user is in a writeable directory or paths are explicitly specified. For files which should be available for reference or reuse, use the user’s home directory, unless they belong in some standard well-defined path elsewhere on the filesystem (such as `/opt` or `/etc`). For throwaway files, use `/tmp`.

## Web Servers

We recommend the Debian-style configuration directories for distributions that don’t structure it that way by default. &nbsp;Always test configuration changes (Apache uses `sudo apachectl configtest`, and Nginx uses `sudo nginx -t`).  
`/var/www/html` should be used as the document root for all web servers. Nginx’s `/usr/share/nginx/html` default should be changed because that directory is owned by and can potentially be modified by package updates. &nbsp;This is no longer a problem in Ubuntu 16.04, but will remain relevant for previous releases.

Moving forward, prefer creating new Apache Virtual Host files or Nginx server block files rather than modifying the provided default files. This helps avoid some common mistakes and maintains the default files as the fallback configuration as intended.

## Security

Encrypt and authenticate all connections between systems. Do not encourage (explicitly or implicitly) users to send credentials or transmit non-public data in the clear.

Specifically, passwords and key material must not be transmitted over unsecured connections. Database connections, logging, cluster management, and other services should ideally be encrypted at all times. Web-based control panels must be [served over HTTPS connections](https://www.digitalocean.com/community/tags/let-s-encrypt?type=tutorials), and TLS/SSL should be used for services where it’s supported. Public-facing services like plain HTTP are permissible, as users may still want or need to offer them, but should be strongly discouraged in the general case, especially for dynamic content.

Avoid practices which constitute low- benefit security through obscurity or theatrics, like changing the default SSH port. Do configure a firewall. Our distro-specific recommendations are `ufw` for Ubuntu, `iptables` for Debian, and `firewalld` for CentOS. However, `iptables` is most consistent across platforms, and has many tools that hook into it.

### SSH

We recommend not changing the default SSH port in line with avoiding low-benefit security-through-obscurity practices. Changing the port may be useful to cut cruft out of logs, but this should only be done in specific situations where that is a primary concern.

Disable password authentication and use key-only authentication for root or, alternatively, disable root login completely. Make sure to use strong SSH keys, at least 2048-bit RSA but recommended 4096; ECDSA is no longer recommended for technical reasons, and Ed25519 and elliptic curve algorithms are not widely supported enough.

Use passphrases for any interactive keys, but not for non-interactive processes. Set up or copy and change ownership on SSH keys from the root account to the user home directory. Install [fail2ban](https://www.digitalocean.com/community/search?q=fail2ban) where it’s practical.

Note that while SSH Agent Forwarding is necessary for normal workflows on platforms like CoreOS, it comes with some security concerns. Essentially, anyone with permissions on your host will be able to use the forwarding socket to connect to your local ssh-agent.

### SSL/TLS

We strongly encourage the use of Let’s Encrypt for ease of use, and recommend TLS. Do use strong SSL security; look at [https://cipherli.st/](https://cipherli.st/) (both modern and legacy recommendations).

For hosts without a domain name, we suggest a self-signed certificate of adequate strength. Again, look at [https://cipherli.st/](https://cipherli.st/) plus the self-signed cert creation used in guides like [this Self-Signed Certification on Nginx guide](how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04). Set up a strong Diffie-Hellman key when enabling encryption, as in [Self-Signed SSL Certifications on Apache](how-to-create-a-self-signed-ssl-certificate-for-apache-in-ubuntu-16-04) and [Nginx](how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-16-04).

### VPN

We recommend VPNs as a solution for general encrypted communication between servers. VPNs become increasingly valuable when multiple services need to be protected between servers; instead of encrypting each service individually, all internal communication can be piped to the VPN. This is particularly useful if the services in question don’t support native encryption.

We generally recommend Tinc over OpenVPN for server-to-server communication. You can read [this article on Ansible and Tinc](how-to-use-ansible-and-tinc-vpn-to-secure-your-server-infrastructure) for more details and implementation.

## Conclusion

This is inherently an opinionated, living document, and will be updated often. Tech changes quickly and we at DigitalOcean do our best to keep up, but if you notice any errors or have feedback, we’ll be monitoring the comments below.
