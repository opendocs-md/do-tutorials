---
author: Justin Ellingwood
date: 2015-01-14
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/a-comparative-introduction-to-freebsd-for-linux-users
---

# A Comparative Introduction to FreeBSD for Linux Users

## Introduction

FreeBSD is a free and open source Unix-like operating system and a popular server platform. While FreeBSD and other BSD-based systems share much in common with systems like Linux, there are points where these two families diverge in important ways.

In this guide, we will briefly discuss some commonalities between FreeBSD and Linux before moving on to a more extended discussion on the important differences between them. Many of the points below can accurately be applied to the greater family of BSD-derived systems, but as a consequence of our focus, we will be referring mainly to FreeBSD as a representative of the family.

## Traits that FreeBSD and Linux Share

Before we begin examining areas where FreeBSD and Linux differ, let’s discuss in broad terms the things these systems have in common.

While the specific licensing that each family employs differs (we will discuss this later), both of these families of systems are free and open source. Users can view and modify the source as they desire and development is done in the open.

Both FreeBSD and Linux-based distributions are Unix-like in nature. FreeBSD has close roots to Unix systems of the past, while Linux was created from scratch as an open Unix-like alternative. This association informs decisions on the design of the systems, how components should interoperate, and the general expectations for what the system should look like and accomplish.

The common Unix-like behavior is mainly a result of both families being mostly [POSIX-compliant](http://en.wikipedia.org/wiki/POSIX). The overall feel and design of the systems are rather standardized and use similar patterns. The filesystem hierarchy is similarly divided, shell environments are the primary method of interaction for both systems, and the programming APIs share similar features.

Due to these considerations, FreeBSD and Linux distributions are able to share many of the same tools and applications. Some cases dictate that the versions or flavors of these programs differ between the systems, but applications can be ported more easily than they can with non-Unix-like systems.

With these points in mind, we will now move on to discuss the areas where these two families of operating systems diverge. Hopefully, these commonalities will help you more accurately digest the information regarding their differences.

## Licensing Differences

One of the most fundamental differences between FreeBSD and Linux systems is a matter of licensing.

The Linux kernel, GNU-based applications, and many pieces of software originating in the Linux world are licensed under some form of the GPL, or GNU General Public License. This license is often described as a “copyleft” license, which is a form of licensing that allows freedom to view, distribute, and modify the source code, while demanding that any derivative works maintain that licensing.

FreeBSD on the other hand, including the kernel and any tools created by FreeBSD contributors, licenses its software under a BSD license. This license type is more permissive than the GPL in that it does not require derivative work to maintain the licensing terms. What this means is that any person or organization can use, distribute, or modify the program without the need to contribute changes back or release the source of the work they are creating. The only requirements are that the original copyright and a copy of the BSD license are included in the source code or the documentation (depending on the release method) of the derivative work and that a provided disclaimer that limits liability is included. The main license is very short and can be found [here](http://choosealicense.com/licenses/bsd-2-clause/).

The appeal of each of these licensing types is almost entirely dependent upon philosophy and the needs of the user. The GPL licenses promote sharing and an open ecosystem above all other considerations. Proprietary software has to be very careful not to rely on GPL-based software. On the other hand, BSD licensed software can be freely incorporated into proprietary, closed source applications. This makes it more attractive to many businesses and individuals hoping to monetize their software because it is possible to sell the software directly and retain the source.

Developers tend to prefer one licensing philosophy over the other, but each has its advantages. Understanding the licensing of these systems can help us begin to understand some of the choices and philosophy that go into their development.

## The FreeBSD Lineage and its Implications

Another important difference between FreeBSD and Linux systems is the lineage and history of each system. Along with the licensing differences discussed above, this is perhaps the largest influencer of the philosophy that each camp adheres to.

Linux is a kernel developed by Linus Torvalds as a means of replacing the education-oriented, but restrictive MINIX system that he was using at the University of Helsinki. Combined with other components, many coming from the GNU suite, an operating system built on the Linux kernel has many Unix-like properties, despite it not being directly derived from a previous Unix OS. Since Linux was started from scratch without some of the inherited design choices and legacy considerations, it can differ significantly from systems with closer ties to Unix.

FreeBSD has many direct ties to its Unix heritage. BSD, or Berkeley Software Distribution, was a distribution of Unix created at the University of California, Berkeley, which extended the feature set of AT&T’s Unix operating system and had agreeable licensing terms. Later on, the decision was made to try to replace as much of the original AT&T operating system as possible with open source alternatives so that users would not be required to obtain an AT&T license to use BSD. Eventually, all components of the original AT&T Unix were rewritten under the BSD license and ported to the i386 architecture as 386BSD. FreeBSD was forked from this base in an effort to maintain, improve, and modernize the work that was already there, and eventually was rebased on an incomplete release called BSD-Lite for the sake of licensing issues.

Through the lengthy and multi-stage process of derivation, FreeBSD became unencumbered in terms of licensing, but maintained close ties to its past. The developers working to create the system have remained invested in the Unix way of doing things, probably because FreeBSD was always meant to operate as an openly licensed clone of Unix. These roots have influenced the direction of any further development and are the reason behind some of the choices we will discuss.

## A Separation of the Core Operating System from Additional Software

A key difference in terms of development effort and system design between FreeBSD and Linux distributions is the scope of the system. The FreeBSD team develops the kernel and the base operating system as a cohesive unit, while Linux technically refers to only the kernel, with the other components coming from a variety of sources.

This might seem like a small difference but actually affects how you interact with and manage each system. In Linux, a distribution might bundle together a select group of packages, ensuring that they interoperate together nicely. However, most of the components will come from a broad array of sources and the distribution developers and maintainers are tasked with molding them into a system that functions correctly.

In this sense, essential components are not much different from the optional packages available through the distribution’s repositories. The distribution’s package management tools are used to track and manage these components in exactly the same way. A distribution might maintain different repositories based on which teams are responsible for certain packages so that the core development team must only worry about a subset of the software available, but this is an organizational and focus difference and generally does not result in differences in the software management from a user’s perspective.

In contrast, FreeBSD maintains an entire core operating system. The kernel and a collection of software, many of which are created by the FreeBSD developers themselves, are maintained as a unit. It is not as simple to swap out components that are part of this core collection because it is, in a sense, a monolithic set of software. This allows the FreeBSD team to very closely manage the main operating system, ensuring tight integration and more predictability.

The software that is included in the core operating system is considered completely separate from the components offered as optional additions. FreeBSD offers a large collection of optional software, just as Linux distributions do, but this is managed separately. The core system is updated as a single unit independently and optional software can be updated individually.

## How Releases are Formed

Most Linux releases are the result of gathering software from a variety of sources and modifying it as necessary. The distribution maintainers decide which components to include in the installation media, which components to include in the distribution maintained repositories, etc. After testing the components together, a release containing the tested software is created.

In the last section, we learned that:

- A large portion of the FreeBSD operating system is developed by the FreeBSD team.
- The base operating system is the main output being produced.
- The base software is considered a cohesive whole.

These qualities lead to a different approach to releasing software than most Linux distributions. Because FreeBSD organizes things on the operating system level, all of the base components are maintained within a single source code repository. This has a few important implications.

First of all, since these tools are all developed in tandem in a single repository, a release is formed simply by selecting a revision of one of the branches of the repository. This is similar to the way that most software is released in that a stable point is selected from an organized code base.

Since the base operating system is all under active version control, this also means that users can “track” different branches or levels of stability depending on how well-tested they want their system components to be. Users do not have to wait for developers to sanction changes to get them on their system.

This is somewhat similar to users tracking different repositories organized by stability in certain Linux distributions. In Linux, you track a package repository, while in FreeBSD, you can track a branch of a centralized source repository.

## Software Differences and System Design

The remaining differences that we will discuss will be related to the software itself and the general qualities of the system.

### Supported Package and Source Installations

One of the key differences between FreeBSD and most Linux distributions from a user’s perspective is the availability and support of both packaged software and source installed software.

While most Linux distributions provide only pre-compiled binary packages of the distribution-supported software, FreeBSD contains both pre-built packages as well as a build system for compiling and installing from source. For most software, this allows you to choose between pre-compiled packages built with reasonable defaults and the ability to customize your software during the compilation process by building it yourself. FreeBSD does this through a system it calls “ports”.

The FreeBSD port system is a collection of software that FreeBSD knows how to build. An organized hierarchy representing this software is available within the `/usr/ports` directory where users can drill down to directories for each application. These directories contain a few files that specify the location where the source files can be obtained, as well instructions for the compiler about how to properly patch the source to work correctly with FreeBSD.

The packaged versions of software are actually produced from the ports system, making FreeBSD a source-first distribution with packages available for convenience. Your system can be comprised of both source-built and pre-packaged software and the software management system can adequately handle a combination of these two installation methods.

### Vanilla vs Customized Software

One decision that might seem a bit strange to users familiar with some of the more popular Linux distributions is that FreeBSD usually opts to provide upstream software unmodified where ever possible.

Many Linux distros make modifications to software in order to make it easier to connect with other components and to try to make management easier. Good examples of this tendency are the restructuring of common web server configuration hierarchies to make server configuration more modular.

While many users find these changes helpful, there are also drawbacks to this approach. One issue with making modifications is that it presumes to know what approach works best for users. It also makes software more unpredictable for users coming from other platforms, as it diverges from upstream conventions.

FreeBSD maintainers often _do_ modify software with patches, but these are generally more conservative changes than some Linux distributions’ package choices. In general, the modifications to software in the FreeBSD ecosystem are those necessary to make the software build and run correctly in a FreeBSD environment and those required to define some reasonable defaults. The configuration files that are placed on the filesystem generally aren’t heavily modified, so some extra work might need to be taken to get components to talk to one another.

### FreeBSD Flavors of Common Tools

Another aspect of FreeBSD systems that might cause confusion for Linux users is the availability of familiar tools that operate slightly differently than they would on Linux systems.

The FreeBSD team maintains its own version of a large number of common tools. While many of the tools found on Linux systems are from the GNU suite, FreeBSD often rolls its own variants for its operating system.

There are a few reasons for this decision. Since FreeBSD is responsible for developing and maintaining the core operating system, controlling the development of these applications and placing them under a BSD license is either essential or useful. Some of these tools also have close functional ties to the BSD and Unix tools from which they were derived, unlike the GNU suite, which in general tends to be less backwards compatible.

These differences often manifest themselves in the options and syntax of commands. You may be used to running a command in a certain way on your Linux machines, but these may not work the same on a FreeBSD server. It is important to always check the `man` pages of commands to get familiar with the options for FreeBSD variants.

### The Standard Shell

A related point that might cause some confusion is that the default shell in FreeBSD is not `bash`. Instead, FreeBSD uses the `tcsh` as its default shell.

This shell is an improved version of `csh`, which is the C shell developed for BSD. The `bash` shell is a GNU component, making it a poor choice as a default for FreeBSD. While both shells generally function in similar ways on the command line, scripting should not be done in `tcsh`. Using the basic Bourne shell `sh` is more reliable and avoids some of the well-documented pitfalls associated with `tcsh` and `csh` scripting.

It is also worth noting that it is very simple to change your shell to `bash` if you are more comfortable in that environment.

### A More Stratified Filesystem

We mentioned several times above that FreeBSD distinguishes between the base operating system and the optional components, or ports, that can be installed on top of that layer.

This has implications in how FreeBSD organizes components in the file structure. In Linux, executables are typically located in the `/bin`, `/sbin`, `/usr/sbin`, or `/usr/bin` directories depending on their purpose and how essential they are to core functionality. FreeBSD recognizes these differences, but also imposes another level of separation between components installed as part of the base system and those installed as ports. The base system software resides in one of the directories above. Any programs that are installed as a port or package are placed within `/usr/local/bin` or `/usr/local/sbin`.

The `/usr/local` directory contains a directory structure that mostly mirrors the structure found in the `/` or `/usr` directory. This is the main root directory for software installed through the ports system. Almost all of the configuration for ports is done through files located in `/usr/local/etc` while the base system configuration is kept in `/etc` as usual. This makes it easy to recognized whether an application is a part of the base system port and helps keep the filesystem clean.

## Final Thoughts

FreeBSD and Linux have many qualities in common but if you are coming from a Linux background, it is important to recognize and understand the ways in which they differ. Where their paths diverge, both systems have their advantages, and proponents from either camp can point to reasons for the choices that were made.

Treating FreeBSD as its own operating system instead of insisting on viewing it through a Linux lens will help you avoid fighting with the OS and will generally result in a better experience. By now, we hope that you have a fairly good understanding of the differences to look out for as you move forward.

If you are new to running FreeBSD servers, a good next step may be our guide on [getting started with FreeBSD](how-to-get-started-with-freebsd-10-1).
