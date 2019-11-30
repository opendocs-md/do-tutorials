---
author: Justin Ellingwood
date: 2014-01-03
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-digitalocean-snapshots-to-automatically-backup-your-droplets
---

# How To Use DigitalOcean Snapshots to Automatically Backup your Droplets

## Introduction

* * *

Backups are extremely important in any kind of production or development environment. Unforeseen circumstances could cost you days or months of productivity. You could easily lose an entire project if you have not backed up your files.

While there are many ways of backing up your important data, there is also a method available through the DigitalOcean control panel and API: snapshots.

Snapshots copy an image of your entire VPS and store it on the DigitalOcean servers. They are different from the “backups” feature, which offers automated backups and can be selected by ticking the backups box. You can redeploy your server or spin up new droplets based on your snapshot. Beginning in October 2016, snapshots cost $0.05 per gigabyte per month, based on the amount of utilized space within the filesystem.

In this article, we will discuss how to use DigitalOcean snapshots as a method of backing up your environment. We will briefly cover the manual way of snapshotting your server, and then quickly move on to doing so in an automated way through the API and a cron job.

## How To Use Manual Snapshots

* * *

It is easy to use the DigitalOcean control panel to snapshot your server for quick, one-off backups.

Start by powering off your droplet from the command line. Although it’s possible to snapshot a live system, powering off provides some guarantee that the filesystem will be in a consistent state. You can do this safely by typing a command like this into the terminal when you are connected to the droplet:

    sudo poweroff

This is much safer than using the “Power Cycle” options within the control panel, because that option acts more like a hard reset.

Next, click on your droplet’s name in the main “Droplets” page:

![DigitalOcean droplet name](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/api_backup/droplet_name.png)

In the next screen, Click on the tab across the top marked “Snapshots”. Enter the name for your snapshot and press the “Take Snapshot” button to initiate a snapshot:

![DigitalOcean take snapshot](https://assets.digitalocean.com/site/ControlPanel/Take_a_Snapshot.png)

Your snapshot will initiate. When the snapshot process is complete, your server will be rebooted.

## How To Snapshot Through the API

* * *

DigitalOcean provides an [API](https://developers.digitalocean.com/) that allows you to access the power of the control panel from the command line or a programming interface.

In this section, we will demonstrate the basic idea using `curl`, which is a simple command line utility to access websites.

### Create an API Key

* * *

Before we begin, you must set up API access to your account. You must do this in the control panel. Click on the “API” section of the top navigation bar:

![DigitalOcean API section](https://assets.digitalocean.com/site/ControlPanel/API_Menu.png)

You will be taken to the general API interface. Here you can generate an API token, register developer applications, view authorized application, and read the API documentation.

Click on “Generate new token” at the top of the page:

![DigitalOcean generate API](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/api_backup/gen_api.png)

Give the token a name and determine the level of access it will have for your account. For this tutorial, you will want to have both read and write access:

![DigitalOcean generate API](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/api_backup/create_token.png)

You will now have an API token available to you:

![DigitalOcean API key](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/api_backup/api_key.png)

Copy and paste the API token into a secure location, as it will **not** be shown to you again. If you lose this key, you will have to recreate another token and adjust the values of any script or application using the former token.

You will need both the API token to access your account through the API.

Now that you have this piece of information, you are ready for our first test.

### Test API Access

* * *

The general syntax needed to operate `curl` that we will be using in this guide is:

    curl -X HTTP\_METHOD "requested\_url"

The method we will be using is “GET”, as shown in the API documentation. The URL that we are requesting will be some variation on this:

    https://api.digitalocean.com/v2/command

Let’s just use AAABBB as the example API token for the example client ID for these next commands.

So, looking at the API documentation, if you wanted to do a request for “/droplets”, which returns all active droplets on your account, you could form a URL like this:

    https://api.digitalocean.com/v2/droplets

As we are trying to do this from the command line, we will use curl in the format we specified above. We must also include the API token in the Authorization header. The command becomes:

    curl -X GET -H "Content-Type: application/json" \
        -H "Authorization: Bearer AAABBB" \
        "https://api.digitalocean.com/droplets"

* * *

    {"droplets":[{"id":123456,"name":"irssi","memory":1024,"vcpus":1,"disk":30,"locked":false,"status":"active","kernel":{"id":1221,"name":"Ubuntu 14.04 x64 vmlinuz-3.13.0-24-generic (1221)","version":"3.13.0-24-generic"},"created_at":"2014-04-20T23:47:21Z","features":["backups","private_networking","virtio"],"backup_ids":[8000333,8185675,8381528,8589151,8739369],"snapshot_ids":[],"image":{"id":3240036,"name":"Ubuntu 14.04 x64","distribution":"Ubuntu","slug":null,"public":false,"regions":["nyc1","ams1","sfo1","nyc2","ams2","sgp1","lon1","nyc2"],"created_at":"2014-04-18T15:59:36Z","min_disk_size":20},"size_slug":"1gb","networks":{"v4":[{"ip_address":"XX.XXX.XXX.XXX","netmask":"255.255.0.0","gateway":"10.128.1.1","type":"private"},{"ip_address":"XX.XXX.XXX.XXX","netmask":"255.255.240.0","gateway":"107.170.96.1","type":"public"}],"v6":[]},"region":{"name":"New York 2","slug":"nyc2","sizes":[],"features":["virtio","private_networking","backups"],"available":null}},
    . . .

We can identify individual droplets by their droplet ID. This is held in the “id” field of each droplet’s returned JSON string. It is also available at the end of the URL on that droplet’s page on the control panel:

![DigitalOcean browser droplet ID](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/api_backup/browser_droplet_id.png)

To get information about a single droplet, we can issue a command like this. We will assume that the droplet ID is 123456:

    curl -X GET -H "Content-Type: application/json" \
        -H "Authorization: Bearer AAABBB" \
        "https://api.digitalocean.com/v2/droplets/123456"

* * *

        {"droplets":[{"id":123456,"name":"irssi","memory":1024,"vcpus":1,"disk":30,"locked":false,"status":"active","kernel":{"id":1221,"name":"Ubuntu 14.04 x64 vmlinuz-3.13.0-24-generic (1221)","version":"3.13.0-24-generic"},"created_at":"2014-04-20T23:47:21Z","features":["backups","private_networking","virtio"],"backup_ids":[8000333,8185675,8381528,8589151,8739369],"snapshot_ids":[],"image":{"id":3240036,"name":"Ubuntu 14.04 x64","distribution":"Ubuntu","slug":null,"public":false,"regions":["nyc1","ams1","sfo1","nyc2","ams2","sgp1","lon1","nyc2"],"created_at":"2014-04-18T15:59:36Z","min_disk_size":20},"size_slug":"1gb","networks":{"v4":[{"ip_address":"XX.XXX.XXX.XXX","netmask":"255.255.0.0","gateway":"10.128.1.1","type":"private"},{"ip_address":"XX.XXX.XXX.XXX","netmask":"255.255.240.0","gateway":"107.170.96.1","type":"public"}],"v6":[]},"region":{"name":"New York 2","slug":"nyc2","sizes":[],"features":["virtio","private_networking","backups"],"available":null}}}

We can then take this further by issuing commands to that specific droplet. Assuming that we had already powered off the droplet safely from within the server, we can issue the snapshot command like this:

    curl -X POST -H 'Content-Type: application/json' \ -H 'Authorization: Bearer AAABBB' \ -d '{"type":"snapshot","name":"Name for New Snapshot"}' \ "https://api.digitalocean.com/v2/droplets/123456/actions" 

    {"action": {"id": 99999999, "status": "in-progress", "type": "snapshot", "started\_at": "2014-11-14T16:34:39Z", "completed\_at": null, "resource\_id": 332233, "resource\_type": "droplet", "region": "nyc3"}}

This will return a JSON string that includes the event ID of the snapshot you just requested. We can use this to query whether the event has completed successfully using the “events/” request:

    curl -X GET -H "Content-Type: application/json" \
        -H "Authorization: Bearer $AAABBB" \
        "https://api.digitalocean.com/v2/actions/123456"

* * *

    {"action":{"id":99999999,"status":"completed","type":"snapshot","started_at":"2014-12-08T21:03:01Z","completed_at":"2014-12-08T21:05:32Z","resource_id":332233,"resource_type":"droplet","region":"nyc3"}}

As you can see, this event is marked as “completed.” We have just made our first snapshot from the command line!

## Automate Snapshot Backups Using a Script

* * *

As you saw in the last section, it is possible to control quite a lot from the command line using the API. However, doing this manually not only is a bit cumbersome, it doesn’t solve our problem of automating snapshots at all. In fact, it requires more work with these methods than pointing and clicking around in the interface.

However, the great thing about being able to access data through the API is that we can add this functionality to a script. A script is advantageous not only because it speeds up all of the manual querying and typing, but also because we can set it to run automatically from the command line.

In this set up, we will create a simple Ruby script that will backup our droplets. We will then automate the script by adding a cronjob to snapshot our servers at predetermined intervals.

You can set up the script and cronjob to run on your local machine assuming that you have access to a Ruby interpreter and cron, or from another droplet. We will be using an Ubuntu 12.04 droplet to snapshot our other servers. [Create a normal user](https://www.digitalocean.com/community/articles/initial-server-setup-with-ubuntu-12-04) if you haven’t done so already.

### Create the Script

* * *

To begin with, we need to download Ruby if it is not already installed on our system. We can do this easily by installing the Ruby version manager and telling it to give us the latest stable version:

    \curl -sSL https://get.rvm.io | bash -s stable --ruby

We will be asked for our sudo password to install the necessary helper utilities and set some system properties. This will [install rvm](how-to-use-rvm-to-manage-ruby-installations-and-environments-on-a-vps) and the latest stable version of Ruby.

After installation, we can source the rvm script by running:

    source ~/.rvm/scripts/rvm

Next, we will need to create a file called `snapshot.rb` in your favorite text editor:

    cd ~
    nano snapshot.rb

Inside, you can paste the following script file:

    #!/usr/bin/env ruby
    require 'rest_client'
    require 'json'
    
    $api_token = ENV['DO_TOKEN']
    $baseUrl = "https://api.digitalocean.com/v2/"
    $headers = {:content_type => :json, "Authorization" => "Bearer #{$api_token}"}
    
    class ResponseError < StandardError; end
    
    def droplet_on?(droplet_id)
      url = $baseUrl + "droplets/#{droplet_id}"
      droplet = get(url)['droplet']
    
      droplet['status'] == 'active'
    end
    
    def power_off(droplet_id)
      url = $baseUrl + "droplets/#{droplet_id}/actions"
      params = {'type' => 'power_off'}
      post(url, params)
    end
    
    def snapshot(droplet_id)
      url = $baseUrl + "droplets/#{droplet_id}/actions"
      params = {'type' => 'snapshot', 'name' => "Droplet #{droplet_id} " + Time.now.strftime("%Y-%m-1")}
      post(url, params)
    end
    
    def get(url)
      response = RestClient.get(url, $headers){|response, request, result| response }
      puts response.code
    
      if response.code == 200
        JSON.parse(response)
      else
        raise ResponseError, JSON.parse(response)["message"]
      end
    end
    
    def post(url, params)
      response = RestClient.post(url, params.to_json, $headers){|response, request, result| response }
    
      if response.code == 201
        JSON.parse(response)
      else
        raise ResponseError, JSON.parse(response)["message"]
      end
    end
    
    droplets = ARGV
    
    droplets.each do |droplet_id|
      puts "Attempting #{droplet_id}"
    
      begin
        if droplet_on?(droplet_id)
          power_off(droplet_id)
    
          while droplet_on?(droplet_id) do
            sleep 10
          end
          puts "Powered Off #{droplet_id}"
          sleep 10
        end
    
        snapshot(droplet_id)
        puts "Snapshotted #{droplet_id}"
      rescue ResponseError => e
        puts "Error Snapshotting #{droplet_id} - #{e.message}"
      end
    end

Save and close the file when you are finished.

Now we can make this file executable by typing:

    chmod 755 snapshot.rb

This script works by assigning our client ID and API key to environmental variables called `DO_CLIENT_ID` and `DO_API_KEY` respectively. We then pass the script a list of droplet ID numbers. The script will then run through the list of IDs, power off any active droplets, and snapshot them.

Assuming we had the same setup that we used previously, we could run this command by typing:

    DO_TOKEN="AAABBB" ./snapshot.rb 123456

This would snapshot just one droplet. More droplet IDs could be added after the first one, separated by spaces:

    DO_TOKEN="AAABBB" ./snapshot.rb 123456 111111 222222 333333

### Automate the Script with Cron

* * *

Now that we have our script file in working order, we can set it to automatically run by using the cron utility.

Because our API calls and script do not require root privileges, we should set this up in our local user’s crontab. Do not use the system crontab file located in `/etc`, because your changes can be wiped out if cron receives an update.

First, we should see if our user already has a crontab:

    crontab -l

If a crontab is printed out, we should back it up in case we want to revert our changes later on:

    cd
    crontab -l > crontab.bak

Now that we have our crontab backed up, let’s see where rvm installed our Ruby. Cron does not have a notion of an environment, so we will need to give it the full path to both our script, and ruby itself:

    which ruby

    /home/your\_user/.rvm/rubies/ruby-2.1.0/bin/ruby

Yours might be slightly different. Save this path so that you can enter it into the crontab.

It is now time to edit your crontab. Type in:

    crontab -e

If this is your first time running crontab as this user, you will be prompted to choose an editor. If you do not have a preference for one of the other listed options, nano is a safe choice.

You will then be dropped into an editing session and the file will be preloaded with comments explaining how to format a cron command.

Cron commands are formatted in the following way:

    minute hour day_of_month month day_of_week command_to_run

You can place a “\*” into any of the interval positions that you do not wish to specify. Cron will read this as all values of that field. So if we wanted to run a command at 3:10am every morning, we could add an entry like this:

    10 03 * * * command

If we wanted to run a command at noon on the first of every month, we could instead type:

    00 12 1 * * command

For our purposes, we we are going to assume that we want to run a snapshot backup every Sunday and Thursday at 3:30am.

We can implement this by typing a line in our crontab that looks like this:

    30 03 \* \* 0,4 DO\_TOKEN="AAABBB" /home/your\_user/.rvm/rubies/ruby-2.1.0/bin/ruby /home/your\_user/snapshot.rb drop\_id1 drop\_id2 ... drop\_idx

It is often useful to check that the command works by setting it to a few minutes from now and then seeing if it runs successfully. For instance, if it were 6:10pm right now, we could add a line that looks like this to check the command:

    14 18 \* \* \* DO\_TOKEN="AAABBB" /home/your\_user/.rvm/rubies/ruby-2.1.0/bin/ruby /home/your\_user/snapshot.rb drop\_id1 drop\_id2 ... drop\_idx

This will run the command in 4 minutes from now. Once you verify that the command is operating successfully (creating snapshots), you can edit it back to the schedule that you wish to keep.

## Conclusion

* * *

There are a number of ways to back up, and layering your backup strategies will provide the best coverage in the event of a problem. Using DigitalOcean snapshots is a simple way to provide an image level backup.

If you do automate this process, it is important to manage the number of snapshots that are being saved to your account. If you don’t check your account regularly and delete stale snapshots, you could quickly stack up quite a few images that are unneeded in your account. Please do your best to delete old snapshots when newer, working snapshots are in place.

By Justin Ellingwood
