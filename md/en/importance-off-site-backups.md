---
author: Mark Drake
date: 2018-01-17
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/importance-off-site-backups
---

# The Importance of Offsite Backups

## Introduction

Data has become some of the most valuable and irreplaceable assets for both individuals and businesses alike. Whether it consists of vacation photos, last year’s sales reports, or top-secret corporate strategy plans, the last thing you want is for your data to be lost or to fall into the wrong hands.

Backing up important files using an auxiliary storage device has become an everyday data protection practice, but this is not by itself a sure-fire solution. After all, backup media have the same risk of being damaged or stolen if they’re stored in the same place as the data’s source. In order to add an extra layer of protection to their valuable information, many people and companies choose to store their backups at an offsite venue to improve their odds against data loss.

In this article, we’ll go over some of the history and technology behind offsite data backups, as well as some practical matters to consider when remotely backing up your own data.

## A Bit About Auxiliary Storage

The history of auxiliary storage can be traced to the use of punched paper cards as a means of recording and storing information. Punch cards were invented in France in the early 18th century as a way to control patterns in a textile loom, and through the 1800s they were adapted into other uses ranging from calculating numbers to controlling player pianos. However, these initial use cases were solely used to instruct machinery and otherwise did not store data.

This changed in 1890 as a result of the United States census. The country’s rapidly growing population and new requirements for more detailed population information meant that the Census Bureau needed to drastically improve its efficiency so as to process the census data in a timely fashion. This need led Herman Hollerith, then an employee of the Census Bureau, to develop the Hollerith Electric Tabulating System which used punched cards to tabulate and store population data.

Hollerith’s punch card machines soon became the industry standard for data storage. His company would eventually be merged into the conglomerate that would form International Business Machines, Inc. — better known today as IBM — which would continue to produce punch cards into the 1970s. But as businesses and governments’ data storage needs grew, punched paper cards became severely limiting in terms of how much data they could hold and how quickly they could be read by machines.

Technology marched forward, though, and each successive generation of auxiliary storage media — from magnetic tape, to hard drives, floppy disks, and optical disks — brought an ever-increasing areal density (the quantity of information bits that can be stored in a given unit of physical space on computer storage media) while simultaneously reducing the cost-per-megabyte of storable data. They also enabled faster read and write speeds, making it easier for people and organizations to store and retrieve their data.

## Moving Data Offsite

The need to have backup copies of crucial data has been clear for as long as people have been keeping important records. Because originals could be lost or damaged in an accident, and malicious actors were likely to target valuable information for theft, the urgency to not just backup data but also keep that data secure was only underscored. This led many people and organizations over the years to protect their data at offsite storage facilities. However, storing backup data at an outside location brought a number of logistical challenges.

Before the ubiquity of software that can quickly transfer files over the internet, an organization’s only option for offsite storage involved physically moving auxiliary storage devices. Reels of magnetic tape or stacks of hard drives would need to be picked up from the central location and delivered to the storage vault by car, which could turn out to be extremely costly for institutions producing a great deal of data backups.

Because storage media deteriorates over time, it was important for companies building storage facilities to be aware of the physical limitations of data stores. Magnetic tape has an estimated shelf life of about 10 years, floppy disks have around 10 to 20, and older types of optical media can only be expected to last about about 5 to 10. This degradation meant that older storage devices would need to be regularly cycled out and replaced with new ones to prevent data loss. Regardless of what storage format is used, data backups have always been vulnerable to physical damage, particularly from fire, smoke, water, excessive heat, natural disaster, and even dust. Therefore, privately managed storage facilities would also have had to be built with controls against these environmental factors in place.

Finally, there was the ever-present issue of keeping data secure. Computer data encryption didn’t see broad implementation until the late 1970s, and even then it was primarily the tool of only the largest corporations and governments. This meant that, for the most part, your data’s security was only as strong as the lock on your door.

Altogether, this put a sizable burden of responsibility on the part of companies and institutions who would store their backups at their own offsite location. It wasn’t until the late 1980s that public cloud remote backup services began to appear. This was largely due to the fact that, until that time, modem speeds were too slow for internet data transfer to be practical. However, almost all of the remote backup services at this time were only focused on enterprise-level customers, leaving consumers and small businesses with few options for where to store offsite data backups.

## Backup Alternatives in the Cloud

With the rise of cloud computing in the mid-2000’s, along with an ample spike in the amount of data created by organizations and individuals, cloud-based data storage has become a convenient and affordable solution. Services like Crashplan or Backblaze are online backup services focused on business clients. Likewise, the rise of file hosting services like Dropbox has brought consumers the ability to backup their data remotely as well.

Although public cloud storage solutions like these do resolve many of the issues generated by previous methods of offsite data backups, there are still several risks associated with them. For example, remote data centers are at just as much risk of natural disasters as anywhere else. Of course, any reputable cloud storage provider is going to take steps to mitigate these particular risks with fire- and flood-resistant building materials and contingency plans for power outages. Also, like any other kind of company, a remote backup service could be sold, close down, or change its services, potentially leaving clients in a difficult place as they seek out alternatives.

Despite this, remote backup solutions still offer many desirable features. For example, they take care of all the logistics that go into managing a data vault, and their user-friendly interfaces lower the cost of training employees on how to use the service. Because these companies specialize in data backups and storage, they are usually better equipped to adapt to new technologies and innovative solutions than a company managing its own offsite data storage. Also, most cloud storage companies have redundancy built into their infrastructure to prevent outages or data loss, helping to ensure high availability of their customers’ data (although it never hurts to duplicate backups yourself, just in case).

All of this means that remote backup services are typically cheaper and easier than a completely self-managed offsite solution, but it’s important to research each one’s options and features before signing up for any remote backup service.

## Object Storage as a Backups Solution

In recent years, object storage solutions such as [DigitalOcean Spaces](https://www.digitalocean.com/products/object-storage/) have become popular alternatives to traditional offsite backup services. While public cloud backup services are popular for their simplicity and easy implementation, object storage services offer a level of flexibility that could be better suited for some companies’ storage needs.

Thanks to the design of the object storage model, object storage services can allow users to store very large amounts of data at a lower cost when compared to remote backup or file-sharing services. This makes them highly scalable, which is appealing to companies that are positioning themselves for future growth. Also, because of features like replication and erasure coding, object storage makes it easy to duplicate data, bringing another layer of protection against data loss and ensuring high availability.

Object storage isn’t always a perfect solution, especially if a user needs to make frequent changes to their data and perform lots of random data access. However, if you’re in need of relatively static archival storage, object storage services are a convenient, elegant, and highly affordable solution for securely storing your company’s key information.

## Conclusion

By now, it’s fairly common knowledge that performing regular backups is an important data security practice, but even small businesses and consumers are beginning to realize the value of storing their backups at an offsite location. After all, it only takes one stroke of bad luck and everything from family photos to corporate financials could be gone in an instant.

It has been a long road from the days of shipping cartons of punch cards to an off-site archive to the development of today’s cloud storage solutions. However, thanks to advances in technology and new paradigms like cloud-based backups and object storage services, both businesses and individuals now have the ability to securely backup their data at a remote location almost instantly.

For more information on storage and backups solutions, the following tutorials may be of interest:

- [Introduction to DigitalOcean Spaces](an-introduction-to-digitalocean-spaces)
- [How To Choose an Effective Backup Strategy for your VPS](how-to-choose-an-effective-backup-strategy-for-your-vps)
- [Object Storage vs. Block Storage Services](object-storage-vs-block-storage-services)
- [How To Back Up a Synology NAS to DigitalOcean Spaces](how-to-back-up-a-synology-nas-to-digitalocean-spaces)
