---
author: Melissa Anderson
date: 2017-07-11
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-monitor-cpu-use-on-digitalocean-droplets
---

# How To Monitor CPU Use on DigitalOcean Droplets

## Introduction

The amount of memory, the size of the cache, the speed of reading from and writing to disk, and the speed and availability of processing power are all key elements that affect the performance of your infrastructure. In this article, we’ll focus on introductory CPU monitoring concepts and alert strategies. We’ll describe how to use two common Linux utilities, `uptime` and `top`, to learn about your CPU load and utilization, and how to set DigitalOcean Alert Policies to notify you about significant changes related to a Droplet’s CPU.

## Prerequisites

The two utilities we discuss, `uptime` and `top` are available as part of the default installation of most Linux distributions. To take advantage of DigitalOcean features like Alert Policies, you’ll need a DigitalOcean Droplet with Monitoring enabled.

The guide [How To Install and Use the DigitalOcean Agent for Monitoring](how-to-install-and-use-the-digitalocean-agent-for-monitoring) explains how to enable Monitoring on a new Droplet as well as how to add the Monitoring Agent to a Droplet that is already running.

## Background

Before we delve into the details of `uptime`, `top`, and DigitalOcean monitoring, we’ll consider how CPU usage is measured and what kind of patterns are desirable.

### CPU Load vs. CPU Utilization

CPU Load and CPU Utilization are two distinct ways of looking at the use of a computer’s processing power.

To conceptualize the main difference between the two, we can imagine the processors as cashiers in a grocery store and tasks as the customers. **CPU load** is like having a single checkout line where customers wait for the next cashier to become available. Load is essentially a count of the number of people in line, including the ones at the cash registers. The longer the line, the longer the wait. In contrast, **CPU utilization** is concerned only with how busy the cashiers are and has no idea how many customers are waiting in line.

More specifically, the tasks queue up to use the server’s CPUs. When one arrives at the top of the queue, it is scheduled to receive a certain amount of processing time. If it completes, then it exits; otherwise it returns to the end of the queue. In either case, the next task in line gets its turn.

**CPU load** is the length of the queue of scheduled tasks, including the ones being processed. Tasks can switch in a matter of milliseconds, so a single snapshot of the load isn’t as useful as the average of several readings taken over a period of time, so the load value is often provided as a **load average.**

The CPU load tells us about how much demand there is for CPU time. High demand can lead to contention for CPU time and degraded performance.

**CPU Utilization** , on the other hand, tells us how busy the CPUs are, without any awareness of how many processes are waiting. Monitoring utilization can show trends over time, highlight spikes, and help identify unwanted activity,

### Non-Normalized vs Normalized Values

On a single processor system, the total capacity is always 1. On a multiprocessor system, the data can be displayed in two different ways. The combined capacity of all the processors is counted as 100% regardless of the number of processors, and this is known as **normalized.** The other option is to count each processor as a unit, so that a 2-processor system in full use is at 200% capacity, a 4-processor system in full use is at 400% capacity, and so on.

In order to correctly interpret the CPU load or usage figures, we’ll need to know how many processors the server has.

### Displaying CPU Information

We can use the `nproc` command with the `--all` option to display the number of processors. Without the `--all` flag, it will display the number of processing units available to the current process, which will be less than the total number of processors if any are in use.

    nproc --all

    Output of nproc2

On most modern Linux distributions, we can also use the `lscpu` command, which displays not only the number of processors but also the architecture, model name, speed, much more:

    lscpu

    Output of lscpuArchitecture: x86_64
    CPU op-mode(s): 32-bit, 64-bit
    Byte Order: Little Endian
    CPU(s): 2
    On-line CPU(s) list: 0,1
    Thread(s) per core: 1
    Core(s) per socket: 1
    Socket(s): 2
    NUMA node(s): 1
    Vendor ID: GenuineIntel
    CPU family: 6
    Model: 63
    Model name: Intel(R) Xeon(R) CPU E5-2650L v3 @ 1.80GHz
    Stepping: 2
    CPU MHz: 1797.917
    BogoMIPS: 3595.83
    Virtualization: VT-x
    Hypervisor vendor: KVM
    Virtualization type: full
    L1d cache: 32K
    L1i cache: 32K
    L2 cache: 256K
    L3 cache: 30720K
    NUMA node0 CPU(s): 0,1
    Flags: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss syscall nx pdpe1gb rdtscp lm constant_tsc arch_perfmon rep_good nopl eagerfpu pni pclmulqdq vmx ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm vnmi ept fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid xsaveopt arat

Knowing the number of processors is important in understanding what the CPU-related output of different tools actually means.

### What are the Optimal Values for Load and Utilization?

Optimal CPU utilization varies depending on the kind of work the server is expected to do. Sustained high CPU usage comes at the price of less responsive interactivity with the system. It is often appropriate for computationally-intense applications and batch jobs to consistently run at or near full capacity. However, if the system is expected to serve web pages or provide responsive interactive sessions for services like SSH, then it may be desirable to have some idle processing power available.

Like many aspects of performance, learning about the specific needs of the services on the system and monitoring for unexpected changes are key to optimizing resources.

## Monitoring the CPU

There are a multitude of tools that can provide insight into a system’s CPU status. We’re going to look at two commands, `uptime` and `top`. Both are part of the default installation of most popular Linux distributions and are commonly used on-demand to investigate CPU load and utilization. In the examples that follow, we’ll examine the 2-core Droplet we profiled above.

### uptime

We’ll start with the `uptime` command to look at the CPU load which, while showing only basic CPU load average, can be helpful when a system is responding slowly to interactive queries because it requires few system resources.

uptime shows :

- the system time at the moment the command was run
- how long the server had been running
- how many connections users had to the machine
- the CPU load average for the past one, five, and fifteen minutes. 

     uptime

    Output 14:08:15 up 22:54, 2 users, load average: 2.00, 1.37, 0.63

In this example, the command was run at 2:08pm on a server that had been up for almost 23 hours. Two users were connected when `uptime` was run. Since this server has 2 CPUs, during the minute before the command was run, the CPU load average of 2.00 means that during that minute, on average, two processes were using the CPUs and no processes were waiting. The 5-minute load average indicates that for some of that interval, there was an idle processor about 60% of the time. The 15-minute value indicates that there was even more available processing time. The three figures together show an increase in load over the last fifteen minutes.

Uptime provides a helpful glance at the load average, but In order to get more in-depth information, we’ll turn to top.

### top

Like `uptime`, top is available on both Linux and Unix systems, but in addition to displaying the load averages for pre-set historical intervals, it provides periodic real-time CPU usage information as well as other pertinent performance metrics. Whereas `uptime` runs and exits, top stays in the foreground and refreshes at regular intervals.

    top

**The Header Block**  
The first five lines provide summary information about processes on the server:

    Outputtop - 18:31:30 up 1 day, 3:17, 2 users, load average: 0.00, 0.00, 0.00
    Tasks: 114 total, 1 running, 113 sleeping, 0 stopped, 0 zombie
    %Cpu(s): 7.7 us, 0.0 sy, 0.0 ni, 92.2 id, 0.0 wa, 0.0 hi, 0.0 si, 0.1 st
    KiB Mem : 4046532 total, 3238884 free, 73020 used, 734628 buff/cache
    KiB Swap: 0 total, 0 free, 0 used. 3694712 avail Mem

- The first line is almost identical to the output of `uptime`. Like `uptime` the one, five , and fifteen minute load averages are displayed. The only difference between this line and the output of `uptime` is that the beginning of the line shows the command name, `top`, and the time is updated each time `top` refreshes the data. 
- The second line provides a summary of the state of tasks: the total number of processes, followed by how many of them are running, sleeping, stopped, or zombie. 
- The third line tells us about the CPU utilization. These figures are normalized and displayed as percentages (without the % symbol) so that all the values on this line should add up to 100% regardless of the number of CPUs. 
- The fourth and fifth lines of the header information tell us about memory and swap usage, respectively.

Finally, the header block is followed by a table with information about each individual process, which we’ll look at in a moment.

In the example header block below, the one-minute load average exceeds the number of processors by .77, indicating a short queue with a little bit of wait time. The total CPU capacity is 100% utilized and there’s plenty of free memory.

    Outputtop - 14:36:05 up 23:22, 2 users, load average: 2.77, 2.27, 1.91
    Tasks: 117 total, 3 running, 114 sleeping, 0 stopped, 0 zombie
    %Cpu(s): 98.3 us, 0.2 sy, 0.0 ni, 0.0 id, 0.0 wa, 0.0 hi, 0.2 si, 1.3 st
    KiB Mem : 4046532 total, 3244112 free, 72372 used, 730048 buff/cache
    KiB Swap: 0 total, 0 free, 0 used. 3695452 avail Mem
     . . . 

Let’s take a look at each of the fields on the CPU line in more depth:

- **us, user: time running un-niced user processes**   
This category refers to user processes that were started with no explicit scheduling priority.  
More specifically, Linux systems [use the `nice` command to set a process’s scheduling priority](how-to-use-ps-kill-and-nice-to-manage-processes-in-linux#how-to-adjust-process-priorities), so “un-niced” means that `nice` wasn’t used to change the default value. The **user** and **nice** values account for all the user processes. High CPU use in this category may indicate a runaway process, and you can use the output in the process table to identify if this is the case. 

- **sy, system: time running kernel processes**   
Most applications have both user and kernel components. When the Linux kernel is doing something like making system calls, checking permissions, or interacting with devices on behalf of an application, the kernel’s use of the CPU is displayed here. When a process is doing its own work, it will appear in either the **user** figure described above or, if its priority was explicitly set using the `nice` command, in the **nice** figure that follows.

- **ni, nice: time running niced user processes**   
Like **user** this refers to process tasks that do not involve the kernel. Unlike **user,** the scheduling priority for these tasks was set explicitly. The niceness level of a process is indicated in the fourth column in the process table under the header **NI**. Processes with a niceness value between 1 and 20 that consume a lot of CPU time are generally not a problem because tasks with normal or higher priority will be able to get processing power when they need it. However, if tasks with elevated niceness, between -1 and -20, are taking a disproportionate amount of CPU, they can easily affect the responsiveness of the system and warrant further investigation. Note that many process that run with the highest scheduling priority, -19 or -20 depending on the system, are spawned by the kernel to do important tasks that affect system stability. If you’re not sure about the processes you see, it’s prudent to investigate them rather than killing them.

- **id, idle: time spent in the kernel idle handler**   
This figure indicates the percentage of time that the CPU was both available and idle. A system is generally in good working order with respect to CPU when the **user** , **nice** , and **idle** figures combined are near 100%. 

- **wa, IO-wait : time waiting for I/O completion**  
The IO-wait figure shows when the a processor has begun a read or write activity and is waiting for the I/O operation to complete. Read/write tasks for remote resources like NFS and LDAP will count in IO-wait as well. Like the idle time, spikes here are normal, but any kind of frequent or sustained time in this state suggests an inefficient task, a slow device, or a potential hard disk problem.

- **hi : time spent servicing hardware interrupts**   
This is the time spent on physical interrupts sent to the CPU from peripheral devices like disks and hardware network interfaces. When the **hardware interrupt** value is high, one of the peripheral devices may not be working properly.

- **si : time spent servicing software interrupts**   
Software interrupts are sent by processes rather than physical devices. Unlike hardware interrupts that occur at the CPU level, software interrupts occur at the kernel level. When the **software interrupt** value is using a lot of processing power, investigate the specific processes that are using the CPU. 

- **st: time stolen from this vm by the hypervisor**   
The “steal” value refers to how long a virtual CPU spends waiting for a physical CPU while the hypervisor is servicing itself or a different virtual CPU. Essentially, the amount of CPU use in this field indicates how much processing power your VM is ready to use, but which is _not_ available to your application because it is being used by the physical host or another virtual machine. Generally, seeing a steal value of up to 10% for brief periods of time is not a cause for concern. Larger amounts of steal for longer periods of time may indicate that the physical server has more demand for CPU than it can support. 

Now that we’ve looked at the summary of CPU usage that is supplied in `top`’s header block, we’ll take a look at the process table that appears below it, paying attention to the CPU-specific columns.

**The Process Table**  
All the processes running on the server, in any state, are listed below the summary block. The example below includes the first six lines of the process table from the `top` command in the section above. By default, the process table is sorted by the %CPU, so we see the processes that are consuming the most CPU first.

    Output
      PID USER PR NI VIRT RES SHR S %CPU %MEM TIME+ COMMAND
     9966 sammy 20 0 9528 96 0 R 99.7 0.0 0:40.53 stress
     9967 sammy 20 0 9528 96 0 R 99.3 0.0 0:40.38 stress
        7 root 20 0 0 0 0 S 0.3 0.0 0:01.86 rcu_sched
     1431 root 10 -10 7772 4556 2448 S 0.3 0.1 0:22.45 iscsid
     9968 root 20 0 42556 3604 3012 R 0.3 0.1 0:00.08 top
     9977 root 20 0 96080 6556 5668 S 0.3 0.2 0:00.01 sshd
    ...

The CPU% is presented as percent value, but it isn’t normalized, so on this two-core system, the total of all the values in the process table should add up to 200% when both processors are fully utilized.

**Note:** If you prefer to see normalized values, you can press SHIFT + I, and the display will switch from Irix mode to Solaris mode. This will display the same information, averaged across the server’s total number of CPUs, so that the amount being used won’t exceed 100%. When we switch to Solaris mode, we’ll get a brief message that Irix mode is off, and the values for our stress processes will switch from nearly 100% each to around 50% each.

    Output PID USER PR NI VIRT RES SHR S %CPU %MEM TIME+ COMMAND
    10081 sammy 20 0 9528 96 0 R 50.0 0.0 0:49.18 stress
    10082 sammy 20 0 9528 96 0 R 50.0 0.0 0:49.08 stress
     1439 root 20 0 223832 27012 14048 S 0.2 0.7 0:11.07 snapd
        1 root 20 0 39832 5868 4020 S 0.0 0.1 0:07.31 systemd
    

So far, we’ve examined at two Linux commands that are commonly used to look into CPU load and CPU utilization. In the next section, we’ll look into the CPU monitoring tools available at no additional cost for DigitalOcean Droplets.

## DigitalOcean Monitoring for CPU Utilization

By default, all Droplets display Bandwidth, CPU, and Disk I/O graphs when you click the Droplet name in the Control Panel:

![Screen capture of a Droplet name in the Control Panel](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/monitor-cpu/droplet-control.png)

These graphs visualize each resource’s use for the last 6 hours, 24 hours, 7 days and 24 hours. The CPU graph provides CPU utilization information. The dark blue line indicates CPU use by user processes. The light blue indicates CPU use by system processes. The values on the graphs and their detail are normalized so that the total capacity is 100% regardless of the number of virtual cores.

![Screen capture of the default CPU graph](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/monitor-cpu/default-cpu-graph.png)

The graphs let you see whether you’re experiencing intermittent or a sustained change in usage and are helpful in spotting changes in a server’s CPU usage pattern.

In addition to these default graphs, you can install the DigitalOcean Agent on a Droplet to collect and display additional data. The Agent also allows you to set Alert Policies for the system. [How To Install and Use the DigitalOcean Agent for Monitoring](how-to-install-and-use-the-digitalocean-agent-for-monitoring) can help you get set up.

Once the agent is installed, you can set alert policies to notify you about resource usage. The thresholds you choose will depend on the workload.

### Example Alerts

**Monitoring for Change: CPU above 1%**  
If you’re using a Droplet primarily for integrating and soak testing code, you might set an alert that’s just slightly above historical patterns so to detect if new code pushed to the server has increased CPU usage. For the graph above where CPU never reaches 1%, a threshold of 1% CPU use for 5 minutes could provide early warning about code-based changes affecting CPU use.

![Screen capture of the Alert Policy form filled out with the values in the previous paragraph](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/monitor-cpu/low-alert.png)

On most systems, there’s a good chance this threshold would be completely inappropriate, but by adjusting the duration and setting a threshold slightly above the average current load, you can learn early on when new code or new services impact the CPU utilization.

**Monitoring for an Emergency Situation: CPU Utilization above 90%**   
You might also want to set a threshold far above the average, one that you consider critical and which would warrant prompt investigation. For example, if a server that experienced sustained CPU use of 50% for five-minute intervals pretty regularly suddenly shot up to 90%, you might want to log in immediately to investigate the situation. Again, the thresholds are specific to the workload of the system.

## Conclusion

In this article, we’ve explored `uptime` and `top`, two common Linux utilities that provide insight into CPU on Linux systems, as well as how to use DigitalOcean Monitoring to see the historical CPU utilization on a Droplet and to alert you to changes and emergencies.

- To learn more about DigitalOcean Monitoring, see [An Introduction to DigitalOcean Monitoring](an-introduction-to-digitalocean-monitoring)

- For guidance on choosing between the Standard, High Memory, and High CPU plans, see [Choosing the Right Droplet for your Application](choosing-the-right-droplet-for-your-application).

- If you’re looking for more fine-grained monitoring services, you might want to learn more about using specific tools like [Zabbix](https://www.digitalocean.com/community/tags/monitoring?type=tutorials), [Icinga](how-to-install-icinga-and-icinga-web-on-ubuntu-16-04) , and [TICK](how-to-monitor-system-metrics-with-the-tick-stack-on-ubuntu-16-04) or review the complete list of [DigitalOcean Monitoring](https://www.digitalocean.com/community/tags/monitoring?type=tutorials) tutorials.
