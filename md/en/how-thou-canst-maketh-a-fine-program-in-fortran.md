---
author: Lisa Tagliaferri
date: 2017-04-01
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-thou-canst-maketh-a-fine-program-in-fortran
---

# How Thou Canst Maketh a Fine Program in Fortran

### Prologue

In troth, the Fortran programming language is well suited for those persons who are scientific and who engineer. Named so for the phrase “Formula Translation,” it is a language exquisite for programming machines.

If it please thee, Fortran was begun in the 1950s upon an honourable respect by IBM for applications of scientific and engineering. Fortran would prevail i’ th’ field from our ancient masters to this present day, as its virtue has been witnessed through th’ incessant use in demanding computational areas.

Avail thyself of this guide to establish Fortran within thy machine and maketh a well-appointed program out of it.

## What Thou Dost Require

Before thou dost undertake this guide, thou must for thine avail taketh an Ubuntu 16.04 server exalted with a sudo non-root user, which thou wilt accomplish in reading “[Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04).”

If thou findest that thou art not as familiar as thou wouldst lief with a terminal environment, thou may findest the article “[An Introduction to the Linux Terminal](an-introduction-to-the-linux-terminal)” to be of good use.

## Install Fortran In Its Proper Right

We doth begin with amending our machine by making much use of the command that follows here:

    sudo apt-get update

Now to the next, we will furnish our machine with the [GNU Fortran](https://gcc.gnu.org/wiki/GFortran) gfortran compiler that will make good work to compile sundry varieties of Fortran: Fortran 95, Fortran 2003, Fortran 2008. We shall now employ us the following command:

    sudo apt-get install gfortran

When the terminal doth prompt us with the request of whether we may find fair fortune in continuing, we shall press `y` to carry on.

Upon finding the installation well-furnished, we may issue forth the following command:

    gfortran

As, in troth, we have not yet supplied our merry command with a Fortran file, we shall receive only the error that here follows and it may seem lamentable to thine eyes, yet this doth mean that the compiler has found itself well-installed:

    Outputgfortran: fatal error: no input files
    compilation terminated.

Now art thou ready to try thy compiler with a Fortran program.

## Create An “O, World!” Program

Forsooth, with thy compiler having been prepared thou may be found ready to create a new file in the text editor of thy choosing, suchlike `nano`. A program by any other name is just as computational; thou may call it `OWorld` for instance. Fortran 2008 is that variant of the language most recent and stable, and as is wont to do, thou will use the extension `.f08` to signify this.

    nano OWorld.f08

In good time, thou may now commence this pattern: begin first with the `program` keyword and name the `program` again whatsoever thou would fancy. The name passed to the program keyword and the name used for the program file need not match, and to here demonstrate we shall use `OWorld` for the program file and `o_world` with the `program` keyword.

OWorld.f08

    program o_world

Whilst at this fair point we will avail of no variables, as thou would achieve good acquaintance with Fortran by including this good phrase, prithee write `implicit none` to allow thy compiler to check for well-declared variable types.

OWorld.f08

    program o_world
    implicit none

Yea, at this very moment, thou may issue forth and bid the program to print thine `O, world!` greeting:

OWorld.f08

    program o_world
    implicit none
    
    print *, "Good morrow, and well met, O world!"

The `print` statement herein employed intakes parameters and deliveth them unto output. Thou likely taketh notice of the asterisk (`*`), which kindly informs thy machine to output thy data that follows in a manner most profitable and suitable to the type of items that are therein contained in what may be a comma-delimited list or which character strings or variables make a part.

In thine own case, thou hast bestowed a character string singularly to the `print` statement.

Lastly and finally, thou shall end the program right well with the `end` statement. Here, thou doth do well to include the specific form of the unit, in this case `program`, and to be most specific thou canst include the name of the unit (`o_world`).

OWorld.f08

    program o_world
    implicit none
    
    print *, "Good morrow, and well met, O world!"
    
    end program o_world

Thou hast completed a great feat in this ending.

## Compile the Program and Bid It Run

‘Tis that thou hast happily arrived at the last. Now thou canst compile the `OWorld.f08` program

For to compile and meet successful fortune, issue forth the command that next comes:

    gfortran OWorld.f08

This command doth conceive an executable file, and thou may in thy machine discover it through the `ls` command:

    ls

    Outputa.out OWorld.f08

This new-come file must be bade to run, which thou must perforce accomplish through issuing this in writing to thy terminal:

    ./a.out

The program output at once will be delivered to thee:

    Output Good morrow, and well met, O world!

With gratitude to kind fortune, thy program hast run most profitably.

If thou dost dislike the filename `a.out`, thou can make a fine change quick to rename the file with a custom name:

    gfortran OWorld.f08 -o OWorld

Run it in the similar fashion as afore:

     ./OWorld

Thou shall find output that doth match:

    Output Good morrow, and well met, O world!

Thou hast built and run a fine program!

## Be It Concluded

Shall we at last conclude our survey of Fortran with prodigious satisfaction?

When thou dost undertake a new Fortran program, let thou keepest in mind:

- Comments in Fortran do commence with an exclamation point (`!`)
- Indenting code may prove to render it more readable for persons
- A case-insensitive language, Fortran doth allow both uppercase and lowercase letters, yet string literals do remain case sensitive

From here, it may please thou to read the culinary guide on “[Fashioning Thy Turkey Supper](5-common-turkey-setups-for-your-dinner).”
