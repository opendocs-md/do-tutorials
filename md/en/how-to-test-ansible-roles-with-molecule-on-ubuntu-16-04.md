---
author: Varun Chopra
date: 2018-07-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-test-ansible-roles-with-molecule-on-ubuntu-16-04
---

# How To Test Ansible Roles with Molecule on Ubuntu 16.04

_The author selected the [Mozilla Foundation](https://www.brightfunds.org/organizations/mozilla-foundation) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

Unit testing in [Ansible](https://www.ansible.com/) is key to making sure roles function as intended. [Molecule](https://github.com/metacloud/molecule/) makes this process easier by allowing you to specify scenarios that test roles against different environments. Using Ansible under the hood, Molecule offloads roles to a provisioner that deploys the role in a configured environment and calls a verifier (such as [Testinfra](https://github.com/philpep/testinfra)) to check for configuration drift. This ensures that your role has made all of the expected changes to the environment in that particular scenario.

In this guide, you will build an Ansible role that deploys [Apache](https://httpd.apache.org/) to a host and configures [Firewalld](https://firewalld.org/) on CentOS 7. To test that this role works as intended, you will create a test in Molecule using [Docker](https://www.docker.com/) as a driver and Testinfra, a Python library for testing the state of servers. Molecule will provision Docker containers to test the role and Testinfra will verify that the server has been configured as intended. When you’re finished, you’ll be able to create multiple test cases for builds across environments and run these tests using Molecule.

## Prerequisites

Before you begin this guide you’ll need the following:

- One Ubuntu 16.04 server. Follow the steps in the [Initial Server Setup with Ubuntu 16.04](initial-server-setup-with-ubuntu-16-04) guide to create a non-root sudo user, and make sure you can connect to the server without a password.
- Docker installed on your server. Follow Steps 1 and 2 in [How To Install and Use Docker on Ubuntu 16.04](how-to-install-and-use-docker-on-ubuntu-16-04), and be sure to add your non-root user to the `docker` group.
- Familiarity with Ansible playbooks. For review, see [Configuration Management 101: Writing Ansible Playbooks](configuration-management-101-writing-ansible-playbooks).

## Step 1 — Preparing the Environment

In order to create our role and tests, let’s first create a virtual environment and install Molecule. Installing Molecule will also install Ansible, enabling the use of playbooks to create roles and run tests.

Start by logging in as your non-root user and making sure your repositories are up-to-date:

    sudo apt-get update

This will ensure that your package repository includes the latest version of the `python-pip` package, which will install `pip` and Python 2.7. We will use `pip` to create a virtual environment and install additional packages. To install `pip`, run:

    sudo apt-get install -y python-pip

Use `pip` to install the `virtualenv` Python module:

    python -m pip install virtualenv

Next, let’s create and activate the virtual environment:

    python -m virtualenv my_env

Activate it to ensure that your actions are restricted to that environment:

    source my_env/bin/activate

Install `molecule` and `docker` using `pip`:

    python -m pip install molecule docker

Here is what each of these packages will do:

- `molecule`: This is the main Molecule package that you will use to test roles. Installing `molecule` automatically installs Ansible, along with other dependencies, and enables the use of Ansible playbooks to execute roles and tests.
- `docker`: This Python library is used by Molecule to interface with Docker. You will need this since you’re using Docker as a driver.

Next, let’s create a role in Molecule.

## Step 2 — Creating a Role in Molecule

With your environment set up, you can use Molecule to create a basic role to test an installation of Apache. This role will create the directory structure and some initial tests, and specify Docker as the driver so that Molecule uses Docker to run its tests.

Create a new role called `ansible-apache`:

    molecule init role -r ansible-apache -d docker

The `-r` flag specifies the name of the role while `-d` specifies the driver, which provisions the hosts for Molecule to use in testing.

Change into the directory of the newly created role:

    cd ansible-apache

Test the default role to check if Molecule has been set up properly:

    molecule test

You will see output that lists each of the default test actions:

    Output--> Validating schema /home/sammy/ansible-apache/molecule/default/molecule.yml.
    Validation completed successfully.
    --> Test matrix
    
    └── default
        ├── lint
        ├── destroy
        ├── dependency
        ├── syntax
        ├── create
        ├── prepare
        ├── converge
        ├── idempotence
        ├── side_effect
        ├── verify
        └── destroy
    ...

Before starting the test, Molecule validates the configuration file `molecule.yml` to make sure everything is in order. It also prints this test matrix, which specifies the order of test actions.

We will discuss each test action in detail once you’ve created your role and customized your tests. For now, pay attention to the `PLAY_RECAP` for each test, and be sure that none of the default actions returns a `failed` status. For example, the `PLAY_RECAP` for the default `'create'` action should look like this:

    Output...
    PLAY RECAP *********************************************************************
    localhost : ok=5 changed=4 unreachable=0 failed=0

Let’s move on to modifying the role to configure Apache and Firewalld.

## Step 3 — Configuring Apache and Firewalld

To configure Apache and Firewalld, you will create a tasks file for the role, specifying packages to install and services to enable. These details will be extracted from a variables file and template that you will use to replace the default Apache index page.

Create a tasks file for the role using `nano` or your favorite text editor:

    nano tasks/main.yml

You’ll see that the file already exists. Delete what’s there and paste the following code to install the required packages and enable the correct services, HTML defaults, and firewall settings:

~/ansible-apache/tasks/main.yml

    ---
    - name: "Ensure required packages are present"
      yum:
        name: "{{ pkg_list }}"
        state: present
    
    - name: "Ensure latest index.html is present"
      template:
        src: index.html.j2
        dest: /var/www/html/index.html
    
    - name: "Ensure httpd service is started and enabled"
      service:
        name: "{{ item }}"
        state: started
        enabled: true
      with_items: "{{ svc_list }}"
    
    - name: "Whitelist http in firewalld"
      firewalld:
        service: http
        state: enabled
        permanent: true
        immediate: true

This playbook includes 4 tasks:

- `"Ensure required packages are present"`: This task will install the packages listed in the variables file under `pkg_list`. The variables file will be located at `~/ansible-apache/vars/main.yml` and you will create it at the end of this step.
- `"Ensure latest index.html is present"`: This task will copy a template page `index.html.j2` and paste it over the default index file, `/var/www/html/index.html`, generated by Apache. You will also create the template in this step.
- `"Ensure httpd service is started and enabled"`: This task will start and enable the services listed in `svc_list` in the variables file.
- `"Whitelist http in firewalld"`: This task will whitelist the `http` service in `firewalld`. Firewalld is a complete firewall solution present by default on CentOS servers. For the `http` service to work, you will need to expose the required ports. Instructing `firewalld` to whitelist a service ensures that it whitelists all of the ports that the service requires.

Save and close the file when you are finished.

Next, let’s create a `templates` directory for the `index.html.j2` template page:

    mkdir templates

Create the page itself:

    nano templates/index.html.j2

Paste in the following boilerplate code:

~/ansible-apache/templates/index.html.j2

    <div style="text-align: center">
        <h2>Managed by Ansible</h2>
    </div>

Save and close the file.

The final step in completing the role is writing the variables file, which provides the names of packages and services to your main role playbook:

    nano vars/main.yml

Paste over the default content with the following code, which specifies `pkg_list` and `svc_list`:

~/ansible-apache/vars/main.yml

    ---
    pkg_list:
      - httpd
      - firewalld
    svc_list:
      - httpd
      - firewalld

These lists contain the following information:

- `pkg_list`: This contains the names of the packages that the role will install: `httpd` and `firewalld`.
- `svc_list`: This contains the names of the services that the role will start and enable: `httpd` and `firewalld`.

**Note:** Make sure that your variables file doesn’t have any blank lines or your test will fail during linting.

Now that you’ve finished creating the role, let’s configure Molecule to test if it works as intended.

## Step 4 — Modifying the Role for Running Tests

In our case, configuring Molecule involves modifying the Molecule configuration file `molecule.yml` to add platform specifications. Because you’re testing a role that configures and starts the `httpd` systemd service, you will need to use an image with systemd configured and privileged mode enabled. For this tutorial, you will use the `milcom/centos7-systemd` image [available on Docker Hub](https://hub.docker.com/r/milcom/centos7-systemd/). Privileged mode allows containers to run with almost all of the capabilities of their host machine.

Let’s edit `molecule.yml` to reflect these changes:

    nano molecule/default/molecule.yml

Add the highlighted platform information:

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

Save and close the file when you are done.

Now that you’ve successfully configured the test environment, let’s move on to writing the test cases that Molecule will run against your container after executing the role.

## Step 5 — Writing Test Cases

In the test for this role, you will check the following conditions:

- That the `httpd` and `firewalld` packages are installed.
- That the `httpd` and `firewalld` services are running and enabled.
- That the `http` service is enabled in your firewall settings.
- That `index.html` contains the same data specified in your template file.

If all of these tests pass, then the role works as intended.

To write the test cases for these conditions, let’s edit the default tests in `~/ansible-apache/molecule/default/tests/test_default.py`. Using Testinfra, you will write the test cases as Python functions that use Molecule classes.

Open `test_default.py`:

    nano molecule/default/tests/test_default.py

Delete the contents of the file so that you can write the tests from scratch.

**Note:** As you write your tests, make sure that they are separated by two new lines or they will fail.

Start by importing the required Python modules:

~/ansible-apache/molecule/default/tests/test\_default.py

    import os
    import pytest
    
    import testinfra.utils.ansible_runner

These modules include:

- `os`: This built-in Python module enables operating-system-dependent functionality, making it possible for Python to interface with the underlying operating system.
- `pytest`: The [`pytest`](https://docs.pytest.org/en/latest/) module enables test writing.
- `testinfra.utils.ansible_runner`: This Testinfra module uses [Ansible as the backend](https://testinfra.readthedocs.io/en/latest/backends.html#ansible) for command execution.

Under the module imports, paste in the following code, which uses the Ansible backend to return the current host instance:

~/ansible-apache/molecule/default/tests/test\_default.py

    ...
    testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
        os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')

With your test file configured to use the Ansible backend, let’s write unit tests to test the state of the host.

The first test will ensure that `httpd` and `firewalld` are installed:

~/ansible-apache/molecule/default/tests/test\_default.py

    ...
    
    @pytest.mark.parametrize('pkg', [
      'httpd',
      'firewalld'
    ])
    def test_pkg(host, pkg):
        package = host.package(pkg)
    
        assert package.is_installed

The test begins with the [`pytest.mark.parametrize` decorator](https://docs.pytest.org/en/latest/parametrize.html#pytest-mark-parametrize-parametrizing-test-functions), which allows us to parameterize the arguments for the test. This first test will take `test_pkg` as a parameter to test for the presence of the `httpd` and `firewalld` packages.

The next test checks whether or not `httpd` and `firewalld` are running and enabled. It takes `test_svc` as a parameter:

~/ansible-apache/molecule/default/tests/test\_default.py

    ...
    
    @pytest.mark.parametrize('svc', [
      'httpd',
      'firewalld'
    ])
    def test_svc(host, svc):
        service = host.service(svc)
    
        assert service.is_running
        assert service.is_enabled

The last test checks that the files and contents passed to `parametrize()` exist. If the file isn’t created by your role and the content isn’t set properly, `assert` will return `False`:

~/ansible-apache/molecule/default/tests/test\_default.py

    ...
    
    @pytest.mark.parametrize('file, content', [
      ("/etc/firewalld/zones/public.xml", "<service name=\"http\"/>"),
      ("/var/www/html/index.html", "Managed by Ansible")
    ])
    def test_files(host, file, content):
        file = host.file(file)
    
        assert file.exists
        assert file.contains(content)

In each test, `assert` will return `True` or `False` depending on the test result.

The finished file looks like this:

~/ansible-apache/molecule/default/tests/test\_default.py

    import os
    import pytest
    
    import testinfra.utils.ansible_runner
    
    testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
        os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')
    
    
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
      ("/etc/firewalld/zones/public.xml", "<service name=\"http\"/>"),
      ("/var/www/html/index.html", "Managed by Ansible")
    ])
    def test_files(host, file, content):
        file = host.file(file)
    
        assert file.exists
        assert file.contains(content)

Now that you’ve specified your test cases, let’s test the role.

## Step 6 — Testing the Role with Molecule

Once you initiate the test, Molecule will execute the actions you defined in your scenario. Let’s now run the default `molecule` scenario again, executing the actions in the default test sequence while looking more closely at each.

Run the test for the default scenario again:

    molecule test

This will initiate the test run. The initial output prints the default test matrix:

    Output--> Validating schema /home/sammy/ansible-apache/molecule/default/molecule.yml.
    Validation completed successfully.
    --> Test matrix
    
    └── default
        ├── lint
        ├── destroy
        ├── dependency
        ├── syntax
        ├── create
        ├── prepare
        ├── converge
        ├── idempotence
        ├── side_effect
        ├── verify
        └── destroy

Let’s go through each test action and the expected output, starting with linting.

The _linting_ action executes `yamllint`, `flake8`, and `ansible-lint`:

- `yamllint`: This linter is executed on all YAML files present in the role directory.
- `flake8`: This Python code linter checks tests created for Testinfra.
- `ansible-lint`: This linter for Ansible playbooks is executed in all scenarios.

    Output...
    --> Scenario: 'default'
    --> Action: 'lint'
    --> Executing Yamllint on files found in /home/sammy/ansible-apache/...
    Lint completed successfully.
    --> Executing Flake8 on files found in /home/sammy/ansible-apache/molecule/default/tests/...
    Lint completed successfully.
    --> Executing Ansible Lint on /home/sammy/ansible-apache/molecule/default/playbook.yml...
    Lint completed successfully.

The next action, _destroy_, is executed using the `destroy.yml` file. This is done to test your role on a newly created container.

By default, destroy is called twice: at the start of the test run, to delete any pre-existing containers, and at the end, to delete the newly created container:

    Output...
    --> Scenario: 'default'
    --> Action: 'destroy'
    
        PLAY [Destroy] *****************************************************************
    
        TASK [Destroy molecule instance(s)] ********************************************
        changed: [localhost] => (item=None)
        changed: [localhost]
    
        TASK [Wait for instance(s) deletion to complete] *******************************
        ok: [localhost] => (item=None)
        ok: [localhost]
    
        TASK [Delete docker network(s)] ************************************************
        skipping: [localhost]
    
        PLAY RECAP *********************************************************************
        localhost : ok=2 changed=1 unreachable=0 failed=0

After the destroy action is complete, the test will move on to _dependency_. This action allows you to pull dependencies from [`ansible-galaxy`](https://galaxy.ansible.com/) if your role requires them. In this case, the role does not:

    Output...
    --> Scenario: 'default'
    --> Action: 'dependency'
    Skipping, missing the requirements file.

The next test action is a _syntax_ check, which is executed on the default `playbook.yml` playbook. It works in a similar way to the `--syntax-check` flag in the command `ansible-playbook --syntax-check playbook.yml`:

    Output...
    --> Scenario: 'default'
    --> Action: 'syntax'
    
        playbook: /home/sammy/ansible-apache/molecule/default/playbook.yml

Next, the test moves on to the _create_ action. This uses the `create.yml` file in your role’s Molecule directory to create a Docker container with your specifications:

    Output...
    
    --> Scenario: 'default'
    --> Action: 'create'
    
        PLAY [Create] ******************************************************************
    
        TASK [Log into a Docker registry] **********************************************
        skipping: [localhost] => (item=None)
        skipping: [localhost]
    
        TASK [Create Dockerfiles from image names] *************************************
        changed: [localhost] => (item=None)
        changed: [localhost]
    
        TASK [Discover local Docker images] ********************************************
        ok: [localhost] => (item=None)
        ok: [localhost]
    
        TASK [Build an Ansible compatible image] ***************************************
        changed: [localhost] => (item=None)
        changed: [localhost]
    
        TASK [Create docker network(s)] ************************************************
        skipping: [localhost]
    
        TASK [Create molecule instance(s)] *********************************************
        changed: [localhost] => (item=None)
        changed: [localhost]
    
        TASK [Wait for instance(s) creation to complete] *******************************
        changed: [localhost] => (item=None)
        changed: [localhost]
    
        PLAY RECAP *********************************************************************
        localhost : ok=5 changed=4 unreachable=0 failed=0

After create, the test moves on to the _prepare_ action. This action executes the prepare playbook, which brings the host to a specific state before running converge. This is useful if your role requires a pre-configuration of the system before the role is executed. Again, this does not apply to our role:

    Output...
    --> Scenario: 'default'
    --> Action: 'prepare'
    Skipping, prepare playbook not configured.

After prepare, the _converge_ action executes your role on the container by running the `playbook.yml` playbook. If multiple platforms are configured in the `molecule.yml` file, Molecule will converge on all of these:

    Output...
    --> Scenario: 'default'
    --> Action: 'converge'
    
        PLAY [Converge] ****************************************************************
    
        TASK [Gathering Facts] *********************************************************
        ok: [centos7]
    
        TASK [ansible-apache : Ensure required packages are present] *******************
        changed: [centos7]
    
        TASK [ansible-apache : Ensure latest index.html is present] ********************
        changed: [centos7]
    
        TASK [ansible-apache : Ensure httpd service is started and enabled] ************
        changed: [centos7] => (item=httpd)
        changed: [centos7] => (item=firewalld)
    
        TASK [ansible-apache : Whitelist http in firewalld] ****************************
        changed: [centos7]
    
        PLAY RECAP *********************************************************************
        centos7 : ok=5 changed=4 unreachable=0 failed=0

After coverge, the test moves on to _idempotence_. This action tests the playbook for idempotence to make sure no unexpected changes are made in multiple runs:

    Output...
    --> Scenario: 'default'
    --> Action: 'idempotence'
    Idempotence completed successfully.

The next test action is the _side-effect_ action. This lets you produce situations in which you’ll be able to test more things, like HA failover. By default, Molecule doesn’t configure a side-effect playbook and the task is skipped:

    Output...
    --> Scenario: 'default'
    --> Action: 'side_effect'
    Skipping, side effect playbook not configured.

Molecule will then run the _verifier_ action using the default verifier, Testinfra. This action executes the tests you wrote earlier in `test_default.py`. If all the tests pass successfully, you will see a success message and Molecule will proceed to the next step:

    Output...
    --> Scenario: 'default'
    --> Action: 'verify'
    --> Executing Testinfra tests found in /home/sammy/ansible-apache/molecule/default/tests/...
        ============================= test session starts ==============================
        platform linux2 -- Python 2.7.12, pytest-3.8.0, py-1.6.0, pluggy-0.7.1
        rootdir: /home/sammy/ansible-apache/molecule/default, inifile:
        plugins: testinfra-1.14.1
    collected 6 items
    
        tests/test_default.py ...... [100%]
    
        ========================== 6 passed in 56.73 seconds ===========================
    Verifier completed successfully.

Finally, Molecule _destroys_ the instances completed during the test and deletes the network assigned to those instances:

    Output...
    --> Scenario: 'default'
    --> Action: 'destroy'
    
        PLAY [Destroy] *****************************************************************
    
        TASK [Destroy molecule instance(s)] ********************************************
        changed: [localhost] => (item=None)
        changed: [localhost]
    
        TASK [Wait for instance(s) deletion to complete] *******************************
        changed: [localhost] => (item=None)
        changed: [localhost]
    
        TASK [Delete docker network(s)] ************************************************
        skipping: [localhost]
    
        PLAY RECAP *********************************************************************
        localhost : ok=2 changed=2 unreachable=0 failed=0

The test actions are now complete, verifying that your role worked as intended.

## Conclusion

In this article you created an Ansible role to install and configure Apache and Firewalld. You then wrote unit tests with Testinfra that Molecule used to assert that the role ran successfully.

You can use the same basic method for highly complex roles, and automate testing using a CI pipeline as well. Molecule is a highly configurable tool that can be used to test roles with any providers that Ansible supports, not just Docker. It’s also possible to automate testing against your own infrastructure, making sure that your roles are always up-to-date and functional. The official [Molecule documentation](https://molecule.readthedocs.io/en/latest/) is the best resource for learning how to use Molecule.
