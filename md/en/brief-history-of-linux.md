---
author: Kathleen Juell
date: 2017-10-27
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/brief-history-of-linux
---

# A Brief History of Linux

## Introduction

In popular usage, “Linux” often refers to a group of operating system distributions built around the Linux kernel. In the strictest sense, though, Linux refers only to the presence of the kernel itself. To build out a full operating system, Linux distributions often include tooling and libraries from the GNU project and other sources. More developers have been using Linux recently to build and run mobile applications; it has also played a key role in the development of affordable devices such as Chromebooks, which run operating systems on the kernel. Within cloud computing and server environments in general, Linux is a popular choice for some practical reasons:

- Its distributions remain current and supported by communities of other developers. 
- It can run on a wide range of hardware and will install alongside pre-existing systems (a helpful trait in local development environments).
- It supports centralized software installation from pre-existing repositories. 
- Its resource requirements are low.
- It is often top of mind when developers are building application ecosystems and tooling for servers, leading to high levels of compatibility.
- It sustains necessary modifications to operating system behaviors.

Linux also traces its origins to the free and open-source software movement, and as a consequence some developers choose it for a combination of ethical and practical reasons:

- For some developers, using Linux represents a commitment to accessibility and freedom of expression.
- The Linux community is also a draw for some developers: when they have questions, they can consult the resources produced by this community or reach out directly to one of many active maintainers.  

To understand Linux’s role within the developer community (and beyond), this article will outline a brief history of Linux by way of Unix, and discuss some popular Linux distributions.

## Roots in Unix

Linux has its roots in Unix and Multics, two projects that shared the goal of developing a robust multi-user operating system.

### The Beginnings of Unix

Unix developed out of the Multics project iteration at the Bell Laboratories’ Computer Sciences Research Center. The developers working on Multics at Bell Labs and elsewhere were interested in building a multi-user operating system with single-level storage, dynamic linking (in which a running process can request that another segment be added to its address space, enabling it to execute that segment’s code), and a hierarchical file system.

Bell Labs stopped funding the Multics project in 1969, but a group of researchers, including Ken Thompson and Dennis Ritchie, continued working with the project’s core principles. In 1972-3 they made the decision to rewrite the system in C, which made Unix uniquely portable: unlike other contemporary operating systems, it could both move from and outlive its hardware.

Research and development at Bell Labs (later AT&T) continued, with Unix System Laboratories developing versions of Unix, in partnership with Sun Microsystems, that would be widely adopted by commercial Unix vendors. Meanwhile, research continued in academic circles, most notably the Computer Systems Research Group at the University of California Berkeley. This group produced the Berkeley Software Distribution (BSD), which inspired a range of operating systems, many of which are still in use today. Two BSD distributions of historical note are NeXTStep, the operating system pioneered by NeXT, which became the basis for macOS, among other products, and MINIX, an educational operating system that formed a comparative basis for Linus Torvalds as he developed Linux.

### Key Features of Unix

Unix is oriented around principles of clarity, portability, and simultaneity.

- Clarity: Unix’s modular design allows functions to run in a limited and defined way. Its file system is unified and hierarchical, which simplifies the manipulation of data. Unlike some of its predecessors, Unix implements hundreds (rather than thousands) of system calls, each of which is designed to be straightforward and clear in goal.
- Portability: By writing Unix in C, the group at Bell Labs positioned Unix for wide-scale use and adoption. C was designed to have low-level access to memory, minimal run-time support, and an efficient relationship between language and machine instructions. A basis in C means Unix is adaptable and easy to run on a variety of hardware. 
- Simultaneity: The Unix kernel is tailored toward the goal (shared by the Multics project) of sustaining multiple users and workflows. Kernel space remains distinct from user space in Unix, which allows multiple applications to run at the same time. 

## The Evolution of Linux

Unix raised important questions for developers, but it also remained proprietary in its earliest iterations. The next chapter of its history is thus the story of how developers worked within and against it to create [free and open-source](Free-vs-Open-Source-Software) alternatives.

### Open-Source Experiments

Richard Stallman was a central figure among the developers who were inspired to create non-proprietary alternatives to Unix. While working at MIT’s Artificial Intelligence Laboratory, he initiated work on the GNU project (recursive for “GNU’s not Unix!”), eventually leaving the Lab in 1984 so he could distribute GNU components as free software. The GNU kernel, known as GNU HURD, became the focus of the [Free Software Foundation (FSF)](http://www.fsf.org/), founded in 1985 and currently headed by Stallman.

Meanwhile, another developer was at work on a free alternative to Unix: Finnish undergraduate Linus Torvalds. After becoming frustrated with licensure for MINIX, Torvalds announced to a MINIX user group on August 25, 1991 that he was developing his own operating system, which resembled MINIX. Though initially developed on MINIX using the GNU C compiler, the Linux kernel quickly became a unique project with a core of developers who released version 1.0 of the kernel with Torvalds in 1994.

Torvalds had been using GNU code, including the GNU C Compiler, with his kernel, and it remains true that many Linux distributions draw on GNU components. Stallman has lobbied to expand the term “Linux” to “GNU/Linux,” which he argues would capture both the role of the GNU project in Linux’s development and the underlying ideals that fostered the GNU project and the Linux kernel. Today, “Linux” is often used to indicate both the presence of the Linux kernel and GNU elements. At the same time, embedded systems on many handheld devices and smartphones often use the Linux kernel with few to no GNU components.

### Key Features of Linux

Though the Linux kernel inherited many goals and properties from Unix, it differs from the earlier system in the following ways:

- Its core component is the kernel, which is developed independently from other operating system components. This means that Linux borrows elements from a variety of sources (such as GNU) to comprise an entire operating system. 
- It is free and open-source. Maintained by a community of developers, the kernel is licensed under the [GNU General Public License](https://www.gnu.org/licenses/gpl-3.0.en.html) (an offshoot of the FSF’s work on the GNU Project), and available for download and modification. The GPL stipulates that derivative work must maintain the licensing terms of the original software. 
- It has a monolithic kernel, similar to Unix, but it can dynamically load and unload kernel code on demand. 
- It has symmetrical multiprocessor (SMP) support, unlike traditional Unix implementations. This means that a single operating system can have access to multiple processors, which share a main memory and access to all I/O devices. 
- Its kernel is preemptive, another difference from Unix. This means that the scheduler can force a context switch on a driver or another part of the kernel while it is executing.
- Its kernel does not differentiate between threads and normal processes. 
- It includes a Command Line Interface (CLI) and can also include a Graphic User Interface (GUI). 

## Popular Linux Distributions

Developers maintain many popular Linux distributions today. Among the longest-standing is Debian, a free and open-source distribution that has 50,000 software packages. Debian inspired another popular distribution, Ubuntu, funded by Canonical Ltd. Ubuntu uses Debian’s deb package format and package management tools, and Ubuntu’s developers push changes back upstream to Debian.

A similar relationship exists between Red Hat, [Fedora](https://www.digitalocean.com/community/tags/fedora), and CentOS. Red Hat created a Linux distribution in 1993, and ten years later split its efforts into Red Hat Enterprise Linux and Fedora, a community-based operating system that utilizes the Linux kernel and elements from the GNU Project. Red Hat also has a relationship with the CentOS Project, another popular Linux distribution for web servers. This relationship does not include paid maintenance, however. Like Debian, CentOS is maintained by a community of developers.

## Conclusion

In this article, we have covered Linux’s roots in Unix and some of its defining features. If you are interested in learning more about the history of Linux and Unix variations (including FreeBSD), a good step might be our [series on FreeBSD](https://www.digitalocean.com/community/tutorial_series/getting-started-with-freebsd). Another option might be to consider our introductory [series on getting started with Linux](https://www.digitalocean.com/community/tutorial_series/getting-started-with-linux). You can also check out this [introduction to the filesystem layout in Linux](how-to-understand-the-filesystem-layout-in-a-linux-vps), this [discussion of how to use `find` and `locate` to search for files on a Linux VPS](how-to-use-find-and-locate-to-search-for-files-on-a-linux-vps), or this [introduction to regular expressions on the command line](an-introduction-to-regular-expressions).
