---
author: Hathy A
date: 2018-01-08
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-build-android-roms-on-ubuntu-16-04
---

# How to Build Android ROMs on Ubuntu 16.04

## Introduction

[Android](https://www.android.com/) is the most popular operating system in the world today. Hundreds of different original equipment manufacturers, or OEMs, choose to install it on their devices because it is free, open source, and has a large ecosystem of apps and services built around it. Unfortunately, many OEMs don’t push over-the-air (OTA) updates for Android regularly. And other OEMs only provide updates for a limited period of time after a device’s launch. Additionally, OEMs tend to customize Android extensively to make sure that their devices sport a unique look and feel. Their customizations include alternative launchers, themed system user interfaces, and pre-installed apps.

If you want to remove all those customizations, or if you want to run the latest version of pure Android on your device, you can build new firmware for it yourself. In the Android modding community, such firmware is usually referred to as a ROM, short for Read Only Memory.

In this tutorial, you’ll build an Android Oreo ROM that’s based on the [Android Open Source Project](https://source.android.com/), or AOSP for short. To keep this tutorial device-independent and generic, we’ll be targeting only the AOSP emulator, but you can apply the same techniques for actual devices.

## Prerequisites

To be able to follow along, you’ll need:

- One Ubuntu 16.04 x64 server with at least 16 GB of RAM, 4 CPUs, and 120 GB of storage space set up by following [the Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04), including a sudo non-root user and a firewall. The compilation process requires a lot of RAM, and more CPUs will speed up compile time. In addition, the files you’ll be downloading and building are quite large. DigitalOcean has [High CPU Droplets](https://www.digitalocean.com/products/compute/high-cpu/) which might be a great fit for this project.
- Git installed by following [How To Install Git on Ubuntu 16.04](how-to-install-git-on-ubuntu-16-04).

## Step 1 — Start a Screen Session

Some of the commands you’ll execute in this tutorial can potentially run for hours. If the SSH connection between your PC and your server is interrupted while the commands are running, they’ll be terminated abruptly. To avoid such a situation, use the `screen` utility, which lets you run multiple console sessions in a single terminal. With screen, you can detatch from a running session and reattach to it later. If you’re new to Screen, learn more in [this tutorial on using Screen on Ubuntu](how-to-install-and-use-screen-on-an-ubuntu-cloud-server).

Start a new `screen` session.

    screen

When you run screen for the first time, you’ll be presented with a license agreement. Press **Enter** to accept the license.

From this point on, should your SSH connection fail, your long-running commands will continue to run in the background. Once you re-establish the SSH connection, you’ll be able to resume the session by running `screen -r`.

Next, let’s install the components we need to compile Android.

## Step 2 — Installing Dependencies

The AOSP source code is spread across several different Git repositories. To make it easier for users to download all those repositories, the AOSP community has created a command-line tool called [`repo`](https://storage.googleapis.com/git-repo-downloads/repo).

We’ll download the latest version of the tool using `wget` and store it in the `~/bin` directory. First, create the `~/bin` directory:

    mkdir -p ~/bin

Then download the `repo` script:

    wget 'https://storage.googleapis.com/git-repo-downloads/repo' -P ~/bin

**Note** : If you’re concerned about the security of running a script on your machine that you downloaded from another site, inspect the contents of the script:

    less ~/bin/repo

Once you’re comfortable with the script’s contents, continue with this tutorial.

Use `chmod` to grant your current user the permission to run `repo`.

    chmod +x ~/bin/repo

The `repo` tool uses Git internally and requires that you create a Git configuration specifying your user name and email address. Execute these commands to do that:

    git config --global user.name "your name"
    git config --global user.email "your_email@your_domain.com"

Android’s source code primarily consists of Java, C++, and XML files. To compile the source code, you’ll need to install OpenJDK 8, GNU C and C++ compilers, XML parsing libraries, ImageMagick, and several other related packages. Fortunately, you can install all of them using `apt`. Before you do so, make sure you update your server’s package lists.

    sudo apt-get update

Once the lists update, install the dependencies:

    sudo apt-get install openjdk-8-jdk android-tools-adb bc bison build-essential curl flex g++-multilib gcc-multilib gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev libesd0-dev liblz4-tool libncurses5-dev libsdl1.2-dev libssl-dev libwxgtk3.0-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc yasm zip zlib1g-dev

Once the dependencies download, we can use the `repo` script to get the Android source.

## Step 3 — Downloading the Source Code

We’ll use the `repo` script to peform a few tasks to prepare our workspace. Create a new directory to store the Android source you’re going to download:

    mkdir -p ~/aosp/oreo

You’ll work in this directory throughout the rest of this tutorial, so switch to it now:

    cd ~/aosp/oreo

The directory must be initialized with the AOSP [manifest repository](https://android.googlesource.com/platform/manifest), a special Git repository containing an XML file named `default.xml`, which specifies the paths of all the other Git repositories that together form the AOSP codebase.

Working with the entirety of the AOSP code tree can get cumbersome. Therefore, you must additionally specify the name of a specific revision or branch you are interested in. In this tutorial, because we’re building an Oreo ROM, we’ll use the `android-8.0.0_r33` branch, whose build ID is `OPD1.170816.025`. You can get a list of all available build IDs and branch names from AOSP’s official [Codenames, Tags, and Build Numbers](https://source.android.com/setup/build-numbers) page.

Furthermore, you won’t be needing the entire commit history of the code tree for this tutorial. You can save both time and storage space by truncating the history to a depth of `1`.

Accordingly, use the `repo init` command to initialize the directory and specify these options:

    repo init -u https://android.googlesource.com/platform/manifest -b android-8.0.0_r33 --depth=1

When prompted to enable color display, press **Y** , followed by **Enter**.

Finally, download the actual AOSP files from the various repositories by running the `repo sync` command:

    repo sync

The above command downloads over 30 GB of data, so be patient while it completes. Once it does, we’ll set up a cache to speed up compilation.

## Step 4 — Preparing a Compiler Cache

To speed up your builds, you can use a compiler cache. As its name suggests, a compiler cache helps you avoid recompiling portions of the ROM that are already compiled.

To enable the use of a compiler cache, set an environment variable named `USE_CCACHE`.

    export USE_CCACHE=1

Unless you have lots of free disk space, you wouldn’t want the cache to grow too large, so you can limit its size. if you are building your ROM for a single device, you can limit it to 15 GB. To do so, use the `ccache` command.

    prebuilts/misc/linux-x86/ccache/ccache -M 15G

You’ll see output that confirms you’ve made this change:

    OutputSet cache size limit to 15.0 Gbytes

There’s one more optimization we need to make before we can compile. Let’s do that next.

## Step 5 — Configuring Jack

The Jack server, which is responsible for building most of the Java-based portions of the ROM, requires a lot of memory. To avoid memory allocation errors, you can use an environment variable named `ANDROID_JACK_VM_ARGS` to specify how much memory Jack is allowed to use. Usually, allocating about 50% of your server’s RAM is sufficient. This environment variable also specifies other compilation settings.

Execute the following command to allocate 8 GB of RAM to the Jack server and preserve the default compilation options Jack needs:

    export ANDROID_JACK_VM_ARGS="-Xmx8g -Dfile.encoding=UTF-8 -XX:+TieredCompilation"

Now you’re ready to build your Android ROM.

## Step 6 — Starting the Build

The AOSP code tree contains a script named `envsetup.sh`, which has several build-related helper functions. While many of the helper functions, such as `mm`, `mma`, and `mmm`, serve as shortcuts for the `make` command, others such as `lunch` set important environment variables that, among other things, decide the CPU architecture of the ROM, and the type of the build.

Source the script to gain access to the helper functions.

    source build/envsetup.sh

    Outputincluding device/asus/fugu/vendorsetup.sh
    including device/generic/car/car-arm64/vendorsetup.sh
    including device/generic/car/car-armv7-a-neon/vendorsetup.sh
    including device/generic/car/car-x86_64/vendorsetup.sh
    including device/generic/car/car-x86/vendorsetup.sh
    including device/generic/mini-emulator-arm64/vendorsetup.sh
    including device/generic/mini-emulator-armv7-a-neon/vendorsetup.sh
    including device/generic/mini-emulator-mips64/vendorsetup.sh
    including device/generic/mini-emulator-mips/vendorsetup.sh
    including device/generic/mini-emulator-x86_64/vendorsetup.sh
    including device/generic/mini-emulator-x86/vendorsetup.sh
    including device/google/dragon/vendorsetup.sh
    including device/google/marlin/vendorsetup.sh
    including device/google/muskie/vendorsetup.sh
    including device/google/taimen/vendorsetup.sh
    including device/huawei/angler/vendorsetup.sh
    including device/lge/bullhead/vendorsetup.sh
    including device/linaro/hikey/vendorsetup.sh
    including sdk/bash_completion/adb.bash

Next, run `lunch` and pass the codename of your device to it, suffixed with a build type, which can be either `eng`, `userdebug`, or `user`. While the `eng` and `userdebug` build types result in ROMs that are best suited for testing purposes, the `user` build type is recommended for production use.

To build a test ROM that can run on the AOSP ARM emulator, pass `aosp_arm-eng` to the `lunch` command:

    lunch aosp_arm-eng

You’ll see this output, showing the environment settings:

    Output============================================
    PLATFORM_VERSION_CODENAME=REL
    PLATFORM_VERSION=8.0.0
    TARGET_PRODUCT=aosp_arm
    TARGET_BUILD_VARIANT=eng
    TARGET_BUILD_TYPE=release
    TARGET_PLATFORM_VERSION=OPD1
    TARGET_BUILD_APPS=
    TARGET_ARCH=arm
    TARGET_ARCH_VARIANT=armv7-a
    TARGET_CPU_VARIANT=generic
    TARGET_2ND_ARCH=
    TARGET_2ND_ARCH_VARIANT=
    TARGET_2ND_CPU_VARIANT=
    HOST_ARCH=x86_64
    HOST_2ND_ARCH=x86
    HOST_OS=linux
    HOST_OS_EXTRA=Linux-4.4.0-104-generic-x86_64-with-Ubuntu-16.04-xenial
    HOST_CROSS_OS=windows
    HOST_CROSS_ARCH=x86
    HOST_CROSS_2ND_ARCH=x86_64
    HOST_BUILD_TYPE=release
    BUILD_ID=OPD1.170816.025
    OUT_DIR=out
    AUX_OS_VARIANT_LIST=
    ============================================

Finally, run `make` to start the build. `make` supports parallel jobs, so you can speed up the build considerably by using the `-j` option to set the number of parallel jobs equal to the number of CPUs available in the server.

Use the `nproc` command to see how many CPUs you have:

    nproc

The command returns the number of CPUS:

    Output8

You can then use this number with `make` to specify parallel execution:

    make -j8

Even with 8 CPUs, you’ll have to wait for over an hour for the build to complete, provided there are no other CPU-intensive processes active on your server. The duration of the build is directly proportional to the amount of RAM and the number of CPUs you have. If you want quicker builds, consider using specialized [High CPU Droplets](https://www.digitalocean.com/products/compute/high-cpu/), which support up to 32 CPUs and 48 GB of memory.

**Note:** You will see many warning messages generated during the build. You can safely ignore them.

Once the ROM is ready, you should see a message saying the build completed successfully. You’ll also be able to see the exact duration of the build.

    Output...
    Creating filesystem with parameters:
        Size: 2147483648
        Block size: 4096
        Blocks per group: 32768
        Inodes per group: 8192
        Inode size: 256
        Journal blocks: 8192
        Label: system
        Blocks: 524288
        Block groups: 16
        Reserved block group size: 127
    Created filesystem with 2266/131072 inodes and 178244/524288 blocks
    [100% 63193/63193] Install system fs i... out/target/product/generic/system.img
    out/target/product/generic/system.img+ maxsize=2192446080 blocksize=2112 total=2147483648 reserve=22146432
    
    #### make completed successfully (01:05:44 (hh:mm:ss)) ####

Let’s verify that things built correctly.

## Step 7 — Verifying the Build

The output of the build process consists of multiple filesystem images, which together form the ROM. You’ll find them in the `out/target/product/generic/` directory.

    ls -l out/target/product/generic/*.img

    Output-rw-r--r-- 1 sammy sammy 69206016 Jan 5 18:51 out/target/product/generic/cache.img
    -rw-rw-r-- 1 sammy sammy 1699731 Jan 5 19:09 out/target/product/generic/ramdisk.img
    -rw-r--r-- 1 sammy sammy 2147483648 Jan 5 19:10 out/target/product/generic/system.img
    -rw-r--r-- 1 sammy sammy 576716800 Jan 5 19:09 out/target/product/generic/userdata.img

To test the ROM, you can try to boot up an emulator with it by running the `emulator` command. If you’re in a non-GUI environment, make sure you pass the `-no-window` and `-noaudio` flags to it.

    emulator -no-window -noaudio > /dev/null 2>&1 &

To check if the emulator was able to boot up successfully, wait for a minute and use the Android debug bridge tool, `adb`, to open a shell on the emulator.

    adb shell

If the ROM has no issues, you’ll see a prompt from a shell running on the emulator.

    Output* daemon not running; starting now at tcp:5037
    * daemon started successfully
    generic:/ #

Exit this shell by typing `exit` and pressing `ENTER`, or by pressing `CTRL+D`.

**Note:** If you try to open the shell before the emulator starts, you’ll see an error message informing you that the emulator is offline. Wait for a short while and try again.

### Troubleshooting

If your build failed, the most likely cause is insufficient memory. To fix it, first kill the Jack server by running the following command:

    jack-admin kill-server

Then start the build again, but with fewer parallel jobs allowed. For example, here’s how you can reduce the number of parallel jobs to just 2:

    make -j2

If your build failed because of insufficient disk space, you’re probably trying to build multiple times without cleaning up the results of previous builds. To discard the results of previous builds, you can run the following command:

    make clobber

Alternatively, you can add more disk space to your Droplet by using DigitalOcean’s [Block Storage](how-to-use-block-storage-on-digitalocean).

## Conclusion

In this tutorial, you successfully built an AOSP-based ROM for Android Oreo. The techniques you learned today are applicable to all forks of AOSP too, such as [Lineage OS](https://lineageos.org/) and [Resurrection Remix OS](http://www.resurrectionremix.com/). If you have experience developing Android apps, you might be interested in modifying small portions of the AOSP codebase to give your ROM a personal touch.

To learn more about building the AOSP source code, browse through the [Android Building forum](https://groups.google.com/forum/?fromgroups#!forum/android-building) on Google Groups.
