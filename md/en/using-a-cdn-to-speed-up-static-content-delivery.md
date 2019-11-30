---
author: Hanif Jetha
date: 2018-08-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/using-a-cdn-to-speed-up-static-content-delivery
---

# Using a CDN to Speed Up Static Content Delivery

## Introduction

Modern websites and applications must often deliver a significant amount of static content to end users. This content includes images, stylesheets, JavaScript, and video. As these static assets grow in number and size, bandwidth usage swells and page load times increase, deteriorating the browsing experience for your users and reducing your servers’ available capacity.

To dramatically reduce page load times, improve performance, and reduce your bandwidth and infrastructure costs, you can implement a CDN, or **c** ontent **d** elivery **n** etwork, to cache these assets across a set of geographically distributed servers.

In this tutorial, we’ll provide a high-level overview of CDNs and how they work, as well as the benefits they can provide for your web applications.

## What is a CDN?

A content delivery network is a geographically distributed group of servers optimized to deliver static content to end users. This static content can be almost any sort of data, but CDNs are most commonly used to deliver web pages and their related files, streaming video and audio, and large software packages.

![Diagram of content delivery without a CDN](http://assets.digitalocean.com/articles/CDN/without-CDN.png)

A CDN consists of multiple _points of presence_ (PoPs) in various locations, each consisting of several _edge_ servers that cache assets from your _origin_, or host server. When a user visits your website and requests static assets like images or JavaScript files, their requests are routed by the CDN to the nearest edge server, from which the content is served. If the edge server does not have the assets cached or the cached assets have expired, the CDN will fetch and cache the latest version from either another nearby CDN edge server or your origin servers. If the CDN edge does have a cache entry for your assets (which occurs the majority of the time if your website receives a moderate amount of traffic), it will return the cached copy to the end user.

![Content Delivery Network (CDN) diagram](http://assets.digitalocean.com/articles/CDN/CDN.png)

This allows geographically dispersed users to minimize the number of hops needed to receive static content, fetching the content directly from a nearby edge’s cache. The result is significantly decreased latencies and packet loss, faster page load times, and drastically reduced load on your origin infrastructure.

CDN providers often offer additional features such as [DDoS](digitalocean-community-glossary#ddos-attack) mitigation and rate-limiting, user analytics, and optimizations for streaming or mobile use cases at additional cost.

## How Does a CDN Work?

When a user visits your website, they first receive a response from a DNS server containing the IP address of your host web server. Their browser then requests the web page content, which often consists of a variety of static files, such as HTML pages, CSS stylesheets, JavaScript code, and images.

Once you roll out a CDN and offload these static assets onto CDN servers, either by “pushing” them out manually or having the CDN “pull” the assets automatically (both mechanisms are covered in the [next section](using-a-cdn-to-speed-up-static-content-delivery#push-vs-pull-zones)), you then instruct your web server to rewrite links to static content such that these links now point to files hosted by the CDN. If you’re using a CMS such as WordPress, this link rewriting can be implemented using a third-party plugin like [CDN Enabler](https://wordpress.org/plugins/cdn-enabler/).

Many CDNs provide support for custom domains, allowing you to create a CNAME record under your domain pointing to a CDN endpoint. Once the CDN receives a user request at this endpoint (located at the edge, much closer to the user than your backend servers), it then routes the request to the Point of Presence (PoP) located closest to the user. This PoP often consists of one or more CDN edge servers collocated at an Internet Exchange Point (IxP), essentially a data center that Internet Service Providers (ISPs) use to interconnect their networks. The CDN’s internal load balancer then routes the request to an edge server located at this PoP, which then serves the content to the user.

Caching mechanisms vary across CDN providers, but generally they work as follows:

1. When the CDN receives a first request for a static asset, such as a PNG image, it does not have the asset cached and must fetch a copy of the asset from either a nearby CDN edge server, or the origin server itself. This is known as a cache “miss,” and can usually be detected by inspecting the HTTP response header, containing `X-Cache: MISS`. This initial request will be slower than future requests because after completing this request the asset will have been cached at the edge.
2. Future requests for this asset (cache “hits”), routed to this edge location, will now be served from cache, until expiry (usually set through HTTP headers). These responses will be significantly faster than the initial request, dramatically reducing latencies for users and offloading web traffic onto the CDN network. You can verify that the response was served from a CDN cache by inspecting the HTTP response header, which should now contain `X-Cache: HIT`.  

To learn more about how a specific CDN works and has been implemented, consult your CDN provider’s documentation.

In the next section, we’ll introduce the two popular types of CDNs: **push** and **pull** CDNs.

## Push vs. Pull Zones

Most CDN providers offer two ways of caching your data: pull zones and push zones.

**Pull Zones** involve entering your origin server’s address, and letting the CDN automatically fetch and cache all the static resources available on your site. Pull zones are commonly used to deliver frequently updated, small to medium sized web assets like HTML, CSS, and JavaScript files. After providing the CDN with your origin server’s address, the next step is usually rewriting links to static assets such that they now point to the URL provided by the CDN. From that point onwards, the CDN will handle your users’ incoming asset requests and serve content from its geographically distributed caches and your origin as appropriate.

To use a **Push Zone** , you upload your data to a designated bucket or storage location, which the CDN then pushes out to caches on its distributed fleet of edge servers. Push zones are typically used for larger, infrequently changing files, like archives, software packages, PDFs, video, and audio files.

## Benefits of Using a CDN

Almost any site can reap the benefits provided by rolling out a CDN, but generally the core reasons for implementing one are to offload bandwidth from your origin servers onto the CDN servers, and to reduce latency for geographically distributed users.

We’ll go through these and several of the other major advantages afforded by using a CDN below.

### Origin Offload

If you’re nearing bandwidth capacity on your servers, offloading static assets like images, videos, CSS and JavaScript files will drastically reduce your servers’ bandwidth usage. Content delivery networks are designed and optimized for serving static content, and client requests for this content will be routed to and served by edge CDN servers. This has the added benefit of reducing load on your origin servers, as they then serve this data at a much lower frequency.

### Lower Latency for Improved User Experience

If your user base is geographically dispersed, and a non-trivial portion of your traffic comes from a distant geographical area, a CDN can decrease latency by caching static assets on edge servers closer to your users. By reducing the distance between your users and static content, you can more quickly deliver content to your users and improve their experience by boosting page load speeds.

These benefits are compounded for websites serving primarily bandwidth-intensive video content, where high latencies and slow loading times more directly impact user experience and content engagement.

### Manage Traffic Spikes and Avoid Downtime

CDNs allow you to handle large traffic spikes and bursts by load balancing requests across a large, distributed network of edge servers. By offloading and caching static content on a delivery network, you can accommodate a larger number of simultaneous users with your existing infrastructure.

For websites using a single origin server, these large traffic spikes can often overwhelm the system, causing unplanned outages and downtime. Shifting traffic onto highly available and redundant CDN infrastructure, designed to handle variable levels of web traffic, can increase the availability of your assets and content.

### Reduce Costs

As serving static content usually makes up the majority of your bandwidth usage, offloading these assets onto a content delivery network can drastically reduce your monthly infrastructure spend. In addition to reducing bandwidth costs, a CDN can decrease server costs by reducing load on the origin servers, enabling your existing infrastructure to scale. Finally, some CDN providers offer fixed-price monthly billing, allowing you to transform your variable monthly bandwidth usage into a stable, predictable recurring spend.

### Increase Security

Another common use case for CDNs is DDoS attack mitigation. Many CDN providers include features to monitor and filter requests to edge servers. These services analyze web traffic for suspicious patterns, blocking malicious attack traffic while continuing to allow reputable user traffic through. CDN providers usually offer a variety of DDoS mitigation services, from common attack protection at the infrastructure level ([OSI layers 3 and 4](https://en.wikipedia.org/wiki/Denial-of-service_attack#Types)), to more advanced mitigation services and rate limiting.

In addition, most CDNs let you configure full SSL, so that you can encrypt traffic between the CDN and the end user, as well as traffic between the CDN and your origin servers, using either CDN-provided or custom SSL certificates.

## Choosing the Best Solution

If your bottleneck is CPU load on the origin server, and not bandwidth, a CDN may not be the most appropriate solution. In this case, local caching using popular caches such as NGINX or Varnish may significantly reduce load by serving assets from system memory.

Before rolling out a CDN, additional optimization steps — like minifying and compressing JavaScript and CSS files, and enabling web server HTTP request compression — can also have a significant impact on page load times and bandwidth usage.

A helpful tool to measure your page load speed and improve it is Google’s [PageSpeed Insights](https://developers.google.com/speed/pagespeed/insights/). Another helpful tool that provides a waterfall breakdown of request and response times as well as suggested optimizations is [Pingdom](https://www.pingdom.com/).

## Conclusion

A content delivery network can be a quick and effective solution for improving the scalability and availability of your web sites. By caching static assets on a geographically distributed network of optimized servers, you can greatly reduce page load times and latencies for end users. In addition, CDNs allow you to significantly reduce your bandwidth usage by absorbing user requests and responding from cache at the edge, thus lowering your bandwidth and infrastructure costs.

With plugins and third-party support for major frameworks like WordPress, Drupal, Django, and Ruby on Rails, as well as additional features like DDoS mitigation, full SSL, user monitoring, and asset compression, CDNs can be an impactful tool for securing and optimizing high-traffic web sites.
