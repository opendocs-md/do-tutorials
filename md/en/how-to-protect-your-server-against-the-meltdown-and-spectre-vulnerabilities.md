---
author: Justin Ellingwood
date: 2018-01-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-protect-your-server-against-the-meltdown-and-spectre-vulnerabilities
---

# How To Protect Your Server Against the Meltdown and Spectre Vulnerabilities

## What are Meltdown and Spectre?

On January 4, 2018, multiple vulnerabilities in the design of modern CPUs were disclosed. Taking advantage of certain processor performance optimizations, these vulnerabilities—named **Meltdown** and **Spectre** —make it possible for attackers to coerce applications into revealing the contents of system and application memory when manipulated correctly. These attacks work because the normal privileges checking behavior within the processor is subverted through the interaction of features like speculative execution, branch prediction, out-of-order execution, and caching.

Meltdown was disclosed in [CVE-2017-5754](https://nvd.nist.gov/vuln/detail/CVE-2017-5754). Spectre was disclosed in [CVE-2017-5753](https://nvd.nist.gov/vuln/detail/CVE-2017-5753) and [CVE-2017-5715](https://nvd.nist.gov/vuln/detail/CVE-2017-5715).

For more detailed information, check out the how does meltdown work? and how does spectre work? sections below.

## Am I Affected by Meltdown and Spectre?

Meltdown and Spectre affect the majority of modern processors. The processor optimizations that are used in these vulnerabilities are a core design feature of most CPUs, meaning that most systems are vulnerable until specifically patched. This includes desktop computers, servers, and compute instances operating in Cloud environments.

Patches to protect against Meltdown are being released from operating system vendors. While updates are also being released for Spectre, it represents an entire class of vulnerabilities, so it will likely require more extensive ongoing remediation.

In cloud and virtualized environments, providers will need to update the underlying infrastructure to protect their guests. Users will need to update their servers to mitigate the impact within guest operating systems.

## How Can I Protect Myself?

Full protection against this class of vulnerability will likely require changes in CPU design.  
In the interim, software updates can provide mitigation against exploits by disabling or working around some of the optimized behavior that leads to these vulnerabilities.

Unfortunately, because these patches affect the optimization routines within the processor, mitigation patches may decrease the performance of your server. The extent of the slowdown is highly dependent on the type of work being performed, with I/O intensive processes experiencing the largest impact.

### Current Mitigation Patch Status

At the time of writing (January 9, 2018), Linux distributions have started to distribute patches, but no distributions are yet fully patched.

Distributions that have released kernel updates with **partial mitigation** (patched for Meltdown **AND** variant 1 of Spectre) include:

- CentOS 7: kernel 3.10.0-693.11.6
- CentOS 6: kernel 2.6.32-696.18.7

Distributions that have released kernel updates with **partial mitigation** (patched for Meltdown) include:

- Fedora 27: kernel 4.14.11-300
- Fedora 26: kernel 4.14.11-200
- Ubuntu 17.10: kernel 4.13.0-25-generic
- Ubuntu 16.04: kernel 4.4.0-109-generic
- Ubuntu 14.04: kernel 3.13.0-139-generic
- Debian 9: kernel 4.9.0-5-amd64
- Debian 8: kernel 3.16.0-5-amd64
- Debian 7: kernel 3.2.0-5-amd64
- Fedora 27 Atomic: kernel 4.14.11-300.fc27.x86\_64
- CoreOS: kernel 4.14.11-coreos

If your kernel is updated to at least the version corresponding to the above, some updates have been applied.

Operating systems that have **not yet released kernels with mitigation** include:

- FreeBSD 11.x
- FreeBSD 10.x

Ubuntu 17.04, which is reaching end of life on January 13, 2018 **will not receive patches**. Users are strongly encouraged to update or migrate.

**Warning:** We strongly recommend that you update or migrate off of any release that has reached end of life. These releases **do not** receive critical security updates for vulnerabilities like Meltdown and Spectre, which can put your systems and users at risk.

Because of the severity of this vulnerability, we recommend applying updates as they become available instead of waiting for a full patch set. This may require you to upgrade the kernel and reboot more than once in the coming days and weeks.

### How Do I Apply the Updates?

To update your servers, you need to update your system software once patches are available for your distribution. You can update by running your regular package manager to download the latest kernel version and then rebooting your server to switch over to the patched code.

**Note:** This article was written to be generally applicable and platform agnostic. If you are using DigitalOcean as your hosting provider and are running an older Droplet, you may have to perform an extra step before getting started.

DigitalOcean’s legacy kernel management system used externally managed kernels that could be changed in the control panel. If your Droplet uses this system, you will need to configure it to use **internal kernel management** before continuing (newer Droplets use this system automatically). To check whether you need to update to internal kernels and to learn how to make the switch, read our [How To Update a DigitalOcean Server’s Kernel](how-to-update-a-digitalocean-server-s-kernel#setting-up-the-droplet-for-internal-kernel-management) article.

For **Ubuntu** and **Debian** servers, you can update your system software by refreshing your local package index and then upgrading your system software:

    sudo apt-get update
    sudo apt-get dist-upgrade

For **CentOS** servers, you can download and install updated software by typing:

    sudo yum update

For **Fedora** servers, use the `dnf` tool instead:

    sudo dnf update

Regardless of the operating system, once the updates are applied, reboot your server to switch to the new kernel:

    sudo reboot

Once the server is back online, log in and check the active kernel against the list above to ensure that your kernel has been upgraded. Check for new updates frequently to ensure that you receive further patches as they become available.

## Additional Context

The Meltdown and Spectre family of vulnerabilities exploit performance-enhancing features within modern processors. A combination of processor features like speculative execution, privilege checking, out-of-order execution, and CPU caching allows read access to memory locations that should be out-of-bounds. The result is that unprivileged programs can be coerced into revealing sensitive data from their memory or accessing privileged memory from the kernel or other applications.

### How Does Meltdown Work?

The Meltdown vulnerability works by tricking a processor into reading an out-of-bounds memory location by taking advantage of flaws in a CPU optimization called speculative execution. The general idea works like this:

- A request is made for an illegal memory location.
- A second request is made to _conditionally_ read a valid memory location _if_ the first request contained a certain value.
- Using speculative execution, the processor completes the background work for both requests before checking that the initial request is invalid. Once the processor understands that the requests involve out-of-bounds memory, it correctly denies both requests. Though the results are not returned by the processor after the privilege checking code identifies the memory access as invalid, both of the accessed locations remain in the processor’s cache.
- A new request is now made for the valid memory location. If it returns quickly, then the location was already in the CPU cache, indicating that the conditional request earlier was executed. Iterative use of these conditionals can be used to understand the value in out-of-bounds memory locations.

Meltdown represents a specific vulnerability that can be patched against.

### How Does Spectre Work?

Spectre also works by tricking a processor to misuse speculative execution to read restricted values. The disclosure notices describe **two variants** with different levels of complexity and impact.

For **variant 1** of Spectre, the processor is tricked into speculatively executing a read before a bounds check is enforced. First, the attacker encourages the processor to speculatively reach for a memory location beyond its valid boundaries. Then, like Meltdown, an additional instruction conditionally loads a legal address into cache based on the out-of-bounds value. Timing how long it takes to retrieve the legal address afterwards reveals whether it was loaded into cache. This, in turn, can reveal the value of the out-of-bounds memory location.

**Variant 2** of Spectre is the most complicated both to exploit and mitigate against. Processors often speculatively execute instructions even when they encounter a conditional statement that cannot be evaluated yet. They do this by guessing the most likely result of the conditional using a mechanism called branch prediction.

Branch prediction uses the history of previous runs through a code path to pick a path to speculatively execute. This can be used by attackers to prime a processor to make an incorrect speculative decision. Because the branch selection history does not store absolute references to the decision, a processor can be fooled into choosing a branch in one part of the code even when trained in another. This can be exploited to reveal memory values outside of the acceptable range.

## Conclusion

Spectre and Meltdown represent serious security vulnerabilities; the full potential of their possible impact is still developing.

To protect yourself, be vigilant in updating your operating system software as patches are released by vendors and continue to monitor communications related to the Meltdown and Spectre vulnerabilities.
