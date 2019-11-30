---
author: Justin Ellingwood
date: 2016-08-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-raid-terminology-and-concepts
---

# An Introduction to RAID Terminology and Concepts

## Introduction

Storage is an important consideration when setting up a server. Almost all of the important information that you and your users care about will at one point be written to a storage device to save for later retrieval. Single disks can serve you well if your needs are straight forward. However, if you have more complex redundancy or performance requirements, solutions like RAID can be helpful.

In this guide, we will talk about common RAID terminology and concepts. We will discuss some of the benefits and shortcomings of arranging your devices into RAID arrays, talk about the differences in implementation technologies, and go over how different RAID levels affect your storage environment.

## What Is RAID?

RAID stands for **R** edundant **A** rrays of **I** ndependent **D** isks. By combining drives in different patterns, administrators can achieve greater performance or redundancy than the collection of drives can offer when operated individually. RAID is implemented as a layer in between the raw drives or partitions and the filesystem layer.

## When Is RAID a Good Idea?

The primary values that RAID provides are data redundancy and performance gains.

Redundancy is meant to help increase the availability of your data. This means that during certain failure conditions, like when a storage drive becomes faulty, your information is still accessible and the system as a whole can continue to function until the drive is replaced. This is _not_ meant as a backup mechanism (separate backups are always recommended with RAID as with any other type of storage), but instead is intended to minimize disruptions when problems do occur.

The other benefit that RAID offers in some scenarios is in performance. Storage I/O is often limited by the speed of a single disk. With RAID, data is either redundant or distributed, meaning that multiple disks can be consulted for each read operation, increasing total throughput. Write operations can also be improved in certain configurations as each individual disk might might be asked to write only a fraction of the total data.

Some drawbacks to RAID include increased management complexity and often a reduction in available capacity. This translates to additional costs for the same amount of usable space. Further expenses might be incurred through the use of specialized hardware when the array is not managed entirely in software.

Another drawback for array configurations that focus on performance without redundancy is the increased risk of total data loss. A set of data in these scenarios is entirely reliant on more than one storage device, increasing the total risk of loss.

## Hardware RAID, Software RAID, and Hardware-Assisted Software RAID

RAID arrays can be created and managed using a few different technologies.

### Hardware RAID

Dedicated hardware called RAID controllers or RAID cards can be used to set up and manage RAID independent from the operating system. This is known as **hardware RAID**. True hardware RAID controllers will have a dedicated processor for managing RAID devices.

This has a number of advantages:

- **Performance** : Genuine hardware RAID controllers do not need to take up CPU cycles to manage the underlying disks. This means no overhead for the management of the storage devices attached. High quality controllers also provide extensive caching, which can have a huge impact on performance.
- **Abstracting away complexity** : Another benefit of using RAID controllers is that they abstract the underlying disk arrangement from the operating system. Hardware RAID can present the entire group of drives as a single logical unit of storage. The operating system does not have to understand the RAID arrangement; it can just interface with the array as if it were a single device.
- **Availability at boot** : Because the array is managed entirely outside of software, it will be available at boot time, allowing the root filesystem itself to easily be installed on a RAID array.

Hardware RAID also has a few significant disadvantages.

- **Vendor lock-in** : Because the RAID arrangement is managed by the proprietary firmware on the hardware itself, an array is somewhat locked to the hardware used to create it. If a RAID controller dies, in almost all cases, it must be replaced with an identical or a compatible model. Some administrators recommend purchasing one or more backup controllers to use in the event that the first has a problem.
- **High cost** : Quality hardware RAID controllers tend to be fairly expensive.

### Software RAID

RAID can also be configured by the operating system itself. Since the relationship of the disks to one another is defined within the operating system instead of the firmware of a hardware device, this is called **software RAID**.

Some advantages of software RAID:

- **Flexibility** : Since RAID is managed within the operating system, it can easily be configured from available storage without reconfiguring hardware, from a running system. Linux software RAID is particularly flexible, allowing many different types of RAID configuration.
- **Open source** : Software RAID implementations for open source operating systems like Linux and FreeBSD are also open source. The RAID implementation is not hidden, and can easily be read and implemented on other systems. For instance, RAID array created on an Ubuntu machine can easily be imported into a CentOS server at a later time. There is little chance of losing access to your data due to software differences.
- **No additional costs** : Software RAID requires no specialty hardware, so it adds no additional cost to your server or workstation.

Some disadvantages of software RAID are:

- **Implementation-specific** : Although software RAID is not tied to specific hardware, it tends to be tied to the specific software implementation of RAID. Linux uses `mdadm`, while FreeBSD uses GEOM-based RAID, and Windows has its own version of software RAID. While the open source implementations can be ported over or read in some cases, the format itself will likely not be compatible with other software RAID implementations.
- **Performance overhead** : Historically, software RAID has been criticized for creating additional overhead. CPU cycles and memory are required to manage the array, which could be used for other purposes. Implementations like `mdadm` on modern hardware largely negates these concerns, however. CPU overhead is minimal and in most cases insignificant.

### Hardware-Assisted Software RAID (Fake RAID)

A third type of RAID called **hardware-assisted software RAID** , firmware RAID, or fake RAID, is also available. Typically, this is found in RAID functionality within motherboards themselves or in inexpensive RAID cards. Hardware-assisted software RAID is an implementation that uses firmware on the controller or card to manage the RAID, but uses the regular CPU to handle the processing.

Advantages of hardware-assisted software RAID:

- **Multi-operating system support** : Since the RAID is brought up during the early boot and then handed off to the operating system, multiple operating systems can use the same array, which might not be possible with software RAID.

Disadvantages of hardware-assisted software RAID:

- **Limited RAID support** : Usually, only RAID 0 or RAID 1 are available.
- **Requires specific hardware** : Like hardware RAID, hardware-assisted software RAID is tied to the hardware used to create and manage it. This issue is even more problematic when included in a motherboard, because a failure of the RAID controller can mean that you have to replace the entire motherboard to access the data again.
- **Performance overhead** : Like software RAID, no CPU is dedicated to managing the RAID. Processing must be shared with the rest of the operating system.

Most administrators stay away from hardware-assisted software RAID as it suffers from a combination of the pitfalls of the other two implementations.

## Terminology

Familiarity with some common concepts will help you understand RAID better. Below are some common terms you might come across:

- **RAID level** : An array’s RAID level refers to the relationship imposed on the component storage devices. Drives can be configured in many different ways, leading to different data redundancy and performance characteristics. See the section on [RAID levels](an-introduction-to-raid-terminology-and-concepts#raid-levels) for more information.
- **Striping** : Striping is the process of dividing the writes to the array over multiple underlying disks. This strategy is used by a number of different RAID levels (see the [next section](an-introduction-to-raid-terminology-and-concepts#raid-levels) for more details). When data is striped across an array, it is split into chunks, and each chunk is written to at least one of the underlying devices.
- **Chunk Size** : When striping data, chunk size defines the amount of data that each chunk will contain. Adjusting the chunk size to match the I/O characteristics you expect can help influence the relative performance of the array.
- **Parity** : Parity is a data integrity mechanism implemented by calculating information from the data blocks written to the array. Parity information can be used to reconstruct data if a drive fails. The calculated parity is placed to a separate device than the data it is calculated from and, in most configurations, is distributed across the available drives for better performance and redundancy.
- **Degraded Arrays** : Arrays that have redundancy can suffer different types of drive failures without losing data. When an array loses a device but is still operational, it is said to be in degraded mode. Degraded arrays can be rebuilt to fully operational condition once the failed hardware is replaced, but might suffer from reduced performance during the interim.
- **Resilvering** : Resilvering, or resyncing, is the term used for rebuilding a degraded array. Depending on the RAID configuration and the impact of the failure, this is done either by copying the data from the existing files in the array, or by calculating the data by evaluating the parity information.
- **Nested Arrays** : Groups of RAID arrays can be combined into larger arrays. This is usually done to take advantage of the features of two or more different RAID levels. Usually, arrays with redundancy (like RAID 1 or RAID 5) are used as components to create a RAID 0 array for increased performance.
- **Span** : Unfortunately, span has a few different meaning when discussing arrays.
  - In certain contexts, “span” can mean to join two or more disks together end-to-end and present them as one logical device, with no performance or redundancy improvements. This is also known as the linear arrangement when dealing with Linux’s `mdadm` implementation.
  - A “span” can also refer to the lower tier of arrays that are combined to form the next tier when discussing nested RAID levels, like RAID 10.
- **Scrubbing** : Scrubbing, or checking, is the process of reading every block in an array to make sure there are no consistency errors. This helps assure that the data is the same across the storage devices, and prevents situations where silent errors can cause corruption, especially during sensitive procedures like rebuilds.

## RAID Levels

The characteristics of an array are determined by the configuration and relationship of the disks, known as its **RAID level**. The most common RAID levels are:

### RAID 0

RAID 0 combines two or more devices by striping data across them. As mentioned above, striping is a technique that breaks up the data into chunks, and then alternatingly writes the chunks to each disk in the array. The advantage of this is that since the data is distributed, the whole power of each device can be utilized for both reads and writes. The theoretical performance profile of a RAID 0 array is simply the performance of an individual disk multiplied by the number of disks (real world performance will fall short of this). Another advantage is that the usable capacity of the array is simply the combined capacity of all constituent drives.

While this approach offers great performance, it has some very important drawbacks as well. Since data is split up and divided between each of the disks in the array, the failure of a single device will bring down the entire array and all data will be lost. Unlike most other RAID levels, RAID 0 arrays cannot be rebuilt, as no subset of component devices contain enough information about the content to reconstruct the data. If you are running a RAID 0 array, backups become extremely important, as your entire data set depends equally on the reliability of each of the disks in the array.

### RAID 1

RAID 1 is a configuration which mirrors data between two or more devices. Anything written to the array is placed on each of the devices in the group. This means that each device has a complete set of the available data, offering redundancy in case of device failure. In a RAID 1 array, data will still be accessible as long as a single device in the array is still functioning properly. The array can be rebuilt by replacing failed drives, at which point the remaining devices will be used to copy the data back to the new device.

This configuration also has some penalties. Like RAID 0, the theoretical read speed can still be calculated by multiplying the read speed of an individual disk by the number of disks. For write operations, however, theoretical maximum performance will be that of the slowest device in the array. This is due to the fact that the whole piece of data must be written to each of the disks in the array. Furthermore, the total capacity of the array will be that of the smallest disk. So a RAID 1 array with two devices of equal size will have the usable capacity of a single disk. Adding additional disks can increase the number of redundant copies of the data, but will not increase the amount of available capacity.

### RAID 5

RAID 5 has some features of the previous two RAID levels, but has a different performance profile and different drawbacks. In RAID 5, data is striped across disks in much the same way as a RAID 0 array. However, for each stripe of data written across the array, parity information, a mathematically calculated value that can be used for error correction and data reconstruction, will be written to one of the disks. The disk that receives the calculated parity block instead of a data block will rotate with each stripe that is written.

This has a few important advantages. Like other arrays with striping, read performance benefits from the ability to read from multiple disks at once. RAID 5 arrays handle the loss of any one disk in the array. The parity blocks allow for the complete reconstruction of data if this happens. Since the parity is distributed (some less common RAID levels use a dedicated parity drive), each disk has a balanced amount of parity information. While the capacity of a RAID 1 array is limited to the size of a single disk (all disks having identical copies of the data), with RAID 5 parity, a level of redundancy can be achieved at the cost of only a single disk’s worth of space. So, four 100G drives in a RAID 5 array would yield 300G of usable space (the other 100G would be taken up by the distributed parity information).

As with the other levels, RAID 5 has some significant drawbacks that must be taken into consideration. System performance can slow down considerably due to on-the-fly parity calculations. This can impact each write operation. If a disk fails and the array enters a degraded state, it will also introduce a significant penalty for read operations (the missing data must be calculated from the remaining disks). Furthermore, when the array is repairing after replacing a failed drive, each drive must be read and the CPU used to calculate the missing data to rebuild the missing data. This can stress the remaining drives, sometimes leading to additional failures, which results in the loss of all data.

### RAID 6

RAID 6 uses an architecture similar to RAID 5, but with double parity information. This means that the array can withstand any two disks failing. This is a significant advantage due to the increased likelihood of an additional disk failure during the intensive rebuild process after a fault has occurred. Like other RAID levels that use striping, the read performance is generally good. All other advantages of RAID 5 also exist for RAID 6.

As for disadvantages, RAID 6 pays for the additional double parity with an additional disk’s worth of capacity. This means that the total capacity of the array is the combined space of the drives involved, minus two drives. The calculation to determine the parity data for RAID 6 is more complex than RAID 5, which can lead to worse write performance than RAID 5. RAID 6 suffers from some of the same degradation problems as RAID 5, but the additional disk’s worth of redundancy guards against the likelihood of additional failures wiping out the data during rebuild operations.

### RAID 10

RAID 10 can be implemented a few different ways, which impacts its general characteristics:

- **Nested RAID 1+0**

Traditionally, RAID 10 refers to a nested RAID, created by first setting up two or more RAID 1 mirrors, and then using those as components to build a striped RAID 0 array across them. This is sometimes now called RAID 1+0 to be more explicit about this relationship. Because of this design, a minimum of four disks is required to form a RAID 1+0 array (RAID 0 striped across two RAID 1 arrays consisting of two devices each).

RAID 1+0 arrays have the high performance characteristics of a RAID 0 array, but instead of relying on single disks for each component of the stripe, a mirrored array is used, providing redundancy. This type of configuration can handle disk failures in any of its mirrored RAID 1 sets so long as at least one of disk in each RAID 1 remains available. The overall array is fault tolerant in an unbalanced way, meaning that it can handle different numbers of failures depending on where where they occur.

Because RAID 1+0 offers both redundancy and high performance, this is usually a very good option if the number of disks required is not prohibitive.

- **mdadm’s RAID 10**

Linux’s `mdadm` offers its own version of RAID 10, which carries forward the spirit and benefits of RAID 1+0, but alters the actual implementation to be more flexible and offer some additional advantages.

Like RAID 1+0, `mdadm` RAID 10 allows for multiple copies and striped data. However, the devices aren’t arranged in terms of mirrored pairs. Instead, the administrator decides on the number of copies that will be written for the array. Data is chunked and written across the array in several copies, making sure that each copy of a chunk is written to a different physical devices. The end result is that the same number of copies exist, but the array is not constrained as much by the underlying nesting.

This conception of RAID 10 has some notable advantages over the nested RAID 1+0. Because it doesn’t rely on using arrays as building blocks, it can use odd numbers of disks and has a lower minimum number of disks (only 3 devices are required). The number of copies to be maintained is also configurable. The management is simplified since you only need to address a single array and can allocate spares that can be used for any disk in the array instead of just one component array.

## Conclusion

The most appropriate RAID level for your server depends heavily on your intended use case and goals. Total cost and constraints imposed by your hardware can also have a significant impact during the decision making process.

To find out more about using Linux’s `mdadm` tool to set up RAID arrays, follow our guide on [creating arrays with mdadm on Ubuntu 16.04](how-to-create-raid-arrays-with-mdadm-on-ubuntu-16-04). Afterwards, it would be a good idea to follow our guide on [how to manage mdadm arrays on Ubuntu 16.04](how-to-manage-raid-arrays-with-mdadm-on-ubuntu-16-04) to learn how to manage existing arrays.
