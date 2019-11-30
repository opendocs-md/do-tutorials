---
author: Mitchell Anicas
date: 2015-03-31
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-map-user-location-with-geoip-and-elk-elasticsearch-logstash-and-kibana
---

# How To Map User Location with GeoIP and ELK (Elasticsearch, Logstash, and Kibana)

## Introduction

IP Geolocation, the process used to determine the physical location of an IP address, can be leveraged for a variety of purposes, such as content personalization and traffic analysis. Traffic analysis by geolocation can provide valuable insight into your user base as it allows you to easily see where they are coming from. This can help you make informed decisions about the ideal geographical location(s) of your application servers and who your current audience is.

In this tutorial, we will show you how to create a visual geo-mapping of the IP addresses of your application’s users, by using Elasticsearch, Logstash, and Kibana.

Here’s a short explanation of how it all works. Logstash uses a GeoIP database to convert IP addresses into a latitude and longitude coordinate pair, i.e. the approximate physical location of an IP address. The coordinate data is stored in Elasticsearch in `geo_point` fields, and also converted into a `geohash` string. Kibana can then read the Geohash strings and draw them as points on a map of the Earth. In Kibana 4, this is known as a Tile Map visualization.

Let’s take a look at the prerequisites now.

## Prerequisites

To follow this tutorial, you must have a working ELK stack. Additionally, you must have logs that contain IP addresses that can be filtered into a field, like web server access logs. If you don’t already have these two things, you can follow the first two tutorials in this series. The first tutorial will set up an ELK stack, and the second one will show you how to gather and filter Nginx or Apache access logs:

- [How To Install Elasticsearch, Logstash, and Kibana 4 on Ubuntu 14.04](how-to-install-elasticsearch-logstash-and-kibana-4-on-ubuntu-14-04)
- [Adding Logstash Filters To Improve Centralized Logging](adding-logstash-filters-to-improve-centralized-logging)

### Add geo\_point Mapping to Filebeat Index

Assuming you followed the prerequisite tutorials, you have already done this. However, we are including this step again in case you skipped it, because the TileMap visualization requires that your GeoIP coordinates are stored in Elasticsearch as a `geo_point` type.

On the server that Elasticsearch is installed on, download the Filebeat index template to your home directory:

    cd ~
    curl -O https://gist.githubusercontent.com/thisismitch/3429023e8438cc25b86c/raw/d8c479e2a1adcea8b1fe86570e42abab0f10f364/filebeat-index-template.json

Then load the template into Elasticsearch with this command:

    curl -XPUT 'http://localhost:9200/_template/filebeat' -d@filebeat-index-template.json

## Configure Logstash to use GeoIP

To get Logstash to store GeoIP coordinates, you need to identify an application that generates logs that contain a public IP address that you can filter as a discrete field. A fairly ubiquitous application that generates logs with this information is a web server, such as Nginx or Apache. We will use Nginx access logs as the example. If you’re using different logs, make the necessary adjustments to the example.

In the [Adding Filters to Logstash](adding-logstash-filters-to-improve-centralized-logging) tutorial, the Nginx filter is stored in a file called `11-nginx-filter.conf`. If your filter is located elsewhere, edit that file instead.

Let’s edit the Nginx filter now:

    sudo vi /etc/logstash/conf.d/11-nginx-filter.conf

Under the `grok` section, add the highlighted portion below:

11-nginx-filter.conf

    filter {
      if [type] == "nginx-access" {
        grok {
          match => { "message" => "%{NGINXACCESS}" }
        }
        geoip {
          source => "clientip"
        }
      }
    }

This configures the filter to convert an IP address stored in the `clientip` field (specified in **source** ). We are specifying the **source** as `clientip` because that is the name of the field that the Nginx user IP address is being stored in. Be sure to change this value if you are storing the IP address information in a different field.

Save and exit.

To put the changes into effect, let’s restart Logstash:

    sudo service logstash restart

If everything was configured correctly, Logstash should now be storing the GeoIP coordinates with your Nginx access logs (or whichever application is generating the logs). Note that this change is **not** retroactive, so your previously gathered logs will not have GeoIP information added.  
Let’s verify that the GeoIP functionality is working properly in Kibana.

## Connect to Kibana

The easiest way to verify if Logstash was configured correctly, with GeoIP enabled, is to open Kibana in a web browser. Do that now.

Find a log message that your application generated since you enabled the GeoIP module in Logstash. Following the Nginx example, we can search Kibana for `type: "nginx-access"` to narrow the log selection.

Then expand one of the messages to look at the table of fields. You should see some new `geoip` fields that contain information about how the IP address was mapped to a real geographical location. For example:

![Example GeoIP Fields](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/elk/geoip_kibana/geoip_fields.png)

**Note:** If you don’t see any logs, generate some by accessing your application, and ensure that your time filter is set to a recent time.

Also note that Kibana may not be able to resolve a geolocation for every IP address. If you’re just testing with one address and it doesn’t seem to be working, try some others before troubleshooting.

If, after all that, you don’t see any GeoIP information (or if it’s incorrect), you probably did not configure Logstash properly.

If you see proper GeoIP information in this view, you are ready to create your map visualization.

## Create Tile Map Visualization

**Note:** If you haven’t used Kibana visualizations yet, check out the [Kibana Dashboards and Visualizations Tutorial](how-to-use-kibana-dashboards-and-visualizations).

To map out the IP addresses in Kibana, let’s create a Tile Map visualization.

Click **Visualize** in the main menu.

Under **Create a new visualization** , select **Tile map**.

Under **Select a search source** you may select either option. If you have a saved search that will find the log messages that you want to map, feel free to select that search. We will proceed as if you clicked **From a new search**.

When prompted to **Select an index pattern** choose **filebeat-** \* from the dropdown. This will take you to a page with a blank map:

![Kibana default tile map building interface](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/elk/geoip_kibana/kibana-blank-map.png)

In the search bar, enter `type: nginx-access` or another search term that will match logs that contain geoip information. Make sure your time period (upper right corner of the page) is sufficient to match some log entries. If you see **No results found** instead of the map, you need to update your search terms or time.

Once you have some results, click **Geo Coordinates** underneath the **buckets** header in the left-hand column. The green “play” button will become active. Click it, and your geolocations will be plotted on the map:

![Kibana tile map with multiple points](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/elk/geoip_kibana/kibana-map-full.png)

When you are satisfied with your visualization, be sure to save it using the **Save Visualization** button (floppy disk icon) next to the search bar.

## Conclusion

Now that you have your GeoIP information mapped out in Kibana, you should be set. By itself, it should give you a rough idea of the geographical location of your users. It can be even more useful if you correlate it with your other logs by adding it to a dashboard.

Good luck!
