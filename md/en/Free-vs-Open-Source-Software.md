---
author: Mark Drake
date: 2017-10-30
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/Free-vs-Open-Source-Software
---

# The Difference Between Free and Open-Source Software

## Introduction

One aspect of software development that many people tend to forget about is how the software should be licensed. A software license dictates how the code can be used and distributed by licensees (the end users), which can make a significant impact on how widely the technology gets adopted. Most modern software is sold under a proprietary license which allows the publisher or creator to retain the intellectual property rights of the software.

However, there’s an alternative viewpoint which contends that this puts an unnecessary level of control into the hands of software publishers. By preventing licensees from copying and changing a software’s source code, the idea holds, proprietary software publishers stifle innovation and hold back the potential growth of new technologies. This stance inspired the creation of licenses which grant users the rights to study, change, and share the software’s source code to their liking. Software licensed in such a way is usually known by one of two names: “free software” or “open-source software.”

Broadly speaking, both terms refer to the same thing: software with few restrictions on how it can be used. From the perspective of their proponents, both free and open-source software are safer, more efficient, and work more reliably than their proprietary counterparts. Why, though, do we have two labels for the same thing? The answer involves a bit of history, and an understanding of the nuances that form two separate but closely related movements.

## A Little Background

The idea that an individual working with a piece of software should be allowed to view, edit, and share its source code without legal consequence is nothing new. Prior to the 1970s, software was typically distributed along with its source code, the reason being that software was usually hardware-specific and end users would have to modify it to run on their particular machine or to add special functionalities.

Most people who interacted with computers around this time did so in a strictly academic or research setting. This meant that computing resources were often shared, and changing software to create more efficient workflows or more reliable solutions was widely encouraged. For example, UC Berkeley’s Project Genie developed the Berkeley Timesharing System—a time-sharing operating system built from scratch—by hacking the source code of the lab’s SDS 930 computer.

As software became more complex and expensive to produce, though, software companies sought ways to halt the unbridled sharing of source code in order to protect their revenue streams and deny competitors access to their implementation. They began putting legal restrictions on their products, including copyrights and leasing contracts, and also started distributing their products under proprietary licenses. By the end of the 1970s, most software companies had stopped shipping software with the source code included. This led many longtime computer users to vocalize their dissatisfaction, and their ethos would eventually form the foundation of the Free Software Movement.

## The Beginnings of Free Software

The Free Software Movement was largely the brainchild of Richard Stallman. Stallman began his studies in computer science in the early 1970s before the rise of proprietary software licenses, and he worked as a researcher at the MIT Artificial Intelligence Laboratory through the early 1980s. Having been a member of the academic hacker community for over a decade, he had grown frustrated by the spread of proprietary software and came to see it as a violation of people’s rights to innovate and improve existing software.

In 1983, Stallman launched the GNU Project—an effort to create a complete operating system which would provide its users with the freedom to view, change, and share its source code. Stallman articulated his motivation for the project in the [_GNU Manifesto_](https://www.gnu.org/gnu/manifesto.html). In it, he states his conviction that proprietary licensing blocks community-driven software development, effectively siloing innovation and crippling the advancement of technology.

This, according to Stallman, puts an unfair burden on users and developers who would otherwise be able to change the code to suit their own needs or alter it to serve a new function. Thus, the GNU Project can be seen as both a response to the rise of proprietary software as well as a callback to the previous era of freely shared source code and collaborative software development.

In 1985, Stallman built on the GNU Project by founding the [Free Software Foundation](http://www.fsf.org/) (FSF), a nonprofit organization dedicated to promoting the concept of free software to the wider public. Stallman would also later develop the GNU General Public License, a software license which guarantees the rights of end-users to run, view, and share source code freely.

According to the FSF, for a piece of software to be considered truly “free,” its license must guarantee four essential freedoms to its users:

- The freedom to run the program as you wish, for any purpose.
- The freedom to study how the program works, and change it so it does your computing as you wish. Access to the source code is a precondition for this.
- The freedom to redistribute copies so you can help your neighbor.
- The freedom to distribute copies of your modified versions to others. By doing this you can give the whole community a chance to benefit from your changes. Access to the source code is a precondition for this.

The FSF considers any software that fails to meet each one of these criteria as non-free and, therefore, unethical.

## The Rise of Open Source

Stallman had chosen the label “free software” to relate the idea that users would be free to change and share source code as they saw fit. This has led to some confusion over the years, as many people assume “free software” refers to any software that can be obtained for zero cost (which would be more accurately labeled as “freeware” or “shareware”). The FSF famously explains the name choice with the line, “think of free as in free speech, not as in free beer.”

By the late 1990s, though, there was a growing worry among some GNU and Linux enthusiasts that this dual meaning would cause a large share of users to miss the philosophy behind free software and its advantages over proprietary code. The FSF had also become known for its hard-line ethical stance against proprietary software of all kinds. There was concern among some free software advocates that this approach was too unfriendly to business interests, and would ultimately hamper the spread of the Free Software Movement.

### The Cathedral and the Bazaar

In 1997 Eric S. Raymond, then a free software advocate and developer, wrote _The Cathedral and the Bazaar_, a widely-cited essay which compares two different development models used in various free software projects. “The Cathedral” refers to a top-down development model where an exclusive group of developers produce the code, exemplified by the development of GNU Emacs. “The Bazaar,” on the other hand, refers to a method in which code is developed publicly over the internet, as was the case for the development of the Linux kernel.

The essay’s central argument is that the Bazaar model is inherently more effective at finding and resolving software bugs, as more people are able to view and experiment with the source code. Thus, Raymond argued, utilizing a community-driven, bottom-up development process results in safer, more reliable software.

Partially in response to the ideas presented in _The Cathedral and the Bazaar_, Netscape released the source code of its Communicator web browser as free software in early 1998. (The Communicator source code would later form the basis of Mozilla FireFox 1.0). Inspired by the commercial potential that Netscape saw in this source code release, a group of free software enthusiasts (including Raymond, Linus Torvalds, Philip Zimmerman, and many others) sought to rebrand the Free Software Movement and shift its focus away from ethical or philosophical motives. The group chose “open source” as its label for freely shareable software in the hope that it would better reflect the business value of a collaborative, community-driven development model.

Shortly thereafter, the [Open Source Initiative](https://opensource.org/) (OSI) was founded by Raymond and Bruce Perens to encourage both the use of the new term as well as the spread of open-source principles. OSI also developed the [Open Source Definition](https://opensource.org/osd)—a list of ten principles which a software’s license must adhere to for it to be considered open-source:

1. **Free Redistribution** - The license shall not restrict any party from selling or giving away the software as a component of a larger software distribution containing programs from multiple sources. 
2. **Source Code** - The program must include source code, and must allow distribution in source code as well as compiled form. 
3. **Derived Works** - The license must allow modifications and derived works, and must allow them to be distributed under the same terms as the license of the original software.
4. **Integrity of The Author’s Source Code** - The license may restrict source-code from being distributed in modified form only if the license allows the distribution of "patch files” with the source code for the purpose of modifying the program at build time. 
5. **No Discrimination Against Persons or Groups** - The license must not discriminate against any person or group of persons.
6. **No Discrimination Against Fields of Endeavor** - The license must not restrict anyone from making use of the program in a specific field of endeavor.
7. **Distribution of License** - The rights attached to the program must apply to all to whom the program is redistributed without the need for execution of an additional license by those parties.
8. **License Must Not Be Specific to a Product** - The rights attached to the program must not depend on the program’s being part of a particular software distribution.
9. **License Must Not Restrict Other Software** - The license must not place restrictions on other software that is distributed along with the licensed software.
10. **License Must Be Technology-Neutral** - No provision of the license may be predicated on any individual technology or style of interface.

## The Differences Between Free and Open-Source Software

As far as most people are concerned, the difference in meaning between “free software” and “open-source software” is negligible, and comes from a slight difference in approach or philosophy. As the Open Source Initiative sees it, both terms mean the same thing, and they can be used interchangeably in just about any context. They simply prefer the “open source” label because they believe it provides a clearer description of the software and its creators’ intent for how it should be used.

For the “free software” camp, though, “open source” doesn’t fully convey the importance of the movement and the potential long-term social problems caused by proprietary software. The Free Software Foundation sees OSI as being too concerned with promoting the practical benefits of non-proprietary software (including its profitability and the efficiency of a community-driven development model), and not concerned enough with the ethical issue of restricting users’ rights to change and improve code on their own terms.

Whether or not a given piece of software is free or open-source depends on which license it’s distributed under and whether that license is approved by the Open Source Initiative, the Free Software Foundation, or both. There’s a good deal of overlap between which licenses are approved by which organization, but there are a few exceptions. For example, the NASA Open Source Agreement is an OSI-approved license which the FSF views as too restrictive. Thus, the FSF discourages anyone from using software distributed under that license. Generally speaking, though, there’s a good chance that if it can be described as free software, it will fit the definition of open-source software as well.

### Alternative Names

Over the years, several other names for this kind of software have been proposed to put an end to this debate. “Free and open-source software”—oftentimes shortened to “FOSS”—is one of the most widely used, and is considered to be a safe neutral between the two. The term “libre software” (“libre” being derived from several Romance languages and roughly meaning “the state of liberty”) has gained a following of its own, so much so that the acronym “FLOSS” (meaning “free/libre and open-source software) has also become fairly common.

It should be noted that both free and open-source software are distinct from software in the public domain. Free and open-source software defines its freedoms through its licensing, while public domain software may adhere to some of the same virtues but does so by falling outside the licensing system. An important distinction of both free and open-source software is that works based on free or open-source source code must also be distributed with a FOSS license. Software released into the public domain does not have this requirement.

Another issue with public domain software stems from the fact that not every country in the world recognizes non-copyrighted content. This makes it impossible to make a globally recognized statement that a piece of software is in the public domain. Thus neither the FSF nor the OSI encourage developers to release software into the public domain.

## Conclusion

The terms “free software” and “open-source software” are interchangeable for most contexts, and whether someone prefers one over the other usually comes down to a matter of semantics or their philosophical outlook. However, for many programmers that are looking to develop software and get it out to the public or for activists hoping to change the way people see and interact with technology, the difference can be an important one. Thus, when releasing new software, it’s essential to carefully weigh the pros and cons of different licenses—including proprietary licenses—and choose the one that best suits your particular needs.

If you’re interested in learning more about which software license is right for your next project, the Free Software Foundation’s [License List](http://www.gnu.org/licenses/license-list.html) provides detailed descriptions of both free and non-free licenses. Additionally, the Open Source Initiative’s [Licenses & Standards](https://opensource.org/licenses) page may also be of interest.
