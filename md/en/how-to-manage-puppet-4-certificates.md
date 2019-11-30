---
author: Melissa Anderson
date: 2016-12-13
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-manage-puppet-4-certificates
---

# How To Manage Puppet 4 Certificates

## A Puppet Cheat Sheet

Puppet is a configuration management tool that helps system administrators automate the provisioning, configuration and management of a server infrastructure. It’s usually run in master/agent mode where the master server manages the configuration of several agent nodes. Communication between the master and agents is granted and secured with client-verified HTTPS, which requires valid identifying SSL certificates. The Puppet master acts as the certificate authority for managing these certificates.

This cheat sheet-style guide provides a quick reference for using the `puppet cert` command to manage those certificates.

**How to Use This Guide:**

- This guide is in cheat sheet format with self-contained command-line snippets
- Jump to any section that is relevant to the task you are trying to complete.

**Note:** If `puppet` is not in your path, you will need to supply the full path to `puppet` in the commands below.

## Listing Certificate Requests

When Puppet agent servers come online, if everything is properly configured, they will present a certificate signing request to the Puppet master. These requests can be reviewed with the `puppet cert list` command.

### List all requests, signed and unsigned

To view all certificate requests, signed and unsigned, use the `--all` flag as follows:

    sudo puppet cert list --all

Signed requests are preceded by a plus (`+`) and unsigned requests are not. In the output below, `host2.example.com` has not been signed, while `host1` and `puppet` have:

    Output:+ "host1.example.com" (SHA256) 51:D8:7A:EB:40:66:74:FD:0A:03:5D:35:AA:4D:B3:FA:35:99:C2:A8:C9:01:83:34:F6:16:60:BB:46:1F:33:3F
      "host2.example.com" (SHA256) 3C:A9:96:3A:8D:24:5F:25:DB:FF:67:B5:22:B1:46:D9:89:F1:75:EC:BA:F2:D6:87:70:0C:59:97:11:11:01:E3
    + "puppet.example.com" (SHA256) 12:32:47:18:D1:12:85:A6:EA:D4:51:9C:24:96:E2:8A:51:41:8D:EB:E8:7C:EB:47:94:B0:8B:16:16:51:6A:D1 (alt names: "DNS:puppet", "DNS:puppet.localdomain", "DNS:puppet.example.com")

### List unsigned requests

Before Puppet Server will be able to communicate with and control the agent node, it must sign that particular agent node’s certificate. To review the unsigned requests, use the `puppet cert list` command from the Puppet server:

    sudo puppet cert list

This will only list unsigned requests. Output will look something like:

    Output: "host2.example.com" (SHA256) 9D:49:DE:46:1C:0F:40:19:9B:55:FC:97:69:E9:2B:C4:93:D8:A6:3C:B8:AB:CB:DD:E6:F5:A0:9C:37:C8:66:A0

The absence of a plus sign (`+`) indicates these certificates have not been signed yet. If there are no unsigned requests, you will be returned to the command prompt with no output.

## Signing Certificate Requests

### Sign specific requests

To sign a single certificate request, use the `puppet cert sign` command, with one or more hostnames as displayed in the certificate request.

    puppet cert sign host2.example.com

Output similar to the example below indicates that the certificate request has been signed:

    Output:Notice: Signed certificate request for host1.example.com
    Notice: Removing file Puppet::SSL::CertificateRequest host2.example.com at '/etc/puppetlabs/puppet/ssl/ca/requests/host1.example.com.pem'

### Sign all requests

You can sign all the requests by adding the `--all` flag:

    sudo puppet cert sign --all

## Revoking Certificates

Eventually, you may want to remove a host from Puppet or rebuild a host and then add it back. In this case, you will need to revoke the host’s certificate from the Puppet master. To do this, use the `clean` action:

**Note:** Create a backup `/etc/puppetlabs/puppet/ssl/` directory before revoking certificates with:

    sudo cp -R /etc/puppetlabs/puppet/ssl/ /root/

### Revoke specific certificates

You can revoke one or more specific certificates with `puppet cert clean` by supplying one or more hostnames as they appear in the certificate:

    sudo puppet cert clean host1.example.com

After revoking a certificate, you must [restart the Puppet master](https://docs.puppet.com/puppetserver/latest/restarting.html) for the revocation to take effect.

    sudo service puppetserver reload

The next time `puppet agent` runs on the agent node, it will send a new certificate signing request to the Puppet master, which can be signed with `puppet cert sign`. You can trigger the request immediately with:

    sudo puppet agent --test

### Revoke multiple certificates

Puppet doesn’t allow the bulk removal of certificates with a `--all` flag, but multiple certificates can be revoked at once by supplying the hostnames, separated by a space:

    sudo puppet cert clean host1.example.com host2.example.com . . . 

After revoking certificates, you must [restart the Puppet master](https://docs.puppet.com/puppetserver/latest/restarting.html) for the revocations to take effect.

    sudo service puppetserver reload

## Conclusion

This guide covers some of the common commands to manage Puppet certificates in Puppet version 4.x. There are other actions and flags that can be used with `puppet cert`. For a comprehensive list, see the [`puppet cert` man page](https://docs.puppet.com/puppet/latest/man/cert.html).
