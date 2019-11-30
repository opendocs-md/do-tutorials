---
author: Mitja Resman
date: 2013-10-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-and-use-yum-repositories-on-a-centos-6-vps
---

# How To Set Up and Use Yum Repositories on a CentOS 6 VPS

## Introduction

YUM Repositories are warehouses of Linux software (RPM package files). RPM package file is a Red Hat Package Manager file and enables quick and easy software installation on Red Hat/CentOS Linux. YUM Repositories hold a number of RPM package files and enable download and installation of new software on our VPS. YUM Repositories can hold RPM package files locally (local disk) or remotely (FTP, HTTP or HTTPS). YUM Configuration files hold the information required to successfully find and install software (RPM packages files) on our VPS.

Most common and largest CentOS YUM Repositories:

- [CentOS Official Repository Mirrors](http://www.centos.org/modules/tinycontent/index.php?id=30)
- [EPEL Repository Mirrors](http://mirrors.fedoraproject.org/publiclist/EPEL/)
- [RPMforge Repository](http://wiki.centos.org/AdditionalResources/Repositories/RPMForge)
- [ElRepo Repository](http://elrepo.org/tiki/tiki-index.php)

Advantages of installing software from YUM Repositories are:

- Easy Software Management - installing, updating, and deleting packages is simple
- Software Dependency Resolution - software dependencies are automatically resolved and installed
- Official Red Hat/CentOS Package Manager - YUM is official Red Hat/CentOS package manager

Sometimes the software we want to install on our CentOS VPS is not available from default Official CentOS Repositories. In situations like this, we can use one of the additional (Non-Official) CentOS YUM Repositories listed above. Additional repositories sometimes hold newer versions of software packages than Official CentOS Repositories.

## YUM Repository Configuration File

We can install new software on Red Hat/CentOS Linux with "yum install packagename" command from console. Running this command first checks for existing YUM Repository configuration files in /etc/yum.repos.d/ directory. It reads each YUM Repository configuration file to get the information required to download and install new software, resolves software dependencies and installs the required RPM package files.

YUM Repository configuration files must:

- be located in **/etc/yum.repos.d/** directory
- have **.repo extension** , to be recognized by YUM

**Available** YUM Repository configuration file options are:

- **Repository ID** - One word unique repository ID (example: [examplerepo])
- **Name** - Human readable name of the repository (example: name=Example Repository)
- **Baseurl** - URL to the repodata directory. You can use file://path if repository is located locally or [ftp://link](ftp://link), [http://link](http://link), [https://link](https://link) if repository is located remotely - HTTP Authentication available [http://user:password@www.<wbr>repo1.com/repo1</wbr>](http://user:password@www.repo1.com/repo1) (example: baseurl=[http://mirror.cisp.<wbr>com/CentOS/6/os/i386/</wbr>](http://mirror.cisp.com/CentOS/6/os/i386/))
- **Enabled** - Enable repository when performing updates and installs (example: enabled=1)
- **Gpgcheck** - Enable/disable GPG signature checking (example: gpgcheck=1)
- **Gpgkey** - URL to the GPG key (example: gpgkey=[http://mirror.cisp.com/<wbr>CentOS/6/os/i386/RPM-GPG-KEY-<wbr>CentOS-6</wbr></wbr>](http://mirror.cisp.com/CentOS/6/os/i386/RPM-GPG-KEY-CentOS-6))
- **Exclude** - List of the packages to exclude (example: exclude=httpd,mod\_ssl)
- **Includepkgs** - List of the packages to include (example: include=kernel)

**Required** YUM Repository configuration file options are:

- **Repository ID**
- **Name**
- **Baseurl**
- **Enabled**

### Step 1: Create YUM Repository configuration file

Use your favorite console text editor and create a new YUM Repository configuration file with .repo extension in /etc/yum.repos.d/ directory. To create a new file with "vi editor" run the following command from console:

    vi /etc/yum.repos.d/example.repo

### Step 2: Insert YUM Repository options

Insert the desired YUM Repository options to the newly created YUM Repository configuration file and save changes.

### Example YUM Repository Configuration file:

/etc/yum.repos.d/example.repo

    [examplerepo] name=Example Repository baseurl=[http://mirror.cisp.<wbr>com/CentOS/6/os/i386/
    enabled=1
    gpgcheck=1
    gpgkey=http://mirror.cisp.com/<wbr>CentOS/6/os/i386/RPM-GPG-KEY-<wbr>CentOS-6</wbr></wbr></wbr>](http://mirror.cisp.com/CentOS/6/os/i386/enabled=1gpgcheck=1gpgkey=http://mirror.cisp.com/CentOS/6/os/i386/RPM-GPG-KEY-CentOS-6)

## CentOS DVD ISO YUM Repository

CentOS DVD ISO holds a large number of software (RPM package files) which are available for installation during Red Hat/CentOS installation wizard. We can also use RPM package files from CentOS DVD ISO to create CentOS DVD ISO YUM Repository. This way we can install all of the software available on CentOS DVD ISO with "yum install packagename" command from VPS console even after we have completed Red Hat/CentOS installation wizard.

### Step 1: Download/Transfer CentOS DVD ISO

CentOS DVD ISO files are available for download at [http://mirror.centos.org/](http://mirror.centos.org/). We need to download or transfer CentOS DVD ISO to our VPS:

- **Transfer** - If we have already downloaded CentOS DVD ISO to a machine different than our VPS, we will need to transfer it from our machine to our cloud server via FTP or SSH. We can do this with software like WinSCP (free SFTP client and FTP) or similar.
- **Download** - We can download CentOS DVD ISO directly to our VPS with "wget" command from console (please change HTTP link accordingly):

    wget [http://mirror.lihnidos.org/<wbr>CentOS/6.4/isos/i386/CentOS-6.<wbr>4-i386-LiveDVD.iso</wbr></wbr>](http://mirror.lihnidos.org/CentOS/6.4/isos/i386/CentOS-6.4-i386-LiveDVD.iso)

### Step 2: Mount CentOS DVD ISO

To view the CentOS DVD ISO data, we first need to mount it on desired location. We usually mount CD-ROM, USB devices or ISO files to /mnt directory (if free to use). To mount CentOS DVD ISO run the following command from console (please change /path/to/iso and /mnt accordingly):

    mount -o loop /path/to/iso /mnt

### Step 3: Create YUM Repository Configuration file

To start using the newly created Custom YUM Repository we must create YUM Repository Configuration file with .repo extension, which must be placed to /etc/yum.repos.d/ directory. Instructions to create YUM Repository Configuration file are covered in the first topic of this article called "YUM Repository Configuration File".

### Example CentOS DVD ISO YUM Repository Configuration file:

/etc/yum.repos.d/centosdvdiso.<wbr>repo</wbr>

    [centosdvdiso] name=CentOS DVD ISO baseurl=file:///mnt enabled=1 gpgcheck=1 gpgkey=file:///mnt/RPM-GPG-<wbr>KEY-CentOS-6</wbr>

## Custom YUM Repository

Sometimes we need to create a Custom YUM Repository (handy when the VPS has no internet connection). We can create a Custom YUM Repository from a desired number of selected RPM package files. Custom YUM Repository only holds the RPM package files we want to include in.

### Step 1: Install "createrepo"

To create Custom YUM Repository we need to install additional software called "createrepo" on our cloud server. We can install "createrepo" by running the following command from console:

    yum install createrepo

### Step 2: Create Repository directory

We need to create a new directory that will be the location of our Custom YUM Repository and will hold the desired RPM package files. We can do this with the following command from console (choose a different /repository1 directory name if you like):

    mkdir /repository1

### Step 3: Put RPM files to Repository directory

If RPM package files are not yet present on our VPS we need to transfer them to our cloud server via FTP or SSH - use software like WinSCP (free SFTP client and FTP) or similar. We can also download RPM package files directly to our VPS (internet connection needed) with "wget" command from console (please change HTTP link accordingly):

    wget [http://mirror.lihnidos.org/<wbr>CentOS/6/os/i386/Packages/<wbr>NetworkManager-0.8.1-43.el6.<wbr>i686.rpm</wbr></wbr></wbr>](http://mirror.lihnidos.org/CentOS/6/os/i386/Packages/NetworkManager-0.8.1-43.el6.i686.rpm)

If RPM files are already present on our VPS, we need to Copy or Move these files to the newly created directory from "Step 2". We can move RPM files with the following command from console (please change /path/to/rpm and /repository1 accordingly):

    mv /path/to/rpm /repository1

We can copy RPM files with the following command from console (please change /path/to/rpm and /repository1 accordingly):

    cp /path/to/rpm /repository1

### Step 4: Run "createrepo"

Createrepo command reads through Custom YUM Repository directory from "Step 2" and creates a new directory called "repodata" in it. Repodata directory holds the metadata information for the newly created repository. Every time we add additional RPM package files to our Custom YUM Repository, we need to re-create Repository metadata with "createrepo" command. We can create new repository metadata by running the following command from console (please change /repository1 accordingly):

    createrepo /repository1

### Step 5: Create YUM Repository Configuration file

To start using the newly created Custom YUM Repository, we must create the corresponding YUM Repository Configuration file with .repo extension, which must be placed to /etc/yum.repos.d/ directory. Instructions to create YUM Repository Configuration file are covered in the first topic of this article called "YUM Repository Configuration File".

### Example Custom YUM Repository Configuration file:

/etc/yum.repos.d/custom.repo

    [customrepo] name=Custom Repository baseurl=file:///repository1/ enabled=1 gpgcheck=0

Submitted by: [@GeekPeekNet](http://www.geekpeek.net)
