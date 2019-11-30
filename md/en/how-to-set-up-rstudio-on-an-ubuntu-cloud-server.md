---
author: Di Wu
date: 2013-04-16
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-set-up-rstudio-on-an-ubuntu-cloud-server
---

# How To Set Up RStudio On An Ubuntu Cloud Server

### What is RStudio?

[RStudio IDE](http://www.rstudio.com/ide) is an open source **I** ntegrated **D** evelopment **E** nvironment for the statistical analysis program R. RStudio Server provides a web version of RStudio IDE that allows easy development on a VPS. Since our VPSs are billed by the hour, it's surprisingly cheap to spin up a 24 core instance, crunch some data, and then destroy the VPS.

## Installing RStudio In a VPS

First, install R, apparmor, and gdebi.

    sudo apt-get install r-base libapparmor1 gdebi-core

Next, download and install the correct package for your architecture. On 32-bit Ubuntu, execute the following commands.

    wget http://download2.rstudio.org/rstudio-server-0.97.336-i386.deb -O rstudio.deb

On 64-bit Ubuntu, execute the following commands.

    wget http://download2.rstudio.org/rstudio-server-0.97.336-amd64.deb -O rstudio.deb

Install the package.

    sudo gdebi rstudio.deb

## Creating RStudio User

It is not advisable to use the root account with RStudio, instead, create a normal user account just for RStudio. The account can be named anything, and the account password will be the one to use in the web interface.

    sudo adduser rstudio

RStudio will use the user's home directory as it's default workspace.

## Using R Studio

RStudio can be access through port 8787. Any user account with a password can be used in RStudio.

 ![Rstudio Sign In](https://assets.digitalocean.com/tutorial_images/kobMKpU.png)

Let's test that RStudio is working correctly by installing a quantitative finance package from [CRAN](http://cran.us.r-project.org), the R package repository.

Run the following command inside RStudio to install [quantmod](http://www.quantmod.com).

    install.packages("quantmod")

 ![Rstudio 1](https://assets.digitalocean.com/tutorial_images/KyPVGkq.png)

Next, let's test out RStudio's graphing capabilities by plotting the stock price of Apple. The graph will appear in the bottom right panel of RStudio.

    library('quantmod') data ![Rstudio 2](https://assets.digitalocean.com/tutorial_images/EIa5IVz.png?1)
    
    R is a really powerful tool and there are hundreds of useful packages available from [CRAN](http://cran.us.r-project.org). You can learn the basics of R at [Try R](http://www.codeschool.com/courses/try-r).
    
    
    
    To learn how to install R packages from CRAN and GitHub and how to ensure that these packages are made available for all users on the same Droplet, check out [How To Set Up R on Ubuntu 14.04](/community/tutorials/how-to-set-up-r-on-ubuntu-14-04).
    
