---
author: Varun Chopra
date: 2019-02-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-implement-continuous-testing-of-ansible-roles-using-molecule-and-travis-ci-on-ubuntu-18-04
---

# How To Implement Continuous Testing of Ansible Roles Using Molecule and Travis CI on Ubuntu 18.04

_The author selected the [Mozilla Foundation](https://www.brightfunds.org/organizations/mozilla-foundation) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[Ansible](https://www.ansible.com/) is an agentless configuration management tool that uses YAML templates to define a list of tasks to be performed on hosts. In Ansible, _roles_ are a collection of variables, tasks, files, templates and modules that are used together to perform a singular, complex function.

[Molecule](https://molecule.readthedocs.io/en/latest/) is a tool for performing automated testing of Ansible roles, specifically designed to support the development of consistently well-written and maintained roles. Molecule’s unit tests allow developers to test roles simultaneously against multiple environments and under different parameters. It’s important that developers continuously run tests against code that often changes; this workflow ensures that roles continue to work as you update code libraries. Running Molecule using a continuous integration tool, like [Travis CI](https://travis-ci.org/), allows for tests to run continuously, ensuring that contributions to your code do not introduce breaking changes.

In this tutorial, you will use a pre-made base role that installs and configures an Apache web server and a firewall on Ubuntu and CentOS servers. Then, you will initialize a Molecule scenario in that role to create tests and ensure that the role performs as intended in your target environments. After configuring Molecule, you will use Travis CI to continuously test your newly created role. Every time a change is made to your code, Travis CI will run `molecule test` to make sure that the role still performs correctly.

## Prerequisites

Before you begin this tutorial, you will need:

- One Ubuntu 18.04 server set up by following the [Ubuntu 18.04 Initial Server Setup](initial-server-setup-with-ubuntu-18-04) guide, including a sudo non-root user and a firewall.
- Ansible and Molecule configured, which you can do by following Step 1 of [How To Test Ansible Roles with Molecule on Ubuntu 18.04](how-to-test-ansible-roles-with-molecule-on-ubuntu-18-04).
- Git installed by following [How To Contribute to Open Source: Getting Started with Git](how-to-contribute-to-open-source-getting-started-with-git).
- Familiarity with continuous integration and its use cases. To learn more, review [An Introduction to Continuous Integration, Delivery, and Deployment](an-introduction-to-continuous-integration-delivery-and-deployment).
- An account on [GitHub](https://github.com/).
- An account on [Travis CI](https://travis-ci.org/).

## Step 1 — Forking the Base Role Repository

You will be using a pre-made role called [ansible-apache](https://github.com/do-community/ansible-apache) that installs Apache and configures a firewall on Debian- and Red Hat-based distributions. You will fork and use this role as a base and then build Molecule tests on top of it. Forking allows you to create a copy of a repository so you can make changes to it without tampering with the original project.

Start by creating a fork of the **ansible-apache** role. Go to the [ansible-apache](https://github.com/do-community/ansible-apache) repository and click on the **Fork** button.

Once you have forked the repository, GitHub will lead you to your fork’s page. This will be a copy of the base repository, but on your own account.

Click on the green **Clone or Download** button and you’ll see a box with **Clone with HTTPS**.

Copy the URL shown for your repository. You’ll use this in the next step. The URL will be similar to this:

    https://github.com/username/ansible-apache.git

You will replace `username` with your GitHub username.

With your fork set up, you will clone it on your server and begin preparing your role in the next section.

## Step 2 — Preparing Your Role

Having followed Step 1 of the prerequisite [How To Test Ansible Roles with Molecule on Ubuntu 18.04](how-to-test-ansible-roles-with-molecule-on-ubuntu-18-04), you will have Molecule and Ansible installed in a virtual environment. You will use this virtual environment for developing your new role.

First, activate the virtual environment you created while following the prerequisites by running:

    source my_env/bin/activate

Run the following command to clone the repository using the URL you just copied in Step 1:

    git clone https://github.com/username/ansible-apache.git

Your output will look similar to the following:

    OutputCloning into 'ansible-apache'...
    remote: Enumerating objects: 16, done.
    remote: Total 16 (delta 0), reused 0 (delta 0), pack-reused 16
    Unpacking objects: 100% (16/16), done.

Move into the newly created directory:

    cd ansible-apache

The base role you’ve downloaded performs the following tasks:

- **Includes variables** : The role starts by including all the required _variables_ according to the distribution of the host. Ansible uses variables to handle the disparities between different systems. Since you are using Ubuntu 18.04 and CentOS 7 as hosts, the role will recognize that the OS families are Debian and Red Hat respectively and include variables from `vars/Debian.yml` and `vars/RedHat.yml`.

- **Includes distribution-relevant tasks** : These tasks include `tasks/install-Debian.yml` and `tasks/install-RedHat.yml`. Depending on the specified distribution, it installs the relevant packages. For Ubuntu, these packages are `apache2` and `ufw`. For CentOS, these packages are `httpd` and `firewalld`.

- **Ensures latest index.html is present** : This task copies over a template `templates/index.html.j2` that Apache will use as the web server’s home page.

- **Starts relevant services and enables them on boot** : Starts and enables the required services installed as part of the first task. For CentOS, these services are `httpd` and `firewalld`, and for Ubuntu, they are `apache2` and `ufw`.

- **Configures firewall to allow traffic** : This includes either `tasks/configure-Debian-firewall.yml` or `tasks/configure-RedHat-firewall.yml`. Ansible configures either Firewalld or UFW as the firewall and whitelists the `http` service.

Now that you have an understanding of how this role works, you will configure Molecule to test it. You will write test cases for these tasks that cover the changes they make.

## Step 3 — Writing Your Tests

To check that your base role performs its tasks as intended, you will start a Molecule scenario, specify your target environments, and create three custom test files.

Begin by initializing a Molecule scenario for this role using the following command:

    molecule init scenario -r ansible-apache

You will see the following output:

    Output--> Initializing new scenario default...
    Initialized scenario in /home/sammy/ansible-apache/molecule/default successfully.

You will add CentOS and Ubuntu as your target environments by including them as platforms in your Molecule configuration file. To do this, edit the `molecule.yml` file using a text editor:

    nano molecule/default/molecule.yml

Add the following highlighted content to the Molecule configuration:

~/ansible-apache/molecule/default/molecule.yml

    ---
    dependency:
      name: galaxy
    driver:
      name: docker
    lint:
      name: yamllint
    platforms:
      - name: centos7
        image: milcom/centos7-systemd
        privileged: true
      - name: ubuntu18
        image: solita/ubuntu-systemd
        command: /sbin/init
        privileged: true
        volumes:
          - /lib/modules:/lib/modules:ro
    provisioner:
      name: ansible
      lint:
        name: ansible-lint
    scenario:
      name: default
    verifier:
      name: testinfra
      lint:
        name: flake8

Here, you’re specifying two target platforms that are launched in privileged mode since you’re working with systemd services:

- `centos7` is the first platform and uses the `milcom/centos7-systemd` image.
- `ubuntu18` is the second platform and uses the `solita/ubuntu-systemd` image. In addition to using privileged mode and mounting the required kernel modules, you’re running `/sbin/init` on launch to make sure iptables is up and running.

Save and exit the file.

For more information on running privileged containers visit the [official Molecule documentation](https://molecule.readthedocs.io/en/latest/examples.html#systemd-container).

Instead of using the default Molecule test file, you will be creating three custom test files, one for each target platform, and one file for writing tests that are common between all platforms. Start by deleting the scenario’s default test file `test_default.py` with the following command:

    rm molecule/default/tests/test_default.py

You can now move on to creating the three custom test files, `test_common.py`, `test_Debian.py`, and `test_RedHat.py` for each of your target platforms.

The first test file, `test_common.py`, will contain the common tests that each of the hosts will perform. Create and edit the common test file, `test_common.py`:

    nano molecule/default/tests/test_common.py

Add the following code to the file:

~/ansible-apache/molecule/default/tests/test\_common.py

    import os
    import pytest
    
    import testinfra.utils.ansible_runner
    
    testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
        os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')
    
    
    @pytest.mark.parametrize('file, content', [
      ("/var/www/html/index.html", "Managed by Ansible")
    ])
    def test_files(host, file, content):
        file = host.file(file)
    
        assert file.exists
        assert file.contains(content)

In your `test_common.py` file, you have imported the required libraries. You have also written a test called `test_files()`, which holds the only common task between distributions that your role performs: copying your template as the web servers homepage.

The next test file, `test_Debian.py`, holds tests specific to Debian distributions. This test file will specifically target your Ubuntu platform.

Create and edit the Ubuntu test file by running the following command:

    nano molecule/default/tests/test_Debian.py

You can now import the required libraries and define the `ubuntu18` platform as the target host. Add the following code to the start of this file:

~/ansible-apache/molecule/default/tests/test\_Debian.py

    import os
    import pytest
    
    import testinfra.utils.ansible_runner
    
    testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
        os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('ubuntu18')

Then, in the same file, you’ll add `test_pkg()` test.

Add the following code to the file, which defines the `test_pkg()` test:

~/ansible-apache/molecule/default/tests/test\_Debian.py

    ...
    @pytest.mark.parametrize('pkg', [
        'apache2',
        'ufw'
    ])
    def test_pkg(host, pkg):
        package = host.package(pkg)
    
        assert package.is_installed

This test will check if `apache2` and `ufw` packages are installed on the host.

**Note:** When adding multiple tests to a Molecule test file, make sure there are two blank lines between each test or you’ll get a syntax error from Molecule.

To define the next test, `test_svc()`, add the following code under the `test_pkg()` test in your file:

~/ansible-apache/molecule/default/tests/test\_Debian.py

    ...
    @pytest.mark.parametrize('svc', [
        'apache2',
        'ufw'
    ])
    def test_svc(host, svc):
        service = host.service(svc)
    
        assert service.is_running
        assert service.is_enabled

`test_svc()` will check if the `apache2` and `ufw` services are running and enabled.

Finally you will add your last test, `test_ufw_rules()`, to the `test_Debian.py` file.

Add this code under the `test_svc()` test in your file to define `test_ufw_rules()`:

~/ansible-apache/molecule/default/tests/test\_Debian.py

    ...
    @pytest.mark.parametrize('rule', [
        '-A ufw-user-input -p tcp -m tcp --dport 80 -j ACCEPT'
    ])
    def test_ufw_rules(host, rule):
        cmd = host.run('iptables -t filter -S')
    
        assert rule in cmd.stdout

`test_ufw_rules()` will check that your firewall configuration permits traffic on the port used by the Apache service.

With each of these tests added, your `test_Debian.py` file will look like this:

~/ansible-apache/molecule/default/tests/test\_Debian.py

    import os
    import pytest
    
    import testinfra.utils.ansible_runner
    
    testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
        os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('ubuntu18')
    
    
    @pytest.mark.parametrize('pkg', [
        'apache2',
        'ufw'
    ])
    def test_pkg(host, pkg):
        package = host.package(pkg)
    
        assert package.is_installed
    
    
    @pytest.mark.parametrize('svc', [
        'apache2',
        'ufw'
    ])
    def test_svc(host, svc):
        service = host.service(svc)
    
        assert service.is_running
        assert service.is_enabled
    
    
    @pytest.mark.parametrize('rule', [
        '-A ufw-user-input -p tcp -m tcp --dport 80 -j ACCEPT'
    ])
    def test_ufw_rules(host, rule):
        cmd = host.run('iptables -t filter -S')
    
        assert rule in cmd.stdout

The `test_Debian.py` file now includes the three tests: `test_pkg()`, `test_svc()`, and `test_ufw_rules()`.

Save and exit `test_Debian.py`.

Next you’ll create the `test_RedHat.py` test file, which will contain tests specific to Red Hat distributions to target your CentOS platform.

Create and edit the CentOS test file, `test_RedHat.py`, by running the following command:

    nano molecule/default/tests/test_RedHat.py

Similarly to the Ubuntu test file, you will now write three tests to include in your `test_RedHat.py` file. Before adding the test code, you can import the required libraries and define the `centos7` platform as the target host, by adding the following code to the beginning of your file:

~/ansible-apache/molecule/default/tests/test\_RedHat.py

    import os
    import pytest
    
    import testinfra.utils.ansible_runner
    
    testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
        os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('centos7')

Then, add the `test_pkg()` test, which will check if the `httpd` and `firewalld` packages are installed on the host.

Following the code for your library imports, add the `test_pkg()` test to your file. (Again, remember to include two blank lines before each new test.)

~/ansible-apache/molecule/default/tests/test\_RedHat.py

    ...
    @pytest.mark.parametrize('pkg', [
        'httpd',
        'firewalld'
    ])
    def test_pkg(host, pkg):
        package = host.package(pkg)
    
          assert package.is_installed

Now, you can add the `test_svc()` test to ensure that `httpd` and `firewalld` services are running and enabled.

Add the `test_svc()` code to your file following the `test_pkg()` test:

~/ansible-apache/molecule/default/tests/test\_RedHat.py

    ...
    @pytest.mark.parametrize('svc', [
        'httpd',
        'firewalld'
    ])
      def test_svc(host, svc):
        service = host.service(svc)
    
        assert service.is_running
        assert service.is_enabled

The final test in `test_RedHat.py` file will be `test_firewalld()`, which will check if Firewalld has the `http` service whitelisted.

Add the `test_firewalld()` test to your file after the `test_svc()` code:

~/ansible-apache/molecule/default/tests/test\_RedHat.py

    ...
    @pytest.mark.parametrize('file, content', [
        ("/etc/firewalld/zones/public.xml", "<service name=\"http\"/>")
    ])
    def test_firewalld(host, file, content):
        file = host.file(file)
    
        assert file.exists
        assert file.contains(content)

After importing the libraries and adding the three tests, your `test_RedHat.py` file will look like this:

~/ansible-apache/molecule/default/tests/test\_RedHat.py

    import os
    import pytest
    
    import testinfra.utils.ansible_runner
    
    testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
        os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('centos7')
    
    
    @pytest.mark.parametrize('pkg', [
        'httpd',
        'firewalld'
    ])
    def test_pkg(host, pkg):
        package = host.package(pkg)
    
        assert package.is_installed
    
    
    @pytest.mark.parametrize('svc', [
        'httpd',
        'firewalld'
    ])
    def test_svc(host, svc):
        service = host.service(svc)
    
        assert service.is_running
        assert service.is_enabled
    
    
    @pytest.mark.parametrize('file, content', [
        ("/etc/firewalld/zones/public.xml", "<service name=\"http\"/>")
    ])
    def test_firewalld(host, file, content):
        file = host.file(file)
    
        assert file.exists
        assert file.contains(content)

Now that you’ve completed writing tests in all three files, `test_common.py`, `test_Debian.py`, and `test_RedHat.py`, your role is ready for testing. In the next step, you will use Molecule to run these tests against your newly configured role.

## Step 4 — Testing Against Your Role

You will now execute your newly created tests against the base role `ansible-apache` using Molecule. To run your tests, use the following command:

    molecule test

You’ll see the following output once Molecule has finished running all the tests:

    Output...
    --> Scenario: 'default'
    --> Action: 'verify'
    --> Executing Testinfra tests found in /home/sammy/ansible-apache/molecule/default/tests/...
        ============================= test session starts ==============================
        platform linux -- Python 3.6.7, pytest-4.1.1, py-1.7.0, pluggy-0.8.1
        rootdir: /home/sammy/ansible-apache/molecule/default, inifile:
        plugins: testinfra-1.16.0
    collected 12 items
    
        tests/test_common.py .. [16%]
        tests/test_RedHat.py ..... [58%]
        tests/test_Debian.py ..... [100%]
    
        ========================== 12 passed in 80.70 seconds ==========================
    Verifier completed successfully.

You’ll see `Verifier completed successfully` in your output; this means that the verifier executed all of your tests and returned them successfully.

Now that you’ve successfully completed the development of your role, you can commit your changes to Git and set up Travis CI for continuous testing.

## Step 5 — Using Git to Share Your Updated Role

In this tutorial, so far, you have cloned a role called `ansible-apache` and added tests to it to make sure it works against Ubuntu and CentOS hosts. To share your updated role with the public, you must commit these changes and push them to your fork.

Run the following command to add the files and commit the changes you’ve made:

    git add .

This command will add all the files that you have modified in the current directory to the staging area.

You also need to set your name and email address in the `git config` in order to commit successfully. You can do so using the following commands:

    git config user.email "sammy@digitalocean.com"
    git config user.name "John Doe"

Commit the changed files to your repository:

    git commit -m "Configured Molecule"

You’ll see the following output:

    Output[master b2d5a5c] Configured Molecule
     8 files changed, 155 insertions(+), 1 deletion(-)
     create mode 100644 molecule/default/Dockerfile.j2
     create mode 100644 molecule/default/INSTALL.rst
     create mode 100644 molecule/default/molecule.yml
     create mode 100644 molecule/default/playbook.yml
     create mode 100644 molecule/default/tests/test_Debian.py
     create mode 100644 molecule/default/tests/test_RedHat.py
     create mode 100644 molecule/default/tests/test_common.py

This signifies that you have committed your changes successfully. Now, push these changes to your fork with the following command:

    git push -u origin master

You will see a prompt for your GitHub credentials. After entering these credentials, your code will be pushed to your repository and you’ll see this output:

    OutputCounting objects: 13, done.
    Compressing objects: 100% (12/12), done.
    Writing objects: 100% (13/13), 2.32 KiB | 2.32 MiB/s, done.
    Total 13 (delta 3), reused 0 (delta 0)
    remote: Resolving deltas: 100% (3/3), completed with 2 local objects.
    To https://github.com/username/ansible-apache.git
       009d5d6..e4e6959 master -> master
    Branch 'master' set up to track remote branch 'master' from 'origin'.
    

If you go to your fork’s repository at `github.com/username/ansible-apache`, you’ll see a new commit called `Configured Molecule` reflecting the changes you made in the files.

Now, you can integrate Travis CI with your new repository so that any changes made to your role will automatically trigger Molecule tests. This will ensure that your role always works with Ubuntu and CentOS hosts.

## Step 6 — Integrating Travis CI

In this step, you’re going to integrate Travis CI into your workflow. Once enabled, any changes you push to your fork will trigger a Travis CI build. The purpose of this is to ensure Travis CI always runs `molecule test` whenever contributors make changes. If any breaking changes are made, Travis will declare the build status as such.

Proceed to [Travis CI](https://travis-ci.org) to enable your repository. Navigate to your profile page where you can click the **Activate** button for GitHub.

You can find further guidance [here](https://travis-ci.com/getting_started) on activating repositories in Travis CI.

For Travis CI to work, you must create a configuration file containing instructions for it. To create the Travis configuration file, return to your server and run the following command:

    nano .travis.yml

To duplicate the environment you’ve created in this tutorial, you will specify parameters in the Travis configuration file. Add the following content to your file:

~/ansible-apache/.travis.yml

    ---
    language: python
    python:
      - "2.7"
      - "3.6"
    services:
      - docker
    install:
      - pip install molecule docker
    script:
      - molecule --version
      - ansible --version
      - molecule test

The parameters you’ve specified in this file are:

- `language`: When you specify Python as the language, the CI environment uses separate `virtualenv` instances for each Python version you specify under the `python` key.
- `python`: Here, you’re specifying that Travis will use both Python 2.7 and Python 3.6 to run your tests.
- `services`: You need Docker to run tests in Molecule. You’re specifying that Travis should ensure Docker is present in your CI environment.
- `install`: Here, you’re specifying preliminary installation steps that Travis CI will carry out in your `virtualenv`.
  - `pip install molecule docker` to check that Ansible and Molecule are present along with the Python library for the Docker remote API.
- `script`: This is to specify the steps that Travis CI needs to carry out. In your file, you’re specifying three steps:
  - `molecule --version` prints the Molecule version if Molecule has been successfully installed.
  - `ansible --version` prints the Ansible version if Ansible has been successfully installed.
  - `molecule test` finally runs your Molecule tests.

The reason you specify `molecule --version` and `ansible --version` is to catch errors in case the build fails as a result of `ansible` or `molecule` misconfiguration due to versioning.

Once you’ve added the content to the Travis CI configuration file, save and exit `.travis.yml`.

Now, every time you push any changes to your repository, Travis CI will automatically run a build based on the above configuration file. If any of the commands in the `script` block fail, Travis CI will report the build status as such.

To make it easier to see the build status, you can add a badge indicating the build status to the `README` of your role. Open the `README.md` file using a text editor:

    nano README.md

Add the following line to the `README.md` to display the build status:

~/ansible-apache/README.md

    [![Build Status](https://travis-ci.org/username/ansible-apache.svg?branch=master)](https://travis-ci.org/username/ansible-apache)

Replace `username` with your GitHub username. Commit and push the changes to your repository as you did earlier.

First, run the following command to add `.travis.yml` and `README.md` to the staging area:

    git add .travis.yml README.md

Now commit the changes to your repository by executing:

    git commit -m "Configured Travis"

Finally, push these changes to your fork with the following command:

    git push -u origin master

If you navigate over to your GitHub repository, you will see that it initially reports **build: unknown**.

![build-status-unknown](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ansible_traivis/step6a.png)

Within a few minutes, Travis will initiate a build that you can monitor at the Travis CI website. Once the build is a success, GitHub will report the status as such on your repository as well — using the badge you’ve placed in your README file:

![build-status-passing](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ansible_traivis/step6b.png)

You can access the complete details of the builds by going to the Travis CI website:

![travis-build-status](https://raw.githubusercontent.com/opendocs-md/do-tutorials-images/master/img/ansible_traivis/step6c.png)

Now that you’ve successfully set up Travis CI for your new role, you can continuously test and integrate changes to your Ansible roles.

## Conclusion

In this tutorial, you forked a role that installs and configures an Apache web server from GitHub and added integrations for Molecule by writing tests and configuring these tests to work on Docker containers running Ubuntu and CentOS. By pushing your newly created role to GitHub, you have allowed other users to access your role. When there are changes to your role by contributors, Travis CI will automatically run Molecule to test your role.

Once you’re comfortable with the creation of roles and testing them with Molecule, you can integrate this with [Ansible Galaxy](https://galaxy.ansible.com/docs/) so that roles are automatically pushed once the build is successful.
