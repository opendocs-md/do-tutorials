---
author: Ben Schaechter
date: 2018-01-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/new-droplet-plans-frequently-asked-questions
---

# New Droplet Plans - Frequently Asked Questions

DigitalOcean [recently announced details](https://blog.digitalocean.com/new-droplet-plans) for new Droplet plans. Below is a list of frequently asked questions with answers to help give more clarity on these plans.

## When are the new Droplet plans available?

New Droplet plans are available immediately through the cloud control panel and API.

## Where can I see the details of these new Droplet plans?

All Droplet resources and rates are updated our [pricing page](https://www.digitalocean.com/pricing/).

## Will these new changes impact my currently active Droplets at all?

No. In order to decrease impact on existing applications and workflows, these plans are being introduced as completely new plans. This means there is no impact to your current Droplet and these changes will only impact newly created Droplets. To take advantage of the new plans, you must [resize your Droplet](how-to-resize-your-droplets-on-digitalocean).

## How does new pricing affect my current bill?

In order to take advantage of the new resources and plans, you must [resize your Droplet](how-to-resize-your-droplets-on-digitalocean). This means there is no impact to your current Droplet and these changes will only impact newly created Droplets or Droplets that you resize.

## How do I resize to these new Droplet plans?

You can resize from first generation Droplets to the new Standard Droplet plans assuming there are no local disk space constraints.

For more information, see: [How To Resize Your Droplets on DigitalOcean](how-to-resize-your-droplets-on-digitalocean)

## My application uses API slugs for the first generation Droplet plans - will my application be impacted?

No. You can continue using your existing API slugs that map to the same Droplet plans as they always have. To get access to the new Droplet plans, you’ll need to update the API slug. We will be supporting the First Generation Droplet slugs until **July 1st, 2018**.

## I noticed there are similar resources between some Standard and Optimized plans but Optimized is more expensive. Why is that?

Optimized Droplets’ vCPUs provide dedicated resources from best-in-class Intel Processors. These Droplets run on entirely different, compute optimized servers meant for different types of workloads that are CPU intensive such as CI/CD, batch processing and data analysis. These Droplets are meant to give you a consistent and reliable measure of performance at all times.

Standard Droplet vCPUs are shared resources that are able to burst up as resources are available. If you are less sensitive to maximum CPU performance at all times, these plans are good to use and priced a bit cheaper relative to Optimized.

For more information, see: [Choosing the Right Droplet for Your Application](choosing-the-right-droplet-for-your-application)

## I currently have an Optimized Droplet - how can I get it to have the updated amounts of SSD?

If you have an active Optimized Droplet - you can run either a power-cycle or combination of power-off/power-on events either through the Droplet’s page on the cloud control panel or via the API. When your Droplet has completed either of these events, you’ll see the updated SSD values.

All newly created Optimized Droplets will come with this local SSD by default upon creation.

## Will DigitalOcean be dropping prices again in the future?

DigitalOcean is always looking for ways to optimize efficiency and costs and will make pricing changes more frequently into the future. Our blog will share any pricing related changes as they happen.

## Why are High Memory Droplets being removed?

As a result of heavily upgrading the resources with the Standard Plans, we’ve made the decision to remove High Memory Droplets in their current form. We recommend customers using High Memory Droplets to begin taking advantage of the larger Standard Droplet plans with ample amounts of RAM and SSD.

The API will support High Memory Droplets created until **July 1st, 2018** , but we recommend transitioning over to the new Standard Droplet Plans before then. (If you have an active High Memory Droplet, it will simply continue to be charged at the same rate for the duration that it remains active.)

In the future, there is a possibility we may re-release the High Memory Droplets but do not have details on that at this time.
