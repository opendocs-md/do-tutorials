---
author: Marko Mudrinić
date: 2016-03-25
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-doctl-the-official-digitalocean-command-line-client
---

# How To Use Doctl, the Official DigitalOcean Command-Line Client

_An earlier version of this tutorial was written by [Brennen Bearnes](https://www.digitalocean.com/community/users/bpb)._

## Introduction

DigitalOcean’s web-based control panel provides a point-and-click interface for managing Droplets. However, you may prefer a command-line tool if you have many Droplets to manage, need to administer Droplets from the terminal without a graphical desktop available, or have tasks which would benefit from a scriptable interface.

`doctl` is the official DigitalOcean command-line client. It uses [the DigitalOcean API](https://developers.digitalocean.com/) to provide access to most account and Droplet features.

## Prerequisites

To follow this tutorial, you will need:

- A local computer with `doctl` installed by following [the project’s installation and configuration instructions](https://github.com/digitalocean/doctl/blob/master/README.md).

This tutorial is intended as a reference for most of `doctl`’s operations. Because `doctl` commands closely parallel the API, it may also be helpful to read the [API documentation](https://developers.digitalocean.com/documentation/v2/) and [How To Use the DigitalOcean API v2](how-to-use-the-digitalocean-api-v2).

## Generic `doctl` Usage

### Invoking Commands

In `doctl`, individual features are invoked by giving the utility a command, one or more sub-commands, and sometimes one or more options specifying particular values. Commands are grouped under three main categories:

- `account` for account-related information
- `auth` for authenticating with DigitalOcean
- `compute` for managing infrastructure

To see an overview of all commands, you can invoke `doctl` by itself. To see all available commands under one of the three main categories, you can use `doctl category`, like `doctl compute`. For a usage guide on a specific command, enter the command with the `--help` flag, as in `doctl compute droplet --help`.

### Retrieving Data in JSON Format

In scripting environments, or when working on the command line with data-processing tools, it’s often helpful to get machine-readable output from a command.

By default, `doctl` formats its output in columns of human-readable text, but can produce detailed JSON output using the `--output json` option.

    doctl compute droplet get droplet_id --output json

    Sample Output{
      "id": droplet_id,
      "name": "droplet_name",
      "memory": 1024,
      "vcpus": 1,
      "disk": 30,
      "region": {
        "slug": "nyc3",
        "name": "New York 3",
        "sizes": [
    ...

In addition to being a format readable with standard libraries in most programming languages, the JSON output may allow more fine-grained inspection of Droplets and other resources.

### Formatting

It’s often useful to obtain only a set of fields from output. To do this, you can use the `--format` flag, which takes list of fields by its name. For example, if you want to to obtain only the ID, name, and IP address of your Droplets, you can use the following command:

    doctl compute droplet list --format "ID,Name,PublicIPv4"

    Sample outputID Name Public IPv4
    50513569 doctl-1 67.205.152.65
    50513570 test 67.205.148.128
    50513571 node-1 67.205.131.88

### Templates

The `doctl compute droplet get` command supports output templating, which lets you customize the format of the output. To use this feature, specify [the Go-formatted template](https://golang.org/pkg/text/template/) via the `--template` flag.

For example, if you want to get a Droplet’s name in the format `droplet_name: droplet_name`, you would use the following `get` command:

    doctl compute droplet get 12345678 --template "droplet_name: {{ .Name}}

    Outputdroplet_name: ubuntu-1gb-nyc3-01

## Working with Resources

### Listing Resources

To get a list of resources, like Droplets, you can use the `list` command with no parameters.

    doctl compute droplet list

    Sample output for list commandID Name Public IPv4 Private IPv4 Public IPv6 Memory VCPUs Disk Region Image Status Tags
    50513569 test-1 67.205.152.65 512 1 20 nyc1 Ubuntu 16.04.2 x64 active
    50513571 test-2 67.205.131.88 512 1 20 nyc1 Ubuntu 16.04.2 x64 active
    50513570 site 67.205.148.128 512 1 20 nyc1 Ubuntu 16.04.2 x64 active

The `list` command supports a glob as an optional parameter. A glob represents pattern with wildcard characters which can be used to filter specific resources by name. For example, to get a list of Droplets whose names start with `test`, you can use the following command:

    doctl compute droplet list 'test*'

    Sample output for list command with 'doctl-' as globID Name Public IPv4 Private IPv4 Public IPv6 Memory VCPUs Disk Region Image Status Tags
    50513569 test-1 67.205.152.65 512 1 20 nyc1 Ubuntu 16.04.2 x64 active
    50513571 test-2 67.205.131.88 512 1 20 nyc1 Ubuntu 16.04.2 x64 active

### Creating Resources

Creating a resource requires longer commands with more detailed parameters.

For example, the following command creates a 64-bit Debian 8 Droplet named **test** with 1GB of memory, an SSH key, and backups enabled.

    doctl compute droplet create test --size 1gb --image debian-8-x64 --region nyc1 --ssh-keys 4d:23:e6:e4:8c:17:d2:cf:89:47:36:b5:c7:33:40:4e --enable-backups

    Sample Droplet creation outputID Name Public IPv4 Memory VCPUs Disk Region Image Status
    11450164 test 1024 1 30 nyc1 Debian 8.3 x64 new

Deleting a resource requires a resource ID as an argument, or a resource name in the event that an ID doesn’t exist for given resource (e.g. tags). To confirm your intentions, you need to confirm all delete actions by answering the confirmation question with `y` or `yes`.

    doctl compute droplet delete 123456

    OutputWarning: Are you sure you want to delete droplet(s) (y/N) ? 

Not providing an answer or providing answer different from `y` or `yes` will cancel the action without deleting the resource. You can make `doctl` assume an affirmative answer without explicitly providing it, using `--f` (`--force`) flag:

    doctl compute droplet delete -f 123456

### Finding Unique Identifiers for Resources

The Droplet creation command requires a series of identifiers, like `nyc1` for the NYC1 region, `debian-8-x64` for the Debian image, and an SSH key fingerprint like `4d:23:e6:e4:8c:17:d2:cf:89:47:36:b5:c7:33:40:4e`.

Some identifiers are guessable, like `1gb` for a 1 gigabyte Droplet, but others aren’t nearly as obvious. A number of resources, such as Droplets and images, are identified by a value (often numeric) unique within DigitalOcean’s database.

The required unique identifiers for most commands can be retrieved from the API:

| Command | Notes |
| --- | --- |
| `doctl compute droplet list` | Your Droplets. Some commands also take the name; most require the numeric value from the **ID** column. |
| `doctl compute ssh-key list` | The SSH keys associated with your account. For Droplet creation, you can specify either the **numeric ID** or **fingerprint**. |
| `doctl compute region list` | Available regions. Use the string in the **Slug** column. |
| `doctl compute image list` | Available images, including snapshots, backups, and base distribution images. Use the string in the **Slug** column for creating new Droplets. |
| `doctl compute size list` | Available Droplet sizes. Use the string in the **Slug** column. |
| `doctl compute tag list` | Available Tags. Use the string in the **Name** column. |

## Working with Droplets

### Creating, Deleting, and Inspecting Droplets

The `doctl compute droplet` command lets you create, delete, and inspect Droplets. Again, most commands for working with individual Droplets require the Droplet’s unique ID, and these can be found in the output from `doctl droplet list`.

| `doctl compute droplet` subcommand | Notes |
| --- | --- |
| `actions droplet_id` | Display a history of actions taken for a Droplet. |
| `backups droplet_id` | List backups for a Droplet. |
| `create name --size 1gb --image image_slug --region nyc1` | Create a Droplet. Size, image and region are all mandatory. |
| `delete droplet_id_or_name` | Delete a Droplet by id or name. |
| `get droplet_id` | Get details for a particular Droplet. |
| `kernels droplet_id` | List kernels for a Droplet. |
| `list` | List your current Droplets. |
| `neighbors droplet_id` | List your Droplets running on the same physical hardware as a specific Droplet. |
| `snapshots droplet_id` | List snapshots for a Droplet. |
| `tag droplet_id/droplet_name` | Tag a Droplet. |
| `untag droplet_id/droplet_name` | Untag a Droplet. |

### Initiating Droplet Actions

The `doctl compute droplet-action` command lets you trigger various actions for a Droplet, including power management actions and toggling features like backups and private networking.

| `doctl compute droplet-action` subcommand | Notes |
| --- | --- |
| `get droplet_id --action-id action_id` | Get details about action on a Droplet. |
| `disable-backups droplet_id` | Disable backups for a Droplet. |
| `reboot droplet_id` | Reboot a Droplet. |
| `power-cycle droplet_id` | Turn a Droplet off and back on again. |
| `shutdown droplet_id` | Shut down a Droplet. |
| `power-off droplet_id` | Power off a Droplet. The Droplet must be powered on. It’s usually best to do this from the command line of the Droplet itself in order to prevent data loss. |
| `power-on droplet_id` | Power on a Droplet. The Droplet must be powered off. |
| `power-reset droplet_id` | Power reset Droplet. |
| `enable-ipv6 droplet_id` | Enable ipv6 for a Droplet. |
| `enable-private-networking droplet_id` | Enable [private networking](how-to-set-up-and-use-digitalocean-private-networking) for a Droplet. |
| `upgrade droplet_id` | Upgrade a Droplet. |
| `restore droplet_id --image-id image_id` | Restore a Droplet to a specific backup image. The `image_id` must be a backup of the Droplet. |
| `resize droplet_id --size 2gb` | Resize a Droplet. The Droplet must be powered off. By default, disk is not resized, which allows Droplet to be downgraded. You can resize disk using the `--resize-disk` flag. |
| `rebuild droplet_id --image-id image_id` | Rebuild a Droplet from a specific image. |
| `rename droplet_id --droplet-name new_name` | Rename a Droplet to `new_name`. |
| `change-kernel droplet_id --kernel-id kernel_id` | Change a Droplet’s kernel to `kernel_id`. |
| `snapshot droplet_id --snapshot-name snapshot_name` | Take a snapshot of a Droplet, naming it `snapshot_name`. |

## Working with SSH

### Making SSH Connections

In order to connect to an individual Droplet with SSH, it’s usually necessary to know either its IP address or fully-qualified domain name. You can instead use `doctl` to connect to a Droplet by its name, numeric ID or Private IP:

    doctl compute ssh droplet_name

    doctl compute ssh droplet_id

    doctl compute ssh --ssh-private-ip droplet_private_ip

Also, you can provide a command to execute once the SSH connection is established using the `--ssh-command` flag. This will run the command, the output of which will be printed on your local terminal, and then the SSH session will close.

    doctl compute ssh --ssh-command command

**Note** : SSH command forwarding is currently not available on Windows.

The default SSH user name is **root** ( **core** for CoreOS) and the default port is `22`. You can use flags to set non-default values and enable other features:

| Flag | Description |
| --- | --- |
| `--ssh-user string` | User name to use for the SSH session. |
| `--ssh-port int` | The port for the SSH session. |
| `--ssh-key-path string` | Path to SSH key. |
| `--ssh-agent-forwarding` | Enable agent forwarding. |

You can also change the default configuration values in a configuration file. [The project’s README file](https://github.com/digitalocean/doctl#configuring-default-values) has more detail on how to do this.

### Using SSH Keys

You can manage the SSH public keys associated with your account using the `doctl compute ssh-key` command. Most commands which reference SSH keys accept either the numeric ID for the key or its fingerprint.

| `doctl compute ssh-key` subcommand | Notes |
| --- | --- |
| `list` | List SSH keys associated with your account. |
| `get ssh_key_id_or_fingerprint` | Get info on a specific key, by numeric ID or key’s fingerprint. |
| `create new_key_name --public-key "public_key"` | Associate a public key with your account by specifying its contents. |
| `import new_key_name --public-key-file ~/.ssh/id_rsa.pub` | Associate a public key with your account by specifying a source file. |
| `delete ssh_key_id_or_fingerprint` | Delete a key from your account by numeric ID or fingerprint. |
| `update ssh_key_id_or_fingerprint --key-name new_key_name` | Change a key’s name by numeric ID or fingerprint. |

## Working with Floating IPs

A Floating IP is a publicly-accessible static IP address that can be assigned to one of your Droplets. For a detailed description of the feature, you can read [How To Use Floating IPs on DigitalOcean](how-to-use-floating-ips-on-digitalocean). You can manipulate floating IPs with `doctl compute floating-ip`.

| `doctl compute floating-ip` subcommand | Notes |
| --- | --- |
| `list` | List all Floating IP addresses. |
| `get floating_ip_address` | Get the details for a Floating IP address. |
| `create --region nyc1` | Create a Floating IP in `nyc1` region. |
| `delete floating_ip_address` | Delete a floating IP address. |

### Assigning Floating IPs to Droplets

The `doctl compute floating-ip-action` command is used to assign or unassign a Floating IP from a Droplet.

| `doctl compute floating-ip-action` subcommand | Notes |
| --- | --- |
| `assign floating_ip droplet_id` | Assign a Floating IP to the Droplet by its numeric ID. |
| `unassign floating_ip` | Unassign a Floating IP. |
| `get floating_ip action_id` | Get details about a Floating IP action by its numeric ID. |

## Working with Domains

The `doctl compute domain` command is used to manage domains. See our [Introduction to Managing DNS series](https://www.digitalocean.com/community/tutorial_series/an-introduction-to-managing-dns) for a broad overview of the subject.

| `doctl compute domain` subcommand | Notes |
| --- | --- |
| `list` | List domains. |
| `create domain_name --ip-address droplet_ip_address` | Create a domain with default records for `droplet_ip_address`. |
| `get domain_name` | Get a domain record. |
| `delete domain_name` | Delete a domain. |

### Managing Domain Records

The `doctl compute domain records` command can be used to create, delete, update or get information about domain’s DNS records.

| `doctl compute domain records` subcommand | Notes |
| --- | --- |
| `list domain_name` | List records for given domain. |
| `create domain_name --record-type record_type` | Create an record for domain. |
| `delete domain_name record_id` | Delete record by numeric ID. |
| `update domain_name --record-id record_id` | Update record by numeric ID. |

## Working with Block Storage Volumes

### Creating, Deleting, and Inspecting Block Storage Volumes

The `doctl compute volume` command can be used to create, delete, or get information about DigitalOcean’s Block Storage volumes. For more information about this feature, read our guide on [How To Use Block Storage on DigitalOcean](how-to-use-block-storage-on-digitalocean).

| `doctl compute volume` subcommand | Notes |
| --- | --- |
| `list` | List volumes. |
| `create volume_name --region volume_region --size volume_size` | Create a volume. The name, region, and size are mandatory. |
| `get volume_ID` | Get volume by numeric ID. |
| `delete volume_ID` | Delete volume. |
| `snapshot volume_ID` | Snapshot volume. |

### Initiating Volume Actions

The `doctl compute volume-action` command lets you trigger actions for a volume, including attaching volumes to and detaching volumes from Droplets.

| `doctl compute volume-action` subcommand | Notes |
| --- | --- |
| `attach volume_id droplet_id` | Attach a volume to a Droplet. |
| `detach volume_id droplet_id` | Detach a volume from a Droplet. |
| `resize volume_id --region volume_region --size new_size` | Resize a volume. |

## Working with Load Balancers

The `doctl compute load-balancer` command can be used to create, delete, or get information about DigitalOcean’s Load Balancers. For more information about this feature, read our [Introduction to DigitalOcean Load Balancers](an-introduction-to-digitalocean-load-balancers).

| `doctl compute load-balancer` subcommand | Notes |
| --- | --- |
| `list` | List load balancers. |
| `create --name lb_name --region lb_region --tag-name tag_name --forwarding-rules forwarding_rule` | Create a Load Balancer. The name, region, a tag or list of Droplet IDs, and at least one forwarding rule are mandatory. |
| `update --name lb_name --region lb_region --tag-name tag_name --forwarding-rules forwarding_rule` | Create a Load Balancer. The name, region, a tag or list of Droplet IDs, and at least one forwarding rule are mandatory. |
| `get lb_ID` | Get a load balancer. |
| `delete lb_ID` | Delete a load balancer. |
| `add-droplets lb_ID --droplet-ids droplet_ID` | Add Droplets to a load balancer. |
| `remove-droplets lb_ID --droplet-ids droplet_ID` | Remove Droplets from a load balancer. |
| `add-forwarding-rules lb_ID --forwarding-rules forwarding_rule` | Add forwarding rules to a load balancer. |
| `remove-forwarding-rules lb_ID --forwarding-rules forwarding_rule` | Remove forwarding rules from a load balancer. |

When used as an argument to `doctl`, forwarding rules should be expressed like: `entry_protocol:protocol,entry_port:port,target_protocol:protocol,target_port:port`.

### Managing Certificates

The `doctl compute certificate` subcommand allows you to upload and manage SSL certificates, private keys, and certificate chains.

| `doctl compute certificate` subcommand | Notes |
| --- | --- |
| `list` | List all Certificates. |
| `get certificate_id` | Get a Certificate by ID. |
| `create --name certificate_name --leaf-certificate-path leaf_certificate_path` | Create a Certificate. Name and Leaf Certificate Path are mandatory. |
| `delete certificate_id` | Delete a Certificate by ID. |

## Working with Snapshots

The `doctl compute snapshot` command can be used to list, delete, or get information about Droplet and Volume Snapshots.

| `doctl compute snapshot` subcommand | Notes |
| --- | --- |
| `list` | List all Snapshots. |
| `get snapshot_ID` | Get a Snapshot. |
| `delete snapshot_ID` | Delete a Snapshot. |

To create a new Snapshot, you need to use the appropriate command under the relevant resource command tree. For example:

- `doctl compute droplet-action snapshot droplet_ID` creates a Snapshot from a Droplet.
- `doctl compute volume snapshot volume_ID` creates a Snapshot from a Volume.

## Working with Images

The `doctl compute image` command allows you to manage all images, including distribution images, application images, and user-created images such as backups and snapshots. We recommend using the `snapshot` command for managing snapshots because it provides more detail, has delete functionality, and supports Block Storage snapshots.

| `doctl compute image` subcommand | Notes |
| --- | --- |
| `list --public` | List all images. |
| `list-distribution --public` | List all available distribution images. |
| `list-application --public` | List all available [One-Click Applications](https://www.digitalocean.com/products/one-click-apps/). |
| `list-user` | List all user-created images. |
| `get image_id` | Get an Image by ID. |
| `update image_id --name image_name` | Update Image’s name. Name is mandatory. |
| `delete image_id` | Delete an Image by ID. |

### Invoking Image Actions

The `doctl compute image-action` command allows you to transfer images and get details about actions invoked on images.

| `doctl compute image-action` subcommand | Notes |
| --- | --- |
| `get image_id --action-id action_id` | Get an Action for Image by its ID. Action ID is mandatory. |
| `transfer image_id --region region` | Transfer an Image to the another region. Image ID and region are mandatory. |

## Working with Firewalls

The `doctl compute firewall` command lets you create and manage Firewalls, including creating and maintaining rules. For more about information about administering Firewalls using `doctl`, check out the [How To Secure Web Server Infrastructure With DigitalOcean Cloud Firewalls Using Doctl](how-to-secure-web-server-infrastructure-with-digitalocean-cloud-firewalls-using-doctl) tutorial.

| `doctl compute firewall` command | Notes |
| --- | --- |
| `list` | List all Firewalls. |
| `list-by-droplet droplet_id` | List all Firewalls by Droplet’s numeric ID. |
| `create --name firewall_name --inbound-rules inbound_rules --outbound-rules outbound_rules` | Create a Firewall. The name and at least an inbound or outbound rule are mandatory. |
| `update firewall_id --name firewall_name --inbound-rules inbound_rules --outbound-rules outbound_rules` | Update a Firewall. The numeric ID, name and at least an inbound or outbound rule are mandatory. |
| `get firewall_id` | Get a Firewall by its numeric ID. |
| `delete firewall_id` | Delete a Firewall by numeric ID. |
| `add-droplets firewall_id --droplet-ids droplet_IDs` | Add Droplets by their numeric ID to the Firewall. |
| `remove-droplets firewall_id --droplet-ids droplet_IDs` | Remove Droplets from the Firewall by their numeric IDs. |
| `add-tags firewall_id --tag-names tags` | Add Tags to the Firewall. |
| `remove-tags firewall_id --tag-names tags` | Remove Tags from the Firewall. |
| `add-rules firewall_id --inbound-rules inbound_rules --outbound-rules outbound_rules` | Add inbound or outbound rules to the Firewall. |
| `remove-rules firewall_id --inbound-rules inbound_rules --outbound-rules outbound_rules` | Remove inbound or outbound rules to the Firewall. |

When used as an argument to `doctl`, inbound or outbound rules should be expressed like: `protocol:protocol,ports:ports,droplet_id:droplet-id`.

## Working with Tags

Tags are used to apply custom labels to resources, allowing you to easily filter them. You can learn more about Tags in [the How To Tag DigitalOcean Droplets tutorial](how-to-tag-digitalocean-droplets).

| `doctl compute tag` subcommand | Notes |
| --- | --- |
| `create tag_name` | Create a Tag. |
| `get tag_name` | Get a Tag by name. |
| `list` | List all Tags. |
| `delete tag_name` | Delete a Tag by name. |

## Working with Your Account

### Reading History of Actions for Your Account

The DigitalOcean system logs a history of the actions taken on your Droplets, Floating IPs, and other resources. You can access this data with the `doctl compute action` command:

    doctl compute action list

You can see actions for a specific Droplet like so:

    doctl compute droplet actions droplet_id

### Retrieving Your Account Information

You can discover basic details about your account, such as your configured e-mail address and Droplet limit:

    doctl account get

Because API requests are rate-limited, it may be helpful to see how many requests you’ve made recently, and when the limit is due to reset:

    doctl account ratelimit

## Conclusion

The `doctl` utility is a helpful tool for managing Droplets and other resources at the command line. It can greatly reduce the amount of manual interaction with web-based interfaces needed for daily development and administrative tasks.

In addition to learning about [the underlying API](how-to-use-the-digitalocean-api-v2), you may want to explore [libraries which wrap the API for popular programming languages](https://developers.digitalocean.com/libraries/), and [tools such as Ansible](how-to-create-ansible-playbooks-to-automate-system-configuration-on-ubuntu) for automating system-level tasks.
