---
author: Justin Ellingwood
date: 2016-12-09
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-use-vault-to-protect-sensitive-ansible-data-on-ubuntu-16-04
---

# How To Use Vault to Protect Sensitive Ansible Data on Ubuntu 16.04

## Introduction

Ansible Vault is a feature that allows users to encrypt values and data structures within Ansible projects. This provides the ability to secure any sensitive data that is necessary to successfully run Ansible plays but should not be publicly visible, like passwords or private keys. Ansible automatically decrypts vault-encrypted content at runtime when the key is provided.

In this guide, we will demonstrate how to use Ansible Vault and explore some recommended practices to simplify its use. We will be using an Ubuntu 16.04 server for the Ansible control machine. No remote hosts are needed.

## Prerequisites

To follow along, you will need an Ubuntu 16.04 server with a non-root user with `sudo` privileges. You can follow our [Ubuntu 16.04 initial server setup guide](initial-server-setup-with-ubuntu-16-04) to create a user with the appropriate permissions.

On the server, you will need to install and configure Ansible. You can follow our tutorial on [installing Ansible on Ubuntu 16.04](how-to-install-and-configure-ansible-on-ubuntu-16-04) to install the appropriate packages.

Continue with this guide when your server is configured with the above requirements.

## What is Ansible Vault?

Vault is a mechanism that allows encrypted content to be incorporated transparently into Ansible workflows. A utility called `ansible-vault` secures confidential data by encrypting it on disk. To integrate these secrets with regular Ansible data, both the `ansible` and `ansible-playbook` commands, for executing ad hoc tasks and structured playbook respectively, have support for decrypting vault-encrypted content at runtime.

Vault is implemented with file-level granularity, meaning that files are either entirely encrypted or unencrypted. It uses the `AES256` algorithm to provide symmetric encryption keyed to a user-supplied password. This means that the same password is used to encrypt and decrypt content, which is helpful from a usability standpoint. Ansible is able to identify and decrypt any vault-encrypted files it finds while executing a playbook or task.

Though [there are proposals to change this](https://github.com/ansible/ansible/issues/13243), at the time of this writing, users can only pass in a single password to Ansible. This means that each of the encrypted files involved must share a password.

Now that you understand a bit about what Vault is, we can start discussing the tools Ansible provides and how to use Vault with existing workflows.

## Setting the Ansible Vault Editor

Before using the `ansible-vault` command, it is a good idea to specify your preferred text editor. A few of Vault’s commands involve opening an editor to manipulate the contents of an encrypted file. Ansible will look at the `EDITOR` environment variable to find your preferred editor. If this is unset, it will default to `vi`.

If you do not want to edit with `vi` editor, you should set the `EDITOR` variable in your environment.

**Note:** If you find yourself within a `vi` session accidentally, you can exit by hitting the **Esc** key, typing `:q!`, and then pressing **Enter**. If you are not familiar with the `vi` editor, any changes you make will likely be unintentional, so this command exits without saving.

To set the editor for an individual command, prepend the command with the environment variable assignment, like this:

    EDITOR=nano ansible-vault . . .

To make this persistent, open your `~/.bashrc` file:

    nano ~/.bashrc

Specify your preferred editor by adding an `EDITOR` assignment to the end of the file:

~/.bashrc

    export EDITOR=nano

Save and close the file when you are finished.

Source the file again to read the change into the current session:

    . ~/.bashrc

Display the `EDITOR` variable to check that your setting was applied:

    echo $EDITOR

    Outputnano

Now that you’ve established your preferred editor, we can discuss the operations available with the `ansible-vault` command.

## How To Manage Sensitive Files with ansible-vault

The `ansible-vault` command is the main interface for managing encrypted content within Ansible. This command is used to initially encrypt files and is subsequently used to view, edit, or decrypt the data.

### Creating New Encrypted Files

To create a new file encrypted with Vault, use the `ansible-vault create` command. Pass in the name of the file you wish to create. For example, to create an encrypted YAML file called `vault.yml` to store sensitive variables, you could type:

    ansible-vault create vault.yml

You will be prompted to enter and confirm a password:

    OutputNew Vault password: 
    Confirm New Vault password:

When you have confirmed your password, Ansible will immediately open an editing window where you can enter your desired contents.

To test the encryption function, enter some test text:

vault.yml

    Secret information

Ansible will encrypt the contents when you close the file. If you check the file, instead of seeing the words you typed, you will see an encrypted block:

    cat vault.yml

    Output$ANSIBLE_VAULT;1.1;AES256
    65316332393532313030636134643235316439336133363531303838376235376635373430336333
    3963353630373161356638376361646338353763363434360a363138376163666265336433633664
    30336233323664306434626363643731626536643833336638356661396364313666366231616261
    3764656365313263620a383666383233626665376364323062393462373266663066366536306163
    31643731343666353761633563633634326139396230313734333034653238303166

We can see some header information that Ansible uses to know how to handle the file, followed by the encrypted contents, which display as numbers.

### Encrypting Existing Files

If you already have a file that you wish to encrypt with Vault, use the `ansible-vault encrypt` command instead.

For testing, we can create an example file by typing:

    echo 'unencrypted stuff' > encrypt_me.txt

Now, you can encrypt the existing file by typing:

    ansible-vault encrypt encrypt_me.txt

Again, you will be prompted to provide and confirm a password. Afterwards, a message will confirm the encryption:

    OutputNew Vault password: 
    Confirm New Vault password:
    Encryption successful

Instead of opening an editing window, `ansible-vault` will encrypt the contents of the file and write it back to disk, replacing the unencrypted version.

If we check the file, we should see a similar encrypted pattern:

    cat encrypt_me.txt

    Output$ANSIBLE_VAULT;1.1;AES256
    66633936653834616130346436353865303665396430383430353366616263323161393639393136
    3737316539353434666438373035653132383434303338640a396635313062386464306132313834
    34313336313338623537333332356231386438666565616537616538653465333431306638643961
    3636663633363562320a613661313966376361396336383864656632376134353039663662666437
    39393639343966363565636161316339643033393132626639303332373339376664

As you can see, Ansible encrypts existing content in much the same way as it encrypts new files.

### Viewing Encrypted Files

Sometimes, you may need to reference the contents of a vault-encrypted file without needing to edit it or write it to the filesystem unencrypted. The `ansible-vault view` command feeds the contents of a file to standard out. By default, this means that the contents are displayed in the terminal.

Pass the vault encrypted file to the command:

    ansible-vault view vault.yml

You will be asked for the file’s password. After entering it successfully, the contents will be displayed:

    OutputVault password:
    Secret information

As you can see, the password prompt is mixed into the output of file contents. Keep this in mind when using `ansible-vault view` in automated processes.

### Editing Encrypted Files

When you need to edit an encrypted file, use the `ansible-vault edit` command:

    ansible-vault edit vault.yml

You will be prompted for the file’s password. After entering it, Ansible will open the file an editing window, where you can make any necessary changes.

Upon saving, the new contents will be encrypted using the file’s encryption password again and written to disk.

### Manually Decrypting Encrypted Files

To decrypt a vault encrypted file, use the `ansible-vault decrypt` command.

**Note:** Because of the increased likelihood of accidentally committing sensitive data to your project repository, the `ansible-vault decrypt` command is only suggested for when you wish to remove encryption from a file permanently. If you need to view or edit a vault encrypted file, it is usually better to use the `ansible-vault view` or `ansible-vault edit` commands, respectively.

Pass in the name of the encrypted file:

    ansible-vault decrypt vault.yml

You will be prompted for the encryption password for the file. Once you enter the correct password, the file will be decrypted:

    OutputVault password:
    Decryption successful

If you view the file again, instead of the vault encryption, you should see the actual contents of the file:

    cat vault.yml

    OutputSecret information

Your file is now unencrypted on disk. Be sure to remove any sensitive information or re-encrypt the file when you are finished.

### Changing the Password of Encrypted Files

If you need to change the password of an encrypted file, use the `ansible-vault rekey` command:

    ansible-vault rekey encrypt_me.txt

When you enter the command, you will first be prompted with the file’s current password:

    OutputVault password:

After entering it, you will be asked to select and confirm a new vault password:

    OutputVault password:
    New Vault password:
    Confirm New Vault password:

When you have successfully confirmed a new password, you will receive a message indicating success of the re-encryption process:

    OutputRekey successful

The file should now be accessible using the new password. The old password will no longer work.

## Running Ansible with Vault-Encrypted Files

After you’ve encrypted your sensitive information with Vault, you can begin using the files with Ansible’s conventional tooling. The `ansible` and `ansible-playbook` commands both know how to decrypt vault-protected files given the correct password. There are a few different ways of providing passwords to these commands depending on your needs.

To follow along, you will need a vault-encrypted file. You can create one by typing:

    ansible-vault create secret_key

Select and confirm a password. Fill in whatever dummy contents you want:

secret\_key

    confidential data

Save and close the file.

We can also create a temporary `hosts` file as an inventory:

    nano hosts

We will add just the Ansible localhost to it. To prepare for a later step, we will place it in the `[database]` group:

hosts

    [database]
    localhost ansible_connection=local

Save and close the file when you are finished.

Next, create an `ansible.cfg` file in the current directory if one does not already exist:

    nano ansible.cfg

For now, just add a `[defaults]` section and point Ansible to the inventory we just created:

ansible.cfg

    [defaults]
    inventory = ./hosts

When you are ready, continue on.

### Using an Interactive Prompt

The most straightforward way of decrypting content at runtime is to have Ansible prompt you for the appropriate credentials. You can do this by adding the `--ask-vault-pass` to any `ansible` or `ansible-playbook` command. Ansible will prompt you for a password which it will use to try to decrypt any vault-protected content it finds.

For example, if we needed to copy the contents of a vault-encrypted file to a host, we could do so with the `copy` module and the `--ask-vault-pass` flag. If the file actually contains sensitive data, you will most likely want to lock down access on the remote host with permission and ownership restrictions.

**Note:** We are using `localhost` as the target host in this example to minimize the number of servers required, but the results should be the same as if the host were truly remote:

    ansible --ask-vault-pass -bK -m copy -a 'src=secret_key dest=/tmp/secret_key mode=0600 owner=root group=root' localhost

Our task specifies that the file’s ownership should be changed to `root`, so administrative privileges are required. The `-bK` flag tells Ansible to prompt for the `sudo` password for the target host, so you will be asked for your `sudo` password. You will then be asked for the Vault password:

    OutputSUDO password:
    Vault password:

When the password is provided, Ansible will attempt to execute the task, using the Vault password for any encrypted files it finds. Keep in mind that all files referenced during execution must use the same password:

    Outputlocalhost | SUCCESS => {
        "changed": true, 
        "checksum": "7a2eb5528c44877da9b0250710cba321bc6dac2d", 
        "dest": "/tmp/secret_key", 
        "gid": 0, 
        "group": "root", 
        "md5sum": "270ac7da333dd1db7d5f7d8307bd6b41", 
        "mode": "0600", 
        "owner": "root", 
        "size": 18, 
        "src": "/home/sammy/.ansible/tmp/ansible-tmp-1480978964.81-196645606972905/source", 
        "state": "file", 
        "uid": 0
    }

Prompting for a password is secure, but can be tedious, especially on repeated runs, and also hinders automation. Thankfully, there are some alternatives for these situations.

### Using Ansible Vault with a Password File

If you do not wish to type in the Vault password each time you execute a task, you can add your Vault password to a file and reference the file during execution.

For example, you could put your password in a `.vault_pass` file like this:

    echo 'my_vault_password' > .vault_pass

If you are using version control, make sure to add the password file to your version control software’s ignore file to avoid accidentally committing it:

    echo '.vault_pass' >> .gitignore

Now, you can reference the file instead. The `--vault-password-file` flag is available on the command line. We could complete the same task from the last section by typing:

    ansible --vault-password-file=.vault_pass -bK -m copy -a 'src=secret_key dest=/tmp/secret_key mode=0600 owner=root group=root' localhost

You will not be prompted for the Vault password this time.

### Reading the Password File Automatically

To avoid having to provide a flag at all, you can set the `ANSIBLE_VAULT_PASSWORD_FILE` environment variable with the path to the password file:

    export ANSIBLE_VAULT_PASSWORD_FILE=./.vault_pass

You should now be able to execute the command without the `--vault-password-file` flag for the current session:

    ansible -bK -m copy -a 'src=secret_key dest=/tmp/secret_key mode=0600 owner=root group=root' localhost

To make Ansible aware of the password file location across sessions, you can edit your `ansible.cfg` file.

Open the local `ansible.cfg` file we created earlier:

    nano ansible.cfg

In the `[defaults]` section, set the `vault_password_file` setting. Point to the location of your password file. This can be a relative or absolute path, depending on which is most useful for you:

ansible.cfg

    [defaults]
    . . .
    vault_password_file = ./.vault_pass

Now, when you run commands that require decryption, you will no longer be prompted for the vault password. As a bonus, `ansible-vault` will not only use the password in the file to decrypt any files, but it will apply the password when creating new files with `ansible-vault create` and `ansible-vault encrypt`.

### Reading the Password from an Environment Variable

You may be worried about accidentally committing your password file to your repository. Unfortunately, while Ansible has an environment variable to point to the location of a password file, it does _not_ have one for setting the password itself.

However, if your password file is executable, Ansible will run it as a script and use the resulting output as the password. In a [GitHub issue](https://github.com/mitchellh/packer/issues/555#issuecomment-145749614), [Brian Schwind](https://github.com/bschwind) suggests the following script can be used to pull the password from an environment variable.

Open up your `.vault_pass` file in your editor:

    nano .vault_pass

Replace the contents with the following script:

.vault\_pass

    #!/usr/bin/env python
    
    import os
    print os.environ['VAULT_PASSWORD']

Make the file executable by typing:

    chmod +x .vault_pass

You can then set and export the `VAULT_PASSWORD` environment variable, which will be available for your current session:

    export VAULT_PASSWORD=my_vault_password

You will have to do this at the beginning of each Ansible session, which may sound inconvenient. However, this effectively guards against accidentally committing your Vault encryption password, which could have serious drawbacks.

## Using Vault-Encrypted Variables with Regular Variables

While Ansible Vault can be used with arbitrary files, it is most frequently used to protect sensitive variables. We will work through an example to show you how to transform a regular variables file into a configuration that balances security and usability.

### Setting Up the Example

Pretend that you are configuring a database server. When you created the `hosts` file earlier, you placed the `localhost` entry in a group called `database` to prepare for this step.

Databases usually require a mixture of sensitive and nonsensitive variables. These can be assigned in a `group_vars` directory in a file named after the group:

    mkdir -p group_vars
    nano group_vars/database

Inside the `group_vars/database` file, set up some variables. Some variables, like the MySQL port number, are not secret and can be freely shared. Other variables, like the database password, will be confidential:

group\_vars/database

    ---
    # nonsensitive data
    mysql_port: 3306
    mysql_host: 10.0.0.3
    mysql_user: fred
    
    # sensitive data
    mysql_password: supersecretpassword

We can test that all of the variables are available to our host with Ansible’s `debug` module and the `hostvars` variable:

    ansible -m debug -a 'var=hostvars[inventory_hostname]' database

    Outputlocalhost | SUCCESS => {
        "hostvars[inventory_hostname]": {
            "ansible_check_mode": false, 
            "ansible_version": {
                "full": "2.2.0.0", 
                "major": 2, 
                "minor": 2, 
                "revision": 0, 
                "string": "2.2.0.0"
            }, 
            "group_names": [
                "database"
            ], 
            "groups": {
                "all": [
                    "localhost"
                ], 
                "database": [
                    "localhost"
                ], 
                "ungrouped": []
            }, 
            "inventory_dir": "/home/sammy", 
            "inventory_file": "hosts", 
            "inventory_hostname": "localhost", 
            "inventory_hostname_short": "localhost", 
            "mysql_host": "10.0.0.3",
            "mysql_password": "supersecretpassword",
            "mysql_port": 3306,
            "mysql_user": "fred",
            "omit": " __omit_place_holder__ 1c934a5a224ca1d235ff05eb9bda22044a6fb400", 
            "playbook_dir": "."
        }
    }

The output confirms that all of the variables we set up are applied to the host. However, our `group_vars/database` file currently holds all of our variables. This means we can either leave it unencrypted, which is a security concern because of the database password variable, or we encrypt all of the variables, which creates usability and collaboration issues.

### Moving Sensitive Variables into Ansible Vault

To solve this issue, we need to make a distinction between sensitive and nonsensitive variables. We should be able to encrypt confidential values and at the same time easily share our nonsensitive variables. To do so, we will split our variables between two files.

It is possible to use a variable _directory_ in place of an Ansible variable _file_ in order to apply variables from more than one file. We can refactor to take advantage of that ability. First, rename the existing file from `database` to `vars`. This will be our unencrypted variable file:

    mv group_vars/database group_vars/vars

Next, create a directory with the same name as the old variable file. Move the `vars` file inside:

    mkdir group_vars/database
    mv group_vars/vars group_vars/database/

We now have a variable directory for the `database` group instead of a single file and we have a single unencrypted variable file. Since we will be encrypting our sensitive variables, we should remove them from our unencrypted file. Edit the `group_vars/database/vars` file to remove the confidential data:

    nano group_vars/database/vars

In this case, we want to remove the `mysql_password` variable. The file should now look like this:

group\_vars/database/vars

    ---
    # nonsensitive data
    mysql_port: 3306
    mysql_host: 10.0.0.3
    mysql_user: fred

Next, create a vault-encrypted file within the directory that will live alongside the unencrypted `vars` file:

    ansible-vault create group_vars/database/vault

In this file, define the sensitive variables that used to be in the `vars` file. Use the same variable names, but prepend the string `vault_` to indicate that these variables are defined in the vault-protected file:

group\_vars/database/vault

    ---
    vault_mysql_password: supersecretpassword

Save and close the file when you are finished.

The resulting directory structure looks this:

    .
    ├── . . .
    ├── group_vars/
    │   └── database/
    │   ├── vars
    │   └── vault
    └── . . .

At this point, the variables are separate and only the confidential data is encrypted. This is secure, but our implementation has affected our usability. While our goal was to protect sensitive _values_, we’ve also unintentionally reduced visibility into the actual variable names. It is not clear which variables are assigned without referencing more than one file, and while you may wish to restrict access to confidential data while collaborating, you still probably want to share the variable names.

To address this, the Ansible project generally recommends a slightly different approach.

### Referencing Vault Variables from Unencrypted Variables

When we moved our sensitive data over to the vault-protected file, we prefaced the variable names with `vault_` (`mysql_password` became `vault_mysql_password`). We can add the original variable names (`mysql_password`) back to the unencrypted file. Instead of setting these to sensitive values directly, we can use Jinja2 templating statements to reference the encrypted variable names from within our unencrypted variable file. This way, you can see all of the defined variables by referencing a single file, but the confidential values will remain in the encrypted file.

To demonstrate, open the unencrypted variables file again:

    nano group_vars/database/vars

Add the `mysql_password` variable again. This time, use Jinja2 templating to reference the variable defined in the vault-protected file:

group\_vars/database/vars

    ---
    # nonsensitive data
    mysql_port: 3306
    mysql_host: 10.0.0.3
    mysql_user: fred
    
    # sensitive data
    mysql_password: "{{ vault_mysql_password }}"

The `mysql_password` variable will be set to the value of the `vault_mysql_password` variable, which is defined in the vault file.

With this method, you can understand all of the variables that will be applied to hosts in the `database` group by viewing the `group_vars/database/vars` file. The sensitive parts will be obscured by the Jinja2 templating. The `group_vars/database/vault` only needs to be opened when the values themselves need to be viewed or changed.

You can check to make sure that all of the `mysql_*` variables are still correctly applied using the same method as last time.

**Note:** If your Vault password is not being automatically applied with a password file, add the `--ask-vault-pass` flag to the command below.

    ansible -m debug -a 'var=hostvars[inventory_hostname]' database

    Outputlocalhost | SUCCESS => {
        "hostvars[inventory_hostname]": {
            "ansible_check_mode": false, 
            "ansible_version": {
                "full": "2.2.0.0", 
                "major": 2, 
                "minor": 2, 
                "revision": 0, 
                "string": "2.2.0.0"
            }, 
            "group_names": [
                "database"
            ], 
            "groups": {
                "all": [
                    "localhost"
                ], 
                "database": [
                    "localhost"
                ], 
                "ungrouped": []
            }, 
            "inventory_dir": "/home/sammy/vault", 
            "inventory_file": "./hosts", 
            "inventory_hostname": "localhost", 
            "inventory_hostname_short": "localhost", 
            "mysql_host": "10.0.0.3",
            "mysql_password": "supersecretpassword",
            "mysql_port": 3306,
            "mysql_user": "fred",
            "omit": " __omit_place_holder__ 6dd15dda7eddafe98b6226226c7298934f666fc8", 
            "playbook_dir": ".", 
            "vault_mysql_password": "supersecretpassword"
        }
    }

Both the `vault_mysql_password` and the `mysql_password` are accessible. This duplication is harmless and will not affect your use of this system.

## Conclusion

Your projects should have all of the information required to successfully install and configure complex systems. However, some configuration data is by definition sensitive and should not be publicly exposed. In this guide, we demonstrated how Ansible Vault can encrypt confidential information so that you can keep your all of your configuration data in one place without compromising security.
