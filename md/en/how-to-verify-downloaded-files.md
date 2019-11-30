---
author: Michael Holley
date: 2018-06-07
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-verify-downloaded-files
---

# How to Verify Downloaded Files

_The author selected the [Electronic Frontier Foundation](https://www.brightfunds.org/organizations/electronic-frontier-foundation-inc) to receive a $300 donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

You’ve probably downloaded some open-source software, such as a Linux distribution ISO, and next to the download link was a link to download a checksum of the file. Have you ever wondered what that checksum link was for? That checksum is used to verify the integrity of the file you just downloaded.

On February 20th, 2016, the website for Linux Mint, a popular Linux distribution, was [hacked](https://blog.linuxmint.com/?p=2994) and the ISO used to install the distro was compromised. Before the compromised ISO was discovered, many people downloaded and possibly installed a version of Linux Mint with a backdoor baked in.

This dangerous install could have been avoided at the user level if the individuals who downloaded the altered ISO performed a file verification to see if what they downloaded had the same checksum as the original file. The hacked ISO had a completely different checksum than the original ISO.

Though file verification can indicate that a file may have been hacked, it’s often more useful in showing the user that the file they downloaded is not quite right or has become altered during the download process. If a TCP packet was dropped during the download, the file you’ve downloaded may be just a hair off, and performing a file verification would let you know that what you downloaded is different than what is available on the source server.

In this tutorial, you’ll learn what file verification is, why it’s important, and how to do it on various operating systems using command-line tools.

## Prerequisites

For this article, you’ll use the command line tools for file verification that are built into every major operating system.

You’ll need a file to verify, as well as the MD5 and SHA1 checksums for that file.

We’ll use an Ubuntu install ISO for our file verifications. Download the [Ubuntu Minimal CD ISO](https://help.ubuntu.com/community/Installation/MinimalCD) for 64 bit PCs (amd64, x86\_64). While it’s downloading, take note of the MD5 and SHA1 sums next to the download link. You’ll use these checksums throughout the tutorial.

## How File Verification Works

File verification, also known as _hashing_, is the process of checking that a file you have on your machine is identical to the source file.. When you hash a file, you are left with a _checksum_, a random alpha numeric string with a set length. Hashing a file doesn’t encrypt the file and you can’t take a checksum and run it back through an algorithm to get the original source file.

The process to generate a checksum is often called a _one-way cryptographic function_. When you perform a hash on a file, it is “summarized” into a string of random characters. For example, let’s say you have a document that contains 1000 characters. When the file is hashed using the MD5 algorithm, the resulting checksum will be 32 random characters. If you were to hash a 2000 character long file, the resulting MD5 checksum is still 32 characters. Even if the source file was only 10 characters long, the MD5 checksum would still be 32 random characters.

Every time you perform a hash on the same file you will always get the same string of characters in the hash, as long as every bit of that file hasn’t changed. But if even one thing is different, like an extra space in the file, the checksum will be completely different.

There are two types of checksums you’ll typically see for file verifications, _MD5_ or _SHA_.

The MD5 algorithm receives a lot of criticism in the world of encryption for being easily hackable, but this isn’t a concern when it comes to file verification. When it comes to verification of a file’s integrity, the weakness of the tool for encryption doesn’t matter. That’s good for us because MD5 is a mature specification and faster than other methods at performing hashes.

Recently, there has been an increase in use of the SHA hashing algorithm for checksums since it’s the hashing algorithm used in some modern encryption. Unlike MD5, however, SHA has different versions and it’s important to use the correct version when checking. The version is identified as either a number like 1, 2, 3, or by the number of times SHA is run in succession, such as 256, 384, or 512. The checksum you use should specify which version of SHA to use. If the site only specifies a hash with the label SHA, with no number, then it’s safe to assume they are using SHA1.

For the purposes of file verification, both methods are equally valid. Though the algorithm is different, both will return a random string with a set length, although MD5 hashes are shorter than any of the SHA hashes.

**Note** : Sometimes PGP/GPG signatures are provided for file verification purposes as well. Those kinds of signatures aren’t very common, and more involved to check. They require you to download the checksum, the site’s public key, and to have `gpg` already set up on your system to perform the check. Those steps are beyond the scope of this tutorial.

Checking the hash on downloaded files provides two different assurances that are both worthwhile. First, with a matching checksum, you can be sure that the file you just downloaded is identical to the source and hasn’t been altered by a third party. And second, you know that the file hasn’t been corrupted or modified during transit. Both of these cases are important since, if either were to happen, the download you have could be harmful to your machine or may not work at all.

Now that you know what a checksum is and why you should perform a check on your files, let’s get to how to do it for your OS. We’ll start by looking at Linux.

## Performing File Verification on Linux

Most Linux distributions have command line tools for each hashing algorithm. The pattern of the tool name is ‘HASH-TYPE’ plus the word 'sum’. So to hash with MD5, the program name is `md5sum`. To hash with SHA 256, the command is `sha256sum`. If you’re not sure what the exact name is, type the hash algorithm name and then press tab twice and most distros will display all commands that start with that algorithm name. We’ll go over a couple popular checks below.

We’ll perform our first check using the MD5 hashing algorithm. Execute the `md5sum` command and pass it the path to the file you want to hash:

    md5sum mini.iso

The results will look something like this:

    Output8388f7232b400bdc80279668847f90da mini.iso

That random string, starting with '8388f’, is the checksum, and this is what you’ll need to compare with the checksum provided on the downloads page.

Since any modification to the file will result in a completely different checksum, to save time just check the first few characters and the last few are the same as the source instead of every character.

For example, if you wanted to quickly verify that the checksum for 'mini.iso’ is a match, verify that both checksums start with '8388f’ and end with 'f90da’. If both match then it’s highly likely (almost 100%) the full hash is the same.

If you want to be 100% sure, just copy and paste the checksum from the website under the output of the local check to see if every character lines up:

    Output8388f7232b400bdc80279668847f90da mini.iso
    8388f7232b400bdc80279668847f90da

Now let’s look at checking SHA hashes. The most common SHA hashing commands are `sha1sum` and `sha256sum`. Execute the `sha1sum` command by passing it the path to the file:

    sha1sum mini.iso

The results will look similar to this:

    Outputcce936c1f9d1448c7d8f74b76b66f42eb4f93d4a mini.iso

Compare the resulting value with the value on the web page to verify they match.

Now let’s look at verifying files on macOS.

## Performing File Verification on macOS

Unlike Linux, macOS only has two hashing commands (`md5` and `shasum`), instead of one for every algorithm. But we can still perform all the checks we need with just these tools.

Despite different applications and different operating systems, the resulting hash from these tools is the same on every OS.

Since `md5` is a standalone algorithm, it is its own command on macOS. Execute the `md5` command, passing it the path to the file you want to check:

    md5 mini.iso

The results will look like this:

    OutputMD5 (mini.iso) = 8388f7232b400bdc80279668847f90da

As you can see, the output on macOS is not exactly the same as the output on Linux, but it still shows the filename and 32 character random string. Compare the characters with the original MD5 checksum and ensure that they match.

Now let’s look at verifying SHA checksums. macOS has one utility used to perform any SHA check called `shasum`. When running it, you provide the type of SHA check you want as an argument.

Execute the following command, specifying SHA1 by using the `-a` flag:

    shasum -a 1 mini.iso

The results will look like this:

    Outputcce936c1f9d1448c7d8f74b76b66f42eb4f93d4a mini.iso

Compare this value to the original file’s SHA1 hash. If they don’t match, you should try downloading the file and checking its hash again.

If you needed to perform a SHA 256 check, the command would be `shasum -a 256 mini.iso`. If you don’t provide the type, it defaults to SHA1.

Next, let’s look at verifying files on Windows.

## Performing File Verification on Windows

Windows 7 and later versions include the `certutil` app that can handle all of our hashing needs. The output looks very different from Linux and macOS, but the checksum will be the same and just as valid. Both of the examples that follow use PowerShell.

The format of the command is `certutil -hashfile path/to/file ALGORITHM`.

The command 'certutil’ is not case-sensitive so 'CertUtil’, 'certUtil’, and 'certutil’ are all valid. The algorithm, however, is case-sensitive, meaning 'md5’ won’t work and you would need to type 'MD5’.

To verify the `mini.iso` file’s MD5 hash, execute this command:

    certutil -hashfile mini.iso MD5

The results will look like this:

    OutputMD5 hash of file mini.iso:
    8388f7232b400bdc80279668847f90da
    CertUtil: -hashfile command completed successfully.

For the SHA algorithm, we’ll execute the same command, but we’ll use `SHA1` instead of `MD5`.

THe number after `SHA` specifies the different version or iterations of SHA. So we use `SHA` or `SHA1` for SHA1 hashing, or `SHA256` if we needed the SHA 256 algorithm.

    certutil -hashfile mini.iso SHA1

The results will look like this:

    OutputSHA1 hash of mini.iso:
    cce936c1f9d1448c7d8f74b76b66f42eb4f93d4a
    CertUtil: -hashfile command completed successfully.

Compare the resulting hash to the one on the download page to ensure they match.

## Conclusion

Whether you’re making sure a file you just downloaded wasn’t corrupted during download or verifying that a nefarious person hasn’t hacked the download server, the extra time it takes to check a file’s hash is well worth the effort.

If the command line is a bit too inconvenient for easy file verification, here are a   
few GUI based tools you can use instead:

- macOS: [HashTab](https://itunes.apple.com/us/app/hashtab/id517065482?mt=12)
- Linux: [GtkHash](https://gtkhash.sourceforge.io/)
- Windows: [HashTab](http://implbits.com/products/hashtab/) or [HashCheck](http://code.kliu.org/hashcheck/)
