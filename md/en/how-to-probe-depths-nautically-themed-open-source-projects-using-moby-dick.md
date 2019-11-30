---
author: Mark Drake
date: 2019-04-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-probe-depths-nautically-themed-open-source-projects-using-moby-dick
---

# How To Probe the Depths of Nautically-Themed Open-Source Projects Using Moby Dick

## Introduction

Despite being a commercial failure after its first publication, Herman Melville’s allegorical adventure novel _Moby-Dick; or, The Whale_ is today one of the most popular and influential novels in the American canon. Artists as diverse as William Faulkner, Ralph Ellison, and Bob Dylan have acknowledged the novel’s impact on their work, and one can spot references to it in films, television, music, and, of course, open-source projects.

In this article, we will analyze several nautically-themed open-source projects and how they pay tribute to _Moby-Dick_.

**Warning:** While it isn’t necessary that you read _Moby-Dick_ prior to reading this article, this article does contain a few spoilers. If you haven’t read the novel but would like to, you may want to hold off from reading this article until you’ve finished it.

## Prerequisites

To follow along with this tutorial, you’ll need:

- Familiarity with 19th-century literature.
- An appreciation for nautical puns.
- An adventurous disposition. For example, whenever you find yourself growing grim about the mouth, you account it high time to get to sea as soon as you can.

## Docker

![Docker logo](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/april_fools_2019/docker.png)

[Docker](https://www.docker.com/) is an open-source program that performs operating system-level virtualization, also known as [_containerization_](https://en.wikipedia.org/wiki/Container_(virtualization)). The influence of _Moby-Dick_ is obvious with this project: Docker’s logo and mascot is a whale [affectionately known as Moby Dock](https://blog.docker.com/2013/10/call-me-moby-dock/). However, there are some substantial differences between Moby Dick and Moby Dock.

First, Moby Dock’s species isn’t immediately obvious. It’s clear from the beginning of the novel that Moby Dick is a sperm whale, and while it’s possible that Moby Dock is a sperm whale as well, there are several clues that suggest otherwise:

- **The head** : Sperm whales have distinctively large, block-shaped heads. Moby Dock, however, has a flat forehead with a snout that slopes smoothly downward to its jaw, which is more suggestive of a right whale or bowhead whale.
- **The blowhole** : Moby Dock is always seen from its left side. As any whaler worth their salt knows, a sperm whale’s blowhole always skews slightly to the left side of its head. No blowhole is visible in any known images of Moby Dock, another clue that it isn’t a sperm whale.
- **The fins** : Moby Dock doesn’t seem to have any pectoral fins. All sperm whales are born with pectoral fins, adding another strike to the “Moby Dock is a sperm whale” theory. That said, all whales have pectoral fins, so this begs the question of [whether or not Moby Dock is a whale at all](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/april_fools_2019/illiuminati.gif).

Another important difference between these Mobys is that Moby Dock is helpfully carrying a few stacks of containers; Moby Dick would never be so accommodating. In fact, one can easily imagine Moby Dick going out of his way to knock over such a neatly organized pile of shipping containers. Perhaps Moby Dock is meant to be seen as a warmer, friendlier cousin of Moby Dick. After all, it’s probably bad marketing to associate one’s product with a ferocious leviathan bent on destroying everything in its path.

## OpenFaaS

![OpenFaaS logo](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/april_fools_2019/openfaas.png)

[OpenFaaS](https://www.openfaas.com/) is an open-source project that aims to make serverless functions simple through the use of Docker containers, allowing users to run complex infrastructures with far greater flexibility and without the fear of vendor lock-in.

The OpenFaaS logo focuses entirely on a whale’s tail, which is significant because Melville dedicates an entire chapter to describing the tails of sperm whales. In it, Ishmael reveals his deep appreciation of whales’ tails:

> Such is the subtle elasticity of [the tail], that whether wielded in sport, or in earnest, or in anger, whatever be the mood it be in, its flexions are invariably marked by exceeding grace. Therein no fairy’s arm can transcend it.

The OpenFaaS whale is shown to be peaking its flukes, presumably as it is about to dive. In the same chapter, Ishmael opines that “excepting the sublime breach…this peaking of the whale’s flukes is perhaps the grandest sight to be seen in all animated nature.” Perhaps the OpenFaaS team chose a whale’s tail as their logo to convey the grace and power that OpenFaaS brings to managing functions. It could even be that the whale is “diving in” to the realm of functions as a service.

Because OpenFaaS is closely related to Docker, it’s obvious why the project’s logo also features a whale. However, are these supposed to be the _same_ whale? Let us not forget that Moby Dick was believed to be “ubiquitous”, with sailors swearing up and down that they had encountered him “in opposite latitudes at one and the same instant of time.” This may be a clue that Moby Dock and the OpenFaaS whale are indeed one and the same.

Perhaps in choosing this logo the OpenFaaS team was trying to signal their hope that the framework would become ubiquitous in future software projects. Interestingly, while an omnipresent whale may strike fear in the hearts of whalers, software is generally seen as safer and more secure if it’s widely used. The OpenFaaS team should be thankful that coders are generally less superstitious than whalers.

## Kubernetes

![Kubernetes logo](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/april_fools_2019/k8s.png)

[Kubernetes](https://kubernetes.io/) is an open-source container orchestration system that helps to automate the deployment, scaling, and management of applications. The name “Kubernetes” comes from the Greek word “κυβερνήτης,” which translates to English as “captain” or “helmsman.” Appropriately, its logo consists of a ship’s wheel, or helm, conveying the control and steadiness required to manage complex container orchestration with ease.

Curiously, the _Pequod_ doesn’t have a wheel; instead, it has a tiller made out of a whale’s jawbone. This is seen by some readers as underscoring the shared histories of Captain Ahab and the ship, as Ahab lost his leg to the great white whale and replaced it with a whalebone prosthesis.

Though a helm or tiller can convey steadiness and control, as the Kubernetes logo designers intended, _Moby-Dick_ shows us the deeper questions that the project maintainers might have brushed aside. Who is at the helm when it comes to Kubernetes? Even more, who is at the helm in our everyday lives? Do we drive software, or does software drive us? Of all these things the helm is the symbol.

## MySQL

![MySQL logo](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/april_fools_2019/mysql1.png)

[MySQL](https://www.mysql.com/) is the world’s most widely deployed open-source database management system (DBMS). MySQL’s logo features the outline of a dolphin, affectionately known as Sakila.

While dolphins aren’t prominently featured in the plot of _Moby-Dick_, Melville discusses them at length in one of the books famous pseudoscientific asides. In Chapter 32, “Cetology,” Ishmael refers to dolphins as “Huzza Porpoises,” so called because sailors see them as an omen of good luck:

> Their appearance is generally hailed with delight by the mariner.... If you yourself can withstand three cheers at beholding these vivacious fish, then heaven help ye; the spirit of godly gamesomeness is not in ye.

Mayhaps the MySQL developers chose a dolphin to represent their DBMS to impart this same sense of hopeful joy to those who use it. By associating the database with a dolphin, they hope users will see it as being similarly fast, agile, and fun-loving. After all, who doesn’t have fun running correlated subqueries?

## MariaDB

![MariaDB logo](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/april_fools_2019/mariadb.png)

[MariaDB](https://mariadb.com/) is a community-supported fork of MySQL, as indicated by its similarly nautical logo. Both the MariaDB and MySQL logos include the respective RDBMS’s name and feature an aquatic animal: in MariaDB’s case, this animal is a pinniped.

Interestingly, there’s some confusion about what kind of animal is depicted in the MariaDB logo. According to [the project’s trademarks page](https://mariadb.org/about/trademark/), the animal in the logo is a sea lion. However, [some](https://twitter.com/adysuciu/status/1045362622906994690) [members](https://twitter.com/peced/status/687608934635536384) of the MariaDB community see it as a seal. MariaDB’s official sources are fairly consistent in referring to their mascot as a sea lion, though [not always](https://twitter.com/mariadb/status/491359114572754945). Certainly, the mascot’s shape does seem to more closely resemble that of a sea lion, but it’s also missing the telltale ears which would distinguish it as such.

The idea that human perception is inherently biased and unreliable runs as a theme throughout the novel. Perhaps by keeping the pinniped’s species vague, the MariaDB team is making a Melvillian comment on how truth isn’t always obvious and, in some cases, can never be known for certain. Is it a seal or a sea lion? Is Moby Dick real or imagined? Is Vim or Emacs the superior text editor? Riddles like these abound throughout the world we live in, which, like a magician’s glass, to each and every man in turn but mirrors back his own mysterious self. Great pains, small gains for those who ask the world to solve them.

Of course, it’s also possible that the logo is simply meant to represent a sea lion. Perhaps when the MariaDB team asked the designer to draw ears, they responded [“I would prefer not to.”](https://en.wikipedia.org/wiki/Bartleby,_the_Scrivener)

## Conclusion

Clearly, Melville’s influence extends far beyond the realm of literature, and well into the world of open-source technology. As this article has highlighted, these five projects (and likely many more) pay homage to his great whaling tale through subtle references in their names and logos, as well as how they challenge our perceptions of truth and human nature.

We hope that by reading this article, you’ll go on to create your own Melville-inspired, nautically-themed, open-source project. Here are a few ideas to help you get started:

- **Ishmael** : an application that turns any server process into an [orphan process](https://en.wikipedia.org/wiki/Orphan_process).
- **Starbuck** : An uptime monitor that swears it will keep everything under control, but in the end just gives up and lets the system crash.
- **Stubb** : A program that purports to do lots of important work, but really just takes credit for work done by other applications.

**Note:** Some readers may be wondering why this article hasn’t yet mentioned DigitalOcean’s own Sammy the Shark. The simple reason is that Sammy has little in common with the sharks depicted in _Moby-Dick_. Throughout the novel, sharks are depicted as ravenous beasts dominated by instinct. Melville’s sharks eat anything and everything in their path, and are violent, dangerous creatures who pose a serious risk to the crew of the _Pequod_ (though not as great a risk as whales, apparently).

Clearly, Melville never encountered a shark like Sammy. After all, Sammy is a vegetarian, and a very friendly one at that!
