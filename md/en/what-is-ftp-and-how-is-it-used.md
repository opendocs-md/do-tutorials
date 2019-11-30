---
author: Etel Sverdlov
date: 2012-08-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/what-is-ftp-and-how-is-it-used
---

# What is FTP and How Is It Used?

## What is FTP?

FTP is a way to transfer files between hosts over the internet. It is especially helpful as a way to upload or download files to or from a site quickly. FTP clients allow connections from both anonymous and registered users. When the goal is to limit who can perform the file transfer, the log in is often set up to require a username and password, while content that is meant to be distributed widely is often set up with an anonymous FTP login.

## How to Install FTP?

FTP is very easy to install on a virtual private server. Most FTP servers have very practical and usable defaults. Since FTP was not conceived as a very secure protocol, for example the login credentials are not encrypted, you can increase the security after installation by disabling anonymous login and chrooting your registered users into their own directories.

There is an large variety of FTP programs that can be installed on a VPS. Two that we find useful are ProFTPD or VSFTPD, and you can see how to download and configure them here, selecting whichever one you prefer.

[VSFTPD on Ubuntu 12.04](https://www.digitalocean.com/community/articles/how-to-set-up-vsftpd-on-ubuntu-12-04)

[VSFTPD on CentOS 6](https://www.digitalocean.com/community/articles/how-to-set-up-vsftpd-on-centos-6--2)

[ProFTPD on Ubuntu 12.04](https://www.digitalocean.com/community/articles/how-to-set-up-proftpd-on-ubuntu-12-04)

[ProFTPD on Centos 6](https://www.digitalocean.com/community/articles/how-to-set-up-proftpd-on-centos-6)

## Next Steps:

Once you have an FTP client installed and configured on your virtual server, you can connect to it through the browser or the command line. Access on the command line is fairly simple, with the user required to type in:

    ftp example.com

The prompt asks for a login and password, if you are doing an anonymous login, type in _anonymous_, and fill out the password with your email address. Once you connect, you can use the following commands to begin transferring files between machines:

**put** : copies the file from the local to the remote server

**mput** : copies multiple files from the local to the remote server

**get** : retrieves the file from the remote server and downloads it on the local machine

**mget** : retrieves multiple files from the remote server and downloads them to the local machine

**ls** : list the files in the current directory

**cd** : change the directory on the remote server

**help** : provides a list of available commands

**pwd** : provides you with the pathname of remote computer’s directory

**delete** : deletes a file on the remote server

**mdelete** : deletes multiple files on the remote server

**exit** : closes the FTP connection

Alternatively, to access a remote ftp server in your browser, type its address into the address bar. It should look like this:

    ftp://example.com

If you prefer to avoid the command line for most of your FTP work, you can download [Filezilla](http://filezilla-project.org/), an open-source FTP client and server.

## See More

This was just a brief overview of FTP. If you have any further questions about FTP programs or commands, feel free to post your questions in our [Q&A Forum](https://www.digitalocean.com/community/questions), and we’ll be happy to answer them.

By Etel Sverdlov
