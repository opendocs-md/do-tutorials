---
author: Bulat Khamitov
date: 2013-02-26
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-scale-your-infrastructure-with-digitalocean
---

# How To Scale Your Infrastructure with DigitalOcean

With DigitalOcean’s simple interface with API access, and full root level access, here is a great opportunity to create an automated setup that scales itself on-demand. You can have your websites scale up or down automatically to meet the traffic demands.

Both vertical and horizontal scalability is possible with this API, which can be accessed with just a bash script. It is best to create an admin droplet which has its public key on all other droplets. This would allow you to push webpage updates with rsync, as well as issue commands to other droplets, and query them for Nagios, NRPE, and SNMPD vitals. You would need to create your own level of logic to determine how and when you wish to scale things – for example if a server reaches 85% CPU usage, double the RAM (vertical scaling) or create a clone (horizontal scaling). The choice is a price-benefit analysis and is left to the reader.

Here is a bash script to get things started. Make sure to modify Client\_Key and API\_Key to your own variables from [API Access Page](https://www.digitalocean.com/api_access) - click “Generate a new API Key”. For our example we have the following:

    Client Key: A2a9SfT4NeFBl6df5cu42 API Key: mnqWGdu4OfLBwwJPee6cpjkeY70qv9mKicqZYvtHJ

### Scaler.sh :

    #!/bin/bash # Be Sure To Change This! Client\_Key=A2a9SfT4NeFBl6df5cu42 API\_Key=mnqWGdu4OfLBwwJPee6cpjkeY70qv9mKicqZYvtHJ droplets() { echo "Your current droplets:" All\_Droplets=`curl -s "https://api.digitalocean.com/droplets/?client_id=$Client_Key&api_key=$API_Key"` echo $All\_Droplets | sed -e 's/,/\n/g' | sed -e 's/{/\n/g' | sed -e 's/}/\n/g' | sed -e 's/"//g' } spinup() { Droplet\_Name=$1 Size\_ID=$2 Image\_ID=$3 Region\_ID=$4 echo "Spinning up a new droplet $Droplet\_Name" curl -s "https://api.digitalocean.com/droplets/new?name=$Droplet\_Name&size\_id=$Size\_ID&image\_id=$Image\_ID&region\_id=$Region\_ID&client\_id=$Client\_Key&api\_key=$API\_Key" } resize() { Droplet\_ID=$1 Size\_ID=$2 echo "Resizing a droplet ID: $Droplet\_ID to Size ID: $2" curl -s "https://api.digitalocean.com/droplets/$Droplet\_ID/resize/?size\_id=$Size\_ID&client\_id=$Client\_Key&api\_key=$API\_Key" } sizes() { sizes=`curl -s "https://api.digitalocean.com/sizes/?client_id=$Client_Key&api_key=$API_Key"` echo $sizes | sed -e 's/,/\n/g' | sed -e 's/{//g' | sed -e 's/}//g' | sed -e 's/"//g' | sed -e 's/\[/\n/g' } snapshot() { Droplet\_ID=$1 Snapshot\_Name=$2 echo "Taking a snapshot of Droplet $1 with Name: $Snapshot\_Name" curl -s "https://api.digitalocean.com/droplets/$Droplet\_ID/snapshot/?name=$Snapshot\_Name&client\_id=$Client\_Key&api\_key=$API\_Key" } go() { # Display all current droplets. Region\_ID: 1 for US, 2 for Amsterdam. droplets # Show possible Size IDs, for RAM, also tied to amount of CPU cores and HDD allocated - refer to https://www.digitalocean.com/pricing echo "Possible droplets sizes by RAM:" sizes # Take a snapshot of an existing droplet # The syntax is: snapshot Droplet\_ID Snapshot\_Name # For example to take a snapshot of droplet with ID "72100": #snapshot 72100 domain.com # Vertical Scaling - Increase RAM, CPU, Disk # The syntax is: resize Droplet\_ID New\_Size\_ID # For example to resize a 512MB droplet to a 1GB droplet with ID "72100": #resize 72100 63 # Horizontal Scaling - Clone a server from a snapshot # The syntax is: spinup Droplet\_Name Size\_ID Image\_ID Region\_ID # For example, to spinup a 512MB clone of domain.com webserver with image ID "12573" in New York datacenter (Region 1): #spinup domain.com 66 12574 1 } go

Suppose we have created a webserver droplet that has the Nginx/Apache/Memcached stack with Nagios, NRPE, SNMPD configured. Our admin droplet’s SSH key in /root/.ssh/authorized\_keys and iptables rules in place, only allowing admin droplet to connect via SSH. The domain being hosted is domain.com.

A sample output of the script, with this webserver droplet being displayed:

    id:72100 name:domain.com image\_id:12574 size\_id:66 region\_id:1 backups\_active:null ip\_address:192.34.56.29 status:active

Note the Droplet\_ID is 72100 and Image\_ID (snapshot) is 12574 To take a snapshot of this droplet, uncomment the following line and run it:

    snapshot 72100 domain.com

Taking a snapshot of Droplet 72100 with Name: domain.com

    {"status":"OK","event\_id":473473}

This creates a snapshot of our droplet and saves it as “domain.com” :

 ![second image](https://assets.digitalocean.com/tutorial_images/MmtmqkZ.png)

To scale this droplet vertically from 512MB to 1GB uncomment the following line and run:

    resize 72100 63

    Resizing a droplet ID: 72100 to Size ID: 63 {"status":"OK","event\_id":473530}

To scale this droplet horizontally, we will spin up a new one by uncommenting this line and running Scaler.sh :

    spinup domain.com 66 12574 1

Spinning up a new droplet domain.com

    {"status":"OK","droplet":{"id":72124,"name":"domain.com","image\_id":12574,"size\_id":66,"event\_id":473545}}

Latest DigitalOcean droplet sizes and IDs:

| **ID** | **Name** |
| 66 | 512MB |
| 63 | 1GB |
| 62 | 2GB |
| 64 | 4GB |
| 65 | 8GB |
| 61 | 16GB |
| 60 | 32GB |
| 70 | 48GB |
| 70 | 48GB |
| 69 | 64GB |
| 68 | 96GB |

Recently DigitalOcean has upgraded to SSD drives, and the smallest droplet comes with 512MB of RAM and 1 CPU core. The next step up is 1GB of RAM and 1 CPU core. You can run Nginx on backend with PHP-FPM handling PHP requests, and Varnish cache in front of Nginx.

**Benchmarks of Varnish cache with Nginx and PHP+FPM reveal 420 requests/second compared against 22.25 requests/second served by Nginx and PHP-FPM alone.**

As far as droplets are concerned, there is also an interesting concept of a self-replicating VM. A host can be self-aware of being ‘overloaded’ and decide to clone itself and add the clone into DNS rotation. There are many ways of implementing this, and simplest way would be to use SNMPD and Nagios for polling data.

You can even setup an orchestration VM that has its public key on all VMs. A level of automation depends on your imagination and desire for complexity.

Having essential monitoring tools like Nagios, SNMPD, NRPE, and your SSH keys on the droplet that you are cloning is important. It will allow you to sync new content to this server down the line, further automating the process. You can setup an admin droplet to which you’ll upload webpages and from which all syncs will be done with a crontab. This admin droplet should have its key placed on all your droplets, and SSH port allowed only from that admin droplet’s IP address. Whether you choose to have an OpenVPN connection to this admin droplet is up to you.

Once you have spun up your new webserver from a snapshot, you’ll need to place the server into rotation. This can be accomplished by DNS round robin, Nginx reverse proxy, a dedicated load balancer setup, and so on. The choice would depend on your infrastructure needs and budget.

By Bulat Khamitov
