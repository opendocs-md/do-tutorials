---
author: Melissa Anderson
date: 2016-09-19
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-install-r-on-ubuntu-16-04-2
---

# How To Install R on Ubuntu 16.04

## Introduction

R is a popular open source programming language that specializes in statistical computing and graphics. It is widely used for developing statistical software and performing data analysis. R is easily extensible, and the community is known for continuously adding user-generated packages for specific areas of study, which makes it applicable to many fields.

In this tutorial, we will install R and show how to add packages from the official [Comprehensive R Archive Network (CRAN)](http://cran.r-project.org/).

## Prerequisites

To follow along, you will need an Ubuntu 16.04 server with:

- **a minimum of 1GB of RAM**
- **a non-root user with `sudo` privileges.** To learn how to set this up, follow our [initial server setup guide](initial-server-setup-with-ubuntu-16-04).

Once these prerequisites are in place, you’re ready to begin.

## Step 1 — Installing R

R is a fast-moving project, and the latest stable version isn’t always available from Ubuntu’s repositories, so we’ll start by adding the external repository maintained by CRAN:

**Note:** CRAN maintains the repositories within their network, but not all external repositories are reliable. Be sure to install only from trusted sources.

    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9

    OutputE298A3A825C0D65DFD57CBB651716619E084DAB9
    gpg: requesting key E084DAB9 from hkp server keyserver.ubuntu.com
    gpg: key E084DAB9: public key "Michael Rutter <marutter@gmail.com>" imported
    gpg: Total number processed: 1
    gpg: imported: 1 (RSA: 1)
    

Once we have the trusted key in each server’s database, we can add the repository.

    sudo add-apt-repository 'deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu xenial/'

We’ll need to run `update` after this in order to include package manifests from the new repository:

    sudo apt-get update

    Output. . .
    Get:6 https://cran.rstudio.com/bin/linux/ubuntu xenial/ InRelease [3,590 B]
    Get:7 https://cran.rstudio.com/bin/linux/ubuntu xenial/ Packages [31.5 kB]
    . . .

If the lines above appear in the output from the `update` command, we’ve successfully added the repository. We can be sure we won’t accidentally install an older version.

Now we’re ready to install R:

    sudo apt-get install r-base

At the time of this writing, the latest stable version from CRAN is at 3.3.1, which is displayed when you start R. Since we’re planning to install the example package for everyone on the system, we’ll start R as the root user so that the libraries will available to all users automatically:

    sudo -i R

    OutputR version 3.3.1 (2016-06-21) -- "Bug in Your Hair"
    . . .
    Type 'demo()' for some demos, 'help()' for on-line help, or
    'help.start()' for an HTML browser interface to help.
    Type 'q()' to quit R.
    >

This confirms that we’ve successfully installed R and entered its interactive shell.

## Step 2 — Installing R Packages from CRAN

Part of R’s strength is the abundance of add-on packages. For demonstration purposes, we’ll install `txtplot`, a library that outputs ASCII graphs, including scatterplot, line plot, density plot, acf and bar charts:

    install.packages('txtplot')

As part of the installation process, you’ll be given a choice of mirrors to install from:

    Output--- Please select a CRAN mirror for use in this session ---
    HTTPS CRAN mirror
    
    1: 0-Cloud [https] 2: Algeria [https]
    3: Australia (Melbourne) [https] 4: Australia (Perth) [https]
    5: Austria [https] 6: Belgium (Ghent) [https]
    7: Brazil (SP 1) [https] 8: Bulgaria [https]
    9: Canada (MB) [https] 10: Chile [https]
    11: China (Beijing 4) [https] 12: Colombia (Cali) [https]
    13: Czech Republic [https] 14: Denmark [https]
    15: France (Lyon 1) [https] 16: France (Lyon 2) [https]
    17: France (Marseille) [https] 18: France (Paris 2) [https]
    19: Germany (Falkenstein) [https] 20: Germany (Münster) [https]
    21: Iceland [https] 22: Ireland [https]
    23: Italy (Padua) [https] 24: Japan (Tokyo) [https]
    25: Malaysia [https] 26: Mexico (Mexico City) [https]
    27: New Zealand [https] 28: Norway [https]
    29: Philippines [https] 30: Russia (Moscow) [https]
    31: Serbia [https] 32: Spain (A Coruña) [https]
    33: Spain (Madrid) [https] 34: Switzerland [https]
    35: Taiwan (Chungli) [https] 36: Turkey (Denizli) [https]
    37: UK (Bristol) [https] 38: UK (Cambridge) [https]
    39: UK (London 1) [https] 40: USA (CA 1) [https]
    41: USA (IA) [https] 42: USA (KS) [https]
    43: USA (MI 1) [https] 44: USA (TN) [https]
    45: USA (TX) [https] 46: USA (WA) [https]
    47: (HTTP mirrors)
    
    Selection: 1

We’ve entered 1 for 0-Cloud, which will connect us to the Content Delivery Network (CDN) provided by RStudio, in order to get the geographically closest option. This mirror will be set as the default for the remainder of the session. Once you exit R and re-enter, you’ll be prompted to choose a mirror again.

**Note:** Before the list of mirrors, the following output showed where the package was being installed.

    OutputInstalling package into ‘/usr/local/lib/R/site-library’
    (as ‘lib’ is unspecified)
    . . .

This site-wide path is available because we ran R as root and is the correct location to make the package available to all users.

When the installation is complete, we can load `txtplot`:

    library('txtplot')

If there are no error messages, the library has successfully loaded. Let’s see it in action now with an example which demonstrates a basic plotting function with axis labels. The example data, supplied by R’s `datasets` package, contains the speed of cars and the distance required to stop based on data from the 1920s:

    txtplot(cars[,1], cars[,2], xlab = "speed", ylab = "distance")

    Output
          +----+-----------+------------+-----------+-----------+--+
      120 + * +
          | |
    d 100 + * +
    i | * * |
    s 80 + * * +
    t | * * * * |
    a 60 + * * * * * +
    n | * * * * * |
    c 40 + * * * * * * * +
    e | * * * * * * * |
       20 + * * * * * +
          | * * * |
        0 +----+-----------+------------+-----------+-----------+--+
               5 10 15 20 25
                                    speed

If you are interested to learn more about `txtplot`, use help(`txtplot`).

Any precompiled package can be installed from CRAN with `install.packages()`. To learn more about what’s available, you can find a listing of official packages organized by name or publication date under the Packages link on any [mirror](https://cran.r-project.org/) .

### Conclusion

Now that you’ve successfully installed R, you might be interested in this guide to [installing the open source RStudio Server](how-to-set-up-rstudio-on-an-ubuntu-cloud-server), an interface to a version of R running on a remote Linux server, which brings an IDE to the server-based deployment you just completed. You may also be interested in learning how to [install directly from GitHub, BitBucket or other locations](how-to-install-r-packages-using-devtools) in order to take advantage of the very latest work from the active community.
