---
author: Kris Stadler
date: 2018-06-08
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-verify-code-and-encrypt-data-with-python-gnupg-and-python-3
---

# How To Verify Code and Encrypt Data with Python-GnuPG and Python 3

_The author selected the [Open Internet/Free Speech Fund](https://www.brightfunds.org/funds/open-internet-free-speech) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

The [GnuPG package](https://www.gnupg.org/) offers a complete solution for generating and storing cryptographic keys. It also allows you to encrypt and sign data and communication.

In this tutorial, you will create a series of scripts that use Python 3 with the [python-gnupg](https://pythonhosted.org/python-gnupg/) module. These scripts will allow you to sign and encrypt multiple files, and to verify the integrity of a script before running it.

## Prerequisites

Before continuing with this tutorial, complete the following prerequisites:

- Set up an Ubuntu 16.04 server, following the [Initial Server Setup for Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) tutorial. After following this tutorial, you should have access to a non-root sudo user account. In this tutorial, our user will be named **sammy**.
- Ensure that you have Python 3 and `pip` installed by following step 1 of [How To Install Python 3 and Set Up a Local Programming Environment on Ubuntu 16.04](how-to-install-python-3-and-set-up-a-local-programming-environment-on-ubuntu-16-04#step-1-%E2%80%94-setting-up-python-3).
- Create a GnuPG key pair, following this [GnuPG tutorial](how-to-use-gpg-to-encrypt-and-sign-messages). 

## Step 1 — Retrieving Key Pair Information

After completing the GnuPG tutorial in the prerequisites, you will have a key pair stored in `.gnupg` under your home directory. GnuPG stores keys with a username and e-mail to help identify key pairs. In this example, our username is **sammy** and our e-mail address is `sammy@example.com`.

Run the command below to get a list of your available keys:

    gpg --list-keys

    Output/home/sammy/.gnupg/pubring.gpg
    -----------------------------
    pub 2048R/4920B23F 2018-04-23
    uid Sammy <sammy@example.com>
    sub 2048R/50C06279 2018-04-23

Make a note of the e-mail address displayed in the `uid` row of your output. You will need it later to identify your keys.

## Step 2 — Installing Python-GnuPG and Signing Files

With your keys in place, you can install the `python-gnupg` module, which acts as a wrapper around GnuPG to enable interaction between GnuPG and Python 3. Using this module, you will be able to create Python scripts that do the following:

- Create detached signatures for files, adding a layer of security to the signature process by decoupling signatures from files. 
- Encrypt files.
- Decrypt files.
- Verify detached signatures and scripts. 

You will create the scripts first, along with some test files, before moving on to test the scripts on these files.

To get started, let’s install the `python-gnupg` module, along with the `fs` package, which will allow you to open, read, and write your test files. Update your package index, and install these packages with `pip`:

    sudo apt-get update
    sudo pip3 install python-gnupg fs

With these packages in place, we can move on to creating the scripts and test files.

To store the scripts and test files, create a folder in your home directory called `python-test`:

    cd ~/
    mkdir python-test

Move to this directory:

    cd python-test/

Next, let’s create three test files:

    echo "This is the first test file" > test1.txt
    echo "print('This test file is a Python script')" > test2.py
    echo "This is the last test file" > test3.txt

To create detached signatures for our test files, let’s create a script called `signdetach.py`, which will target all of the files in the directory where it’s executed. A signature acts as a timestamp and certifies the authenticity of the document.

The detached signatures will be stored in a new folder called `signatures/`, which will be created when the script runs.

Open a new file called `signdetach.py` using `nano` or your favorite text editor:

    nano signdetach.py

Let’s first import all of the required modules for the script. These include the `os` and `fs` packages, which enable file navigation, and `gnupg`:

~/python-test/signdetach.py

    #!/usr/bin/env python3
    
    import os
    import fs
    from fs import open_fs
    import gnupg

Let’s now set the directory where GnuPG will find its encryption keys. GnuPG stores its keys in `.gnupg` by default, so let’s configure this with our username. Be sure to replace **sammy** with the name of your non-root user:

~/python-test/signdetach.py

    ...
    gpg = gnupg.GPG(gnupghome="/home/sammy/.gnupg")

Next, let’s create a `home_fs` variable to store the current directory location as a file object. This will make it possible for the script to work within the directory where it’s executed:

~/python-test/signdetach.py

    ...
    home_fs = open_fs(".")

By now your script will look like this:

~/python-test/signdetach.py

    #!/usr/bin/env python3
    
    import os
    import fs
    from fs import open_fs
    import gnupg
    
    gpg = gnupg.GPG(gnupghome="/home/sammy/.gnupg")
    home_fs = open_fs(".")

This configuration block is the basic template you will use in your scripts as you move through this tutorial.

Next, add code to check if there is a folder named `signatures/` and create it if it does not exist:

~/python-test/signdetach.py

    ...
    if os.path.exists("signatures/"):
            print("Signatures directory already created")
    else:
            home_fs.makedir(u"signatures")
            print("Created signatures directory")

Create an empty array to store the filenames in and then scan the current directory, appending all of the file names to the `files_dir` array:

~/python-test/signdetach.py

    ...
    files_dir = []
    
    files = [f for f in os.listdir(".") if os.path.isfile(f)]
    for f in files:
        files_dir.append(f)

The next thing the script will do is generate detached signatures for the files. Looping through the `files_dir` array will create a signature for each file using the first private key on your keyring. To access the private key you will need to unlock it with the passphrase you set. Replace `"my passphrase"` with the passphrase you used when you generated the key-pair in the prerequisites:

~/python-test/signdetach.py

    ...
    for x in files_dir:
        with open(x, "rb") as f:
            stream = gpg.sign_file(f,passphrase="my passphrase",detach = True, output=files_dir[files_dir.index(x)]+".sig")
            os.rename(files_dir[files_dir.index(x)]+".sig", "signatures/"+files_dir[files_dir.index(x)]+".sig")
            print(x+" ", stream.status)

When finished, all the signatures will be moved to the `signatures/` folder. Your finished script will look like this:

~/python-test/signdetach.py

     #!/usr/bin/env python3
    
    import os
    import fs
    from fs import open_fs
    import gnupg
    
    gpg = gnupg.GPG(gnupghome="/home/sammy/.gnupg")
    home_fs = open_fs(".")
    
    if os.path.exists("signatures/"):
        print("Signatures directory already created")
    else:
        home_fs.makedir(u"signatures")
        print("Created signatures directory")
    
    files_dir = []
    
    files = [f for f in os.listdir(".") if os.path.isfile(f)]
    for f in files:
        files_dir.append(f)
    
    for x in files_dir:
        with open(x, "rb") as f:
            stream = gpg.sign_file(f,passphrase="my passphrase",detach = True, output=files_dir[files_dir.index(x)]+".sig")
            os.rename(files_dir[files_dir.index(x)]+".sig", "signatures/"+files_dir[files_dir.index(x)]+".sig")
            print(x+" ", stream.status)
    

Now we can move on to encrypting files.

## Step 3 — Encrypting Files

Executing the encryption script in a folder will cause all of the files within that folder to be copied and encrypted within a new folder called `encrypted/`. The public key used to encrypt the files is the one that corresponds with the e-mail you specified in your key pair configuration.

Open a new file called `encryptfiles.py`:

    nano encryptfiles.py

First, import all of the required modules, set GnuPG’s home directory, and create the current working directory variable:

~/python-test/encryptfiles.py

    #!/usr/bin/env python3
    
    import os
    import fs
    from fs import open_fs
    import gnupg
    
    gpg = gnupg.GPG(gnupghome="/home/sammy/.gnupg")
    home_fs = open_fs(".")

Next, let’s add code to check if the current directory already has a folder called `encrypted/`, and to create it if it doesn’t exist:

~/python-test/encryptfiles.py

    ...
    if os.path.exists("encrypted/"):
            print("Encrypt directory exists")
    else:
            home_fs.makedir(u"encrypted")
            print("Created encrypted directory")

Before searching for files to encrypt, let’s create an empty array to store the filenames:

~/python-test/encryptfiles.py

    ...
    files_dir = []

Next, create a loop to scan the folder for files and append them to the array:

~/python-test/encryptfiles.py

    ...
    files = [f for f in os.listdir(".") if os.path.isfile(f)]
    for f in files:
        files_dir.append(f)

Finally, let’s create a loop to encrypt all the files within the folder. When completed, all the encrypted files will be transferred to the `encrypted/` folder. In this example `sammy@example.com` is the e-mail ID for the key to use during encryption. Be sure to replace this with the e-mail address you noted in step 1:

~/python-test/encryptfiles.py

    ...
    for x in files_dir:
        with open(x, "rb") as f:
            status = gpg.encrypt_file(f,recipients=["sammy@example.com"],output= files_dir[files_dir.index(x)]+".gpg")
            print("ok: ", status.ok)
            print("status: ", status.status)
            print("stderr: ", status.stderr)
            os.rename(files_dir[files_dir.index(x)] + ".gpg", 'encrypted/' +files_dir[files_dir.index(x)] + ".gpg")

If you have multiple keys stored within your `.gnupg` folder and want to use a specific public key or multiple public keys for encryption, you need to modify the `recipients` array by either adding the additional recipients or replacing the current one.

Your `encryptfiles.py` script file will look like this when you are done:

~/python-test/encryptfiles.py

     #!/usr/bin/env python3
    
    import os
    import fs
    from fs import open_fs
    import gnupg
    
    gpg = gnupg.GPG(gnupghome="/home/sammy/.gnupg")
    home_fs = open_fs(".")
    
    if os.path.exists("encrypted/"):
        print("Encrypt directory exists")
    else:
        home_fs.makedir(u"encrypted")
        print("Created encrypted directory")
    
    files_dir = []
    
    files = [f for f in os.listdir(".") if os.path.isfile(f)]
    for f in files:
        files_dir.append(f)
    
    for x in files_dir:
        with open(x, "rb") as f:
            status = gpg.encrypt_file(f,recipients=["sammy@example.com"],output= files_dir[files_dir.index(x)]+".gpg")
            print("ok: ", status.ok)
            print("status: ", status.status)
            print("stderr: ", status.stderr)
            os.rename(files_dir[files_dir.index(x)] + ".gpg", "encrypted/" +files_dir[files_dir.index(x)] + ".gpg")
    

Now let’s look at the second part of the process: decrypting and verifying multiple files at once.

## Step 4 — Decrypting Files

The decryption script works much the same as the encryption script, except that it is meant to be executed within an `encrypted/` directory. When launched, `decryptfiles.py` will first identify the public key used and then search for the corresponding private key in the `.gnupg` folder to decrypt the file. Decrypted files will be stored in a new folder called `decrypted/`.

Open a new file called `decryptfiles.py` with `nano` or your favorite editor:

    nano decryptfiles.py

Start by inserting the configuration settings:

~/python-test/decryptfiles.py

    #!/usr/bin/env python3
    
    import os
    import fs
    from fs import open_fs
    import gnupg
    
    gpg = gnupg.GPG(gnupghome="/home/sammy/.gnupg")
    home_fs = open_fs(".")

Next, create two empty arrays to store data during script execution:

~/python-test/decryptfiles.py

    ...
    files_dir = []
    files_dir_clean = []

The goal here is for the script to place the decrypted files into their own folder; otherwise, the encrypted and decrypted files will get mixed, making it difficult to locate a specific decrypted file. To solve this problem, you can add code that will scan the current folder to see if a `decrypted/` folder exists, creating it if it doesn’t:

~/python-test/decryptfiles.py

    ...
    if os.path.exists("decrypted/"):
        print("Decrypted directory already exists")
    else:
        home_fs.makedir(u"decrypted/")
        print("Created decrypted directory")

Scan through the folder and append all the filenames to the `files_dir` array:

~/python-test/decryptfiles.py

    ...
    files = [f for f in os.listdir(".") if os.path.isfile(f)]
    for f in files:
        files_dir.append(f)

All the encrypted files have the `.gpg` extension added to their filename to indicate that they are encrypted. However, when decrypting them, we want to save them without this extension, as they aren’t encrypted anymore.

To do this, loop through the `files_dir` array and remove the `.gpg` extension from each filename:

~/python-test/decryptfiles.py

    ...
        for x in files_dir:
                length = len(x)
                endLoc = length - 4
                clean_file = x[0:endLoc]
                files_dir_clean.append(clean_file)

The new “cleaned-up” filenames are stored within the `file_dir_clean` array.

Next, let’s loop through the files and decrypt them. Replace `"my passphrase"` with your passphrase to unlock the private key:

~/python-test/decryptfiles.py

    ...
    for x in files_dir:
        with open(x, "rb") as f:
           status = gpg.decrypt_file(f, passphrase="my passphrase",output=files_dir_clean[files_dir.index(x)])
           print("ok: ", status.ok)
           print("status: ", status.status)
           print("stderr: ", status.stderr)
           os.rename(files_dir_clean[files_dir.index(x)], "decrypted/" + files_dir_clean[files_dir.index(x)])

Your script file will look like this when you are finished:

~/python-test/decryptfiles.py

     #!/usr/bin/env python3
    
    import os
    import fs
    from fs import open_fs
    import gnupg
    
    gpg = gnupg.GPG(gnupghome="/home/sammy/.gnupg")
    home_fs = open_fs(".")
    
    files_dir = []
    files_dir_clean = []
    
    if os.path.exists("decrypted/"):
        print("Decrypted directory already exists")
    else:
        home_fs.makedir(u"decrypted/")
        print("Created decrypted directory")
    
    files = [f for f in os.listdir(".") if os.path.isfile(f)]
    for f in files:
        files_dir.append(f)
    
    for x in files_dir:
        length = len(x)
        endLoc = length - 4
        clean_file = x[0:endLoc]
        files_dir_clean.append(clean_file)
    
    for x in files_dir:
        with open(x, "rb") as f:
           status = gpg.decrypt_file(f, passphrase="my passphrase",output=files_dir_clean[files_dir.index(x)])
           print("ok: ", status.ok)
           print("status: ", status.status)
           print("stderr: ", status.stderr)
           os.rename(files_dir_clean[files_dir.index(x)], "decrypted/" + files_dir_clean[files_dir.index(x)])

With our decryption script in place, we can move on to verifying detached signatures for multiple files.

## Step 5 — Verifying Detached Signatures

To verify the detached digital signatures of multiple files, let’s write a `verifydetach.py` script. This script will search for a `signatures/` folder within the working directory and verify each file with its signature.

Open a new file called `verifydetach.py`:

    nano verifydetach.py

Import all the necessary libraries, set the working and home directories, and create the empty `files_dir` array, as in the previous examples:

~/python-test/verifydetach.py

    #!/usr/bin/env python3
    
    import os
    import fs
    from fs import open_fs
    import gnupg
    
    gpg = gnupg.GPG(gnupghome="/home/sammy/.gnupg")
    home_fs = open_fs(".")
    
    files_dir = []    

Next, let’s scan the folder that contains the files we want to verify. The filenames will be appended to the empty `files_dir` array:

~/python-test/verifydetach.py

    ...
    files = [f for f in os.listdir(".") if os.path.isfile(f)]
    for f in files:
    files_dir.append(f)

Finally, let’s verify each file with its own detached signature, using a loop that moves through the `files_dir` array to search for the detached signature of each file within the `signatures/` folder. When it finds the detached signature, it will verify the file with it. The last line prints out the status of each file’s verification:

~/python-test/verifydetach.py

    ...
    for i in files_dir:
         with open("../../signatures/" + i + ".sig", "rb") as f:
             verify = gpg.verify_file(f, i)
             print(i + " ", verify.status)

When you are finished, your script will look like this:

~/python-test/verifydetach.py

     #!/usr/bin/env python3
    
    import os
    import fs
    from fs import open_fs
    import gnupg
    
    gpg = gnupg.GPG(gnupghome="/home/sammy/.gnupg")
    home_fs = open_fs(".")
    
    files_dir = []   
    
    files = [f for f in os.listdir(".") if os.path.isfile(f)]
    for f in files:
        files_dir.append(f)
    
    for i in files_dir:
        with open("../../signatures/" + i + ".sig", "rb") as f:
            verify = gpg.verify_file(f, i)
            print(i + " ", verify.status)

Next, let’s go over how to verify the signature of a file before it gets executed on your server.

## Step 6 — Verifying Files

The final script will verify scripts before they are executed. In this sense, it is similar to `verifydetach`, but it has the additional ability to launch scripts that have been verified. It works by taking a script’s name as an argument and then verifying the signature of that file. If the verification is successful, the script will post a message to the console and launch the verified script. Should the verification process fail, the script will post the error to the console and abort file execution.

Create a new file called `verifyfile.py`:

    nano verifyfile.py

Let’s first import the necessary libraries and set the working directories:

~/python-test/verifyfile.py

    #!/usr/bin/env python3
    
    import os
    import fs
    from fs import open_fs
    import gnupg
    
    gpg = gnupg.GPG(gnupghome="/home/sammy/.gnupg")
    home_fs = open_fs(".")

For the script to work, it’s necessary to store the name of the file to verify and execute. To do this, let’s create a new variable called `script_to_run`:

~/python-test/verifyfile.py

    ...
    script_to_run = str(sys.argv[1])

This variable takes the first argument and stores it within the newly created variable. Next, the script will open the detached signature file, verify the file in `script_to_run` with its signature, and then execute it if it passes verification:

~/python-test/verifyfile.py

    ...
    with open("../../signatures/" + script_to_run + ".sig", "rb") as f:
         verify = gpg.verify_file(f, script_to_run)
         print(script_to_run + " ", verify.status)
         if verify.status == "signature valid":
              print("Signature valid, launching script...")
              exec(open(script_to_run).read())
         else:
               print("Signature invalid or missing, ")
               print("aborting script execution")

The finished script will look like this:

~/python-test/verifyfile.py

     #!/usr/bin/env python3
    
    import os
    import sys
    import fs
    from fs import open_fs
    import gnupg
    
    gpg = gnupg.GPG(gnupghome="/home/sammy/.gnupg")
    home_fs = open_fs(".")
    
    script_to_run = str(sys.argv[1])
    
    with open("../../signatures/" + script_to_run + ".sig", "rb") as f:
        verify = gpg.verify_file(f, script_to_run)
        print(script_to_run + " ", verify.status)
        if verify.status == "signature valid":
            print("Signature valid, launching script...")
            exec(open(script_to_run).read())
        else:
            print("Signature invalid or missing, ")
            print("aborting script execution")

We have finished creating the scripts, but at the moment they can only be launched from within the current folder. In the next step we will modify their permissions to make them globally accessable.

## Step 7 — Making the Scripts Available System-Wide

For ease of use, let’s make the scripts executable from any directory or folder on the system and place them within our `$PATH`. Use the `chmod` command to give executable permissions to the owner of the files, your non-root user:

    chmod +x *.py

Now to find your `$PATH` settings, run the following command:

    echo $PATH

    Output-bash: /home/sammy/bin:/home/sammy/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

Files stored in your `$PATH` will be accessable from any folder within your system, if the directory’s permissions allow it. You can place your scripts anywhere within your `$PATH`, but for now let’s move the scripts from the `python-test/` directory to `/usr/local/bin/`.

Note that we are dropping the `.py` extension when copying the files. If you look at the first line of the scripts we created, you will see `#!usr/bin/env python3`. This line is known as a [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) and it helps the operating system identify the bash interpreter or enviroment to use when executing the code. When we execute the script, the operating system will note that we specified Python as our enviroment, and will pass the code to Python for execution. This means that we no longer need file extensions to help identify the enviroment we want to work in:

    sudo mv encryptfiles.py /usr/local/bin/encryptfiles
    sudo mv decryptfiles.py /usr/local/bin/decryptfiles
    sudo mv signdetach.py /usr/local/bin/signdetach
    sudo mv verifyfile.py /usr/local/bin/verifyfile
    sudo mv verifydetach.py /usr/local/bin/verifydetach

Now the scripts can be executed anywhere in the system by simply running the script name along with any arguments the script might take from the command line. In the next step, we will look at some examples of how to use these scripts.

## Step 8 — Testing the Scripts

Now that we have moved the scripts to our `$PATH`, we can run them from any folder on the server.

First, check if you are still working within the `python-test` directory with the `pwd` command:

    pwd

The output should be:

    Output/home/sammy/python-test

You created three test files earlier in the tutorial. Run the `ls -l` command to list the files in the folder:

    ls -l

You should see three files stored in your `python-test` folder:

    Output-rw-rw-r-- 1 sammy sammy 15 Apr 15 10:08 test1.txt
    -rwxrwxr-x 1 sammy sammy 15 Apr 15 10:08 test2.py 
    -rw-rw-r-- 1 sammy sammy 15 Apr 15 10:08 test3.txt

We will be testing the scripts on these three files. You can quickly display the content of the files before encryption using the `cat` command, as follows:

    cat test1.txt

    OutputThis is the first test file

Let’s start by creating detached signatures for all of the files. To do this, execute the `signdetach` script from within the current folder:

    signdetach

    OutputCreated signatures directory
    test2.py signature created
    test1.txt signature created
    test3.txt signature created

Notice in the output that the script detected that the `signatures/` directory was not present and made it. It then created the file signatures.

We can confirm this by running the `ls -l` command again:

    ls -l

    Outputtotal 16
    drwxrwxr-x 2 sammy sammy 4096 Apr 21 14:11 signatures
    -rw-rw-r-- 1 sammy sammy 15 Apr 15 10:08 test1.txt
    -rwxrwxr-x 1 sammy sammy 15 Apr 15 10:08 test2.py 
    -rw-rw-r-- 1 sammy sammy 15 Apr 15 10:08 test3.txt

Notice the new `signatures` directory among the items on the list. Let’s list the content of this folder and take a closer look at one of the signatures.

To list all of the signatures, type:

    ls -l signatures/

    Outputtotal 12
    -rw-rw-r-- 1 sammy sammy 473 Apr 21 14:11 test1.txt.sig
    -rw-rw-r-- 1 sammy sammy 473 Apr 21 14:11 test2.py.sig
    -rw-rw-r-- 1 sammy sammy 473 Apr 21 14:11 test3.txt.sig

Detached signature files can be identified by the `.sig` extension. Again, the `cat` command can display the content of one of these signatures. Let’s take a look at the content of signature `test1.txt.sig`:

    cat signatures/test1.txt.sig

    Output-----BEGIN PGP SIGNATURE-----
    Version: GnuPG v1
    
    iQEcBAABAgAGBQJa20aGAAoJENVtx+Y8cX3mMhMH+gOZsLJX3aEgUPZzDlKRWYec
    AyrXEGp5yIABj7eoLDKGUxftwGt+c4HZud1iEUy8AhtW/Ea6eRlMFPTso2hb9+cw
    /MyffTrWGpa0AGjNvf4wbxdq7TNpAlw4nmcwKpeYqkUu2fP3c18oZ3G3R3+P781w
    GWori9FK3eTyVPs9E0dVgdo7S8G1pF/ECo8Cl4Mrj80rERAitQAMbSaN/dF0wUKu
    okRZPJPVjd6GwqRRkXoqwh0vm4c+p3nAhFV+v7uK2BOUIJKPFbbn58vmmn+LVaBS
    MFWSb+X85KwwftIezqCV/hqsMKAuhkvfIi+YQFCDXElJMtjPBxxuvZFjQFjEHe8=
    =4NB5
    -----END PGP SIGNATURE-----

This output is the detached signature for `test1.txt`.

With the signatures in place, it’s possible to move on to encrypting our files. To do this, execute the `encryptfiles` script:

    encryptfiles

    OutputCreated encrypted directory
    ok: True
    status: encryption ok
    stderr: [GNUPG:] BEGIN_ENCRYPTION 2 9
    [GNUPG:] END_ENCRYPTION
    
    ok: True
    status: encryption ok
    stderr: [GNUPG:] BEGIN_ENCRYPTION 2 9
    [GNUPG:] END_ENCRYPTION
    
    ok: True
    status: encryption ok
    stderr: [GNUPG:] BEGIN_ENCRYPTION 2 9
    [GNUPG:] END_ENCRYPTION

From the output, notice that the script created the `encrypted/` folder. Also notice that all of the files were encrypted sucessfully. Run the `ls -l` command again and notice the new folder within the directory:

    ls -l

    Outputtotal 20
    drwxrwxr-x 2 sammy sammy 4096 Apr 21 14:42 encrypted
    drwxrwxr-x 2 sammy sammy 4096 Apr 21 14:11 signatures
    -rw-rw-r-- 1 sammy sammy 15 Apr 15 10:08 test1.txt
    -rw-rw-r-- 1 sammy sammy 15 Apr 15 10:08 test2.py
    -rw-rw-r-- 1 sammy sammy 15 Apr 15 10:08 test3.txt

Let’s see how the message in `test1.txt` looks now that it has been encrypted:

    cat encrypted/test1.txt.gpg

    Output-----BEGIN PGP MESSAGE-----
    Version: GnuPG v1
    
    hQEMA9Vtx+Y8cX3mAQf9FijeaCOKFRUWOrwOkUw7efvr5uQbSnxxbE/Dkv0y0w8S
    Y2IxQPv4xS6VrjhZQC6K2R968ZQDvd+XkStKfy6NJLsfKZM+vMIWiZmqJmKxY2OT
    8MG/b9bnNCORRI8Nm9etScSYcRu4eqN7AeUdWOXAFX+mo7K00IdEQH+0Ivyc+P1d
    53WBgWstt8jHY2cn1sLdoHh4m70O7v1rnkHOvrQW3AAsBbKzvdzxOa0/5IKGCOYF
    yC8lEYfOihyEetsasx0aDDXqrMZVviH3KZ8vEiH2n7hDgC5imgJTx5kpC17xJZ4z
    LyEiNPu7foWgVZyPzD2jGPvjW8GVIeMgB+jXsAfvEdJJAQqX6qcHbf1SPSRPJ2jU
    GX5M/KhdQmBcO9Sih9IQthHDXpSbSVw/UejheVfaw4i1OX4aaOhNJlnPSUDtlcl4
    AUoBjuBpQMp4RQ==
    =xJST
    -----END PGP MESSAGE-----

The sentence stored in the original file has been transformed into a complex series of characters and numbers as a result of the encryption process.

Now that the files have been signed and encrypted, it’s possible to delete the originals and recover the original messages from the encrypted files.

To delete the originals, type:

    rm *.txt *.py

Run the `ls -l` command again to ensure that all of the original files have been deleted:

    ls -l

    Outputtotal 8
    drwxrwxr-x 2 sammy sammy 4096 Apr 21 14:42 encrypted
    drwxrwxr-x 2 sammy sammy 4096 Apr 21 14:11 signatures

With the original files gone, let’s decrypt and verify the encrypted files. Change into the `encrypted` folder and list all of the files:

    cd encrypted/ && ls -l

    Outputtotal 12
    -rw-rw-r-- 1 sammy sammy 551 Apr 21 14:42 test1.txt.gpg
    -rw-rw-r-- 1 sammy sammy 551 Apr 21 14:42 test2.py.gpg
    -rw-rw-r-- 1 sammy sammy 551 Apr 21 14:42 test3.txt.gpg

To decrypt the files, run the `decryptfiles` script from within the current folder:

    decryptfiles

    OutputCreated decrypted directory
    ok: True
    status: decryption ok
    stderr: [GNUPG:] ENC_TO D56DC7E63C717DE6 1 0
    [GNUPG:] USERID_HINT D56DC7E63C717DE6 Autogenerated Key <sammy@example.com>
    [GNUPG:] NEED_PASSPHRASE D56DC7E63C717DE6 D56DC7E63C717DE6 1 0
    [GNUPG:] GOOD_PASSPHRASE
    gpg: encrypted with 2048-bit RSA key, ID 3C717DE6, created 2018-04-15
          "Autogenerated Key <sammy@example.com>"
    [GNUPG:] BEGIN_DECRYPTION
    [GNUPG:] DECRYPTION_INFO 2 9
    [GNUPG:] PLAINTEXT 62 1524321773
    [GNUPG:] PLAINTEXT_LENGTH 15
    [GNUPG:] DECRYPTION_OKAY
    [GNUPG:] GOODMDC
    [GNUPG:] END_DECRYPTION
    
    ok: True
    status: decryption ok
    stderr: [GNUPG:] ENC_TO D56DC7E63C717DE6 1 0
    [GNUPG:] USERID_HINT D56DC7E63C717DE6 Autogenerated Key <sammy@example.com>
    [GNUPG:] NEED_PASSPHRASE D56DC7E63C717DE6 D56DC7E63C717DE6 1 0
    [GNUPG:] GOOD_PASSPHRASE
    gpg: encrypted with 2048-bit RSA key, ID 3C717DE6, created 2018-04-15
          "Autogenerated Key <sammy@example.com>"
    [GNUPG:] BEGIN_DECRYPTION
    [GNUPG:] DECRYPTION_INFO 2 9
    [GNUPG:] PLAINTEXT 62 1524321773
    [GNUPG:] PLAINTEXT_LENGTH 15
    [GNUPG:] DECRYPTION_OKAY
    [GNUPG:] GOODMDC
    [GNUPG:] END_DECRYPTION
    
    ok: True
    status: decryption ok
    stderr: [GNUPG:] ENC_TO D56DC7E63C717DE6 1 0
    [GNUPG:] USERID_HINT D56DC7E63C717DE6 Autogenerated Key <sammy@example.com>
    [GNUPG:] NEED_PASSPHRASE D56DC7E63C717DE6 D56DC7E63C717DE6 1 0
    [GNUPG:] GOOD_PASSPHRASE
    gpg: encrypted with 2048-bit RSA key, ID 3C717DE6, created 2018-04-15
          "Autogenerated Key <sammy@example.com>"
    [GNUPG:] BEGIN_DECRYPTION
    [GNUPG:] DECRYPTION_INFO 2 9
    [GNUPG:] PLAINTEXT 62 1524321773
    [GNUPG:] PLAINTEXT_LENGTH 15
    [GNUPG:] DECRYPTION_OKAY
    [GNUPG:] GOODMDC
    [GNUPG:] END_DECRYPTION

The script returned `status: decryption ok` for each file, meaning that each was successfully decrypted.

Change into the new `decrypted/` folder and display the content of `test1.txt` using the `cat` command:

    cd decrypted/ && cat test1.txt

    OutputThis is the first test file

We have recovered the message stored witihin the `test1.txt` file that we deleted.

Next, let’s confirm that this message is indeed the original message by verifying its signature with the `verifydetach` script.

The signature file contains the identity of the signer as well as a hash value calculated using data from the signed document. During verification, `gpg` will take the public key of the sender and use it alongside a hashing algorithm to calculate the hash value for the data. The calculated hash value and the value stored within the signature need to match for verification to be successful.

Any tampering with the original file, the signature file, or the public key of the sender will cause the hash value to change and the verification process to fail.

Run the script from within the `decrypted` folder:

    verifydetach

    Outputtest2.py signature valid
    test1.txt signature valid
    test3.txt signature valid

You can see from the output that all of the files have a valid signature, meaning that the documents have not been tampered with during this process.

Let’s now look at what happens when you make changes to your document after you’ve signed it. Open up the `test1.txt` file with `nano`:

    nano test1.txt 

Now add the following sentence to the file:

~/python-test/encrypted/decrypted/test1.txt

    This is the first test file
    Let's add a sentence after signing the file

Save and close the file.

Now re-run the `verifydetach` script and notice how the output has changeed:

    verifydetach

    Outputtest2.py signature valid
    test1.txt signature bad
    test3.txt signature valid

Note that GnuPG returned `signature bad` when verifying `test1.txt`. This is because we made changes to the file after it had been signed. Remember that during the verification process, `gpg` compares the hash value stored in the signature file with the hash value it calculates from the document you signed. The changes we made to the document resulted in `gpg` calculating a different hash value for `test1.txt`. A more detailed discussion about how hashing algorithims work can be found [here](http://etutorials.org/Programming/Programming+.net+security/Part+III+.NET+Cryptography/Chapter+13.+Hashing+Algorithms/13.1+Hashing+Algorithms+Explained/).

For our last test, let’s make use of `verifyfile` to verify a script before it gets executed. This script can be seen as an extension of the `verifydetach` script, though with the following difference: if a script passes the verification process, `verifyfile` will proceed to launch it.

The `test2.py` script prints a string to the console when launched. Let’s use it to demonstrate how the `verifyfile` script works.

Run the `test2.py` script with `verifyfile`:

    verifyfile test2.py

    Outputtest2.py signature valid
    Signature valid, launching script...
    The second test file is a Python script

From the output you can see that the script verified the signature of the file, printed an appropriate result based on that verification, and then launched the script.

Let’s test the verification process by adding an additional line of code to the file. Open `test2.py` and insert the following line of code:

    nano test2.py

~/python-test/encrypted/decrypted/test2.py

    print "The second test file is a Python script"
    print "This line will cause the verification script to abort"

Now re-run the `verifyfile` script:

    verifyfile test2.py

    Outputtest2.py signature bad
    Signature invalid, 
    aborting script execution

The verification of the script failed, causing the script launch to be aborted.

## Conclusion

The `python-gnupg` module allows integration between a wide range of cryptographic tools and Python. The ability to quickly encrypt or verify the integrity of data streams is crucial in certain situations, like querying or storing data to a remote database server. GnuPG keys can also be used for things like [creating backups](how-to-use-duplicity-with-gpg-to-back-up-data-to-digitalocean-spaces) and SSH authentication, or combined with a VPN setup.

To learn more about the `python-gnupg` module, you can visit the [python-gnupg project page](https://pythonhosted.org/python-gnupg/). For more information about file hashing, take a look at this guide on [How To Verify Downloaded Files](how-to-verify-downloaded-files).
