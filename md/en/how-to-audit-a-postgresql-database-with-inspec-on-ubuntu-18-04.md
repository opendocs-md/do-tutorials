---
author: Elijah Oyekunle
date: 2019-04-02
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-audit-a-postgresql-database-with-inspec-on-ubuntu-18-04
---

# How To Audit a PostgreSQL Database with InSpec on Ubuntu 18.04

_The author selected the [Free and Open Source Fund](https://www.brightfunds.org/funds/foss-nonprofits) to receive a donation as part of the [Write for DOnations](https://do.co/w4do-cta) program._

## Introduction

[InSpec](https://www.inspec.io) is an open-source, automated testing framework for testing and auditing your system to ensure the compliance of integration, security, and other policy requirements. Developers can test the actual state of their infrastructure and applications against a target state using InSpec code.

To specify the policy requirements you’re testing for, InSpec includes _audit controls_. Traditionally, developers manually enforce policy requirements and often do this right before deploying changes to production. With InSpec however, developers can continuously evaluate compliance at every stage of product development, which aids in solving issues earlier in the process of development. The [InSpec DSL (Domain Specific Language)](https://www.inspec.io/docs/reference/dsl_inspec) built on [RSpec](http://rspec.info/), a DSL testing tool written in Ruby, specifies the syntax used to write the audit controls.

InSpec also includes a collection of [_resources_](https://www.inspec.io/docs/reference/resources) to assist in configuring specific parts of your system and to simplify making audit controls. There is a feature to write your own custom resources when you need to define a specific solution that isn’t available. [_Universal matchers_](https://www.inspec.io/docs/reference/matchers) allow you to compare resource values to expectations across all InSpec tests.

In this tutorial, you’ll install InSpec on a server running Ubuntu 18.04. You will start by writing a test that verifies the operating system family of the server, then you’ll create a PostgreSQL audit profile from the ground up. This audit profile starts by checking that you have PostgreSQL installed on the server and that its services are running. Then you’ll add tests to check that the PostgreSQL service is running with the correct port, address, protocol, and user. Next you’ll test specific PostgreSQL configuration parameters, and finally, you’ll audit client authentication configuration.

## Prerequisites

Before following this tutorial, you will need the following:

- One Ubuntu 18.04 server, set up by using the [Initial Server Setup with Ubuntu 18.04](initial-server-setup-with-ubuntu-18-04), including a sudo non-root user and a firewall.
- A working PostgreSQL 10 installation, following this [installation guide](how-to-install-and-use-postgresql-on-ubuntu-18-04).

## Step 1 — Preparing the Environment

In this step, you’ll download and unpack the latest stable version of InSpec into your home directory. InSpec provides installable binaries on their [downloads](https://downloads.chef.io/inspec) page.

Navigate to your home directory:

    cd ~

Now download the binary with `curl`:

    curl -LO https://packages.chef.io/files/stable/inspec/3.7.11/ubuntu/18.04/inspec_3.7.11-1<^>_amd64.deb

Next, use the `sha256sum` command to generate a checksum of the downloaded file. This is to verify the integrity and authenticity of the downloaded file.

    sha256sum inspec_3.7.11-1_amd64.deb

Checksums for each binary are listed on the [InSpec downloads page](https://downloads.chef.io/inspec), so visit the downloads page to compare with your output from this command.

    Outpute665948f9c0441e8648b08f8d3c8d34a86f9e994609877a7e4853c012dbc7523 inspec_3.7.11-1_amd64.deb

If the checksums are different, delete the downloaded file and repeat the download process.

Next, you’ll install the downloaded binary. For this, you’ll use the `dpkg` command that you can use for package management, and which comes with all Debian-based systems, such as Ubuntu, by default. The `-i` flag prompts the dpkg command to install the package files.

    sudo dpkg -i inspec_3.7.11-1_amd64.deb

If there are no errors, it means that you’ve installed InSpec successfully. To verify the installation, enter the following command:

    inspec version

You’ll receive output showing the version of InSpec you just installed:

    Output3.7.11

If you don’t see a version number displayed, run over step 1 again.

After this, you can delete `inspec_3.7.11-1_amd64.deb` since you don’t need it anymore as you’ve installed the package:

    rm inspec_3.7.11-1_amd64.deb

You’ve successfully installed InSpec on your server. In the next step, you will write a test to verify the operating system family of your server.

## Step 2 — Completing Your First InSpec Test

In this step, you’ll complete your first InSpec test, which will be testing that your operating system family is `debian`.

You will use the [`os`](https://www.inspec.io/docs/reference/resources/os/) resource, which is a built-in InSpec audit resource to test the platform on which the system is running. You’ll also use the `eq` matcher. The `eq` matcher is a universal matcher that tests for the exact equality of two values.

An InSpec test consists of a `describe` block, which contains one or more `it` and `its` statements each of which validates one of the resource’s features. Each statement describes an expectation of a specific condition of the system as _assertions_. Two keywords that you can include to make an assertion are `should` and `should_not`, which assert that the condition should be true and false respectively.

Create a file called `os_family.rb` to hold your test and open it with your text editor:

    nano os_family.rb

Add the following to your file:

os\_family.rb

    describe os.family do
      it {should eq 'debian'}
    end

This test ensures that the operating system family of the target system is `debian`. Other possible values are `windows`, `unix`, `bsd`, and so on. You can find a complete list in the [`os` resource documentation](https://www.inspec.io/docs/reference/resources/os/). Save and exit the file.

Next, run your test with the following command:

    inspec exec os_family.rb

The test will pass, and you’ll receive output resembling the following:

    OutputProfile: tests from os_family.rb (tests from os_family.rb)
    Version: (not specified)
    Target: local://
    
      debian
         ✔ should eq "debian"
    
    Test Summary: 1 successful, 0 failures, 0 skipped

In your output, the `Profile` contains the name of the profile that just executed. Since this test is not included in a profile, InSpec generates a default profile name from the test’s file name `tests from os_family.rb`. (You’ll work with InSpec _profiles_ in the next section where you will start building your PostgreSQL InSpec profile.) Here InSpec presents the `Version` as `not specified`, because you can only specify versions in profiles.

The `Target` field specifies the target system that the test is executed on, which can be local or a remote system via `ssh`. In this case, you’ve executed your test on the local system so the target shows `local://`.

Usefully, the output also displays the executed test with a checkmark symbol (✔) to the left indicating a successful test. The output will show a cross symbol (✘) if the test fails.

Finally, the test summary gives overall details about how many tests were successful, failed, and skipped. In this instance, you had a single successful test.

Now you’ll see what the output looks like for a failed test. Open `os_family.rb`:

    nano os_family.rb

In the test you created earlier in this step, you’ll now change the expected value of the operating system family from `debian` to `windows`. Your file contents after this will be the following:

os\_family.rb

    describe os.family do
      it {should eq 'windows'}
    end

Save and exit the file.

Next, run the updated test with the following command:

    inspec exec os_family.rb

You will get output similar to the following:

    OutputProfile: tests from os_family.fail.rb (tests from os_family.fail.rb)
    Version: (not specified)
    Target: local://
    
      debian
         (✘) should eq "windows"
    
         expected: "windows"
              got: "debian"
    
         (compared using ==)
    
    
    Test Summary: 0 successful, 1 failure, 0 skipped

As expected, the test failed. The output indicates that your expected (`windows`) and actual (`debian`) values do not match for the `os.family` property. The `(compared using ==)` output indicates that the `eq` matcher performed a string comparison between the two values to come up with this result.

In this step, you’ve written a successful test that verifies the operating system family of the server. You’ve also created a failed test in order to see what the InSpec output for a failed test looks like. In the next step, you will start building the audit profile to test your PostgreSQL installation.

## Step 3 — Auditing Your PostgreSQL Installation

Now, you will audit your PostgreSQL installation. You’ll start by checking that you have PostgreSQL installed and its service is running correctly. Finally, you’ll audit the PostgreSQL system port and process. For your PostgreSQL audit, you will create various InSpec controls, all within an InSpec `profile` named `PostgreSQL`.

An InSpec _control_ is a high-level grouping of related tests. Within a control, you can have multiple `describe` blocks, as well as metadata to describe your tests such as impact level, title, description, and tags. InSpec profiles organize controls to support dependency management and code reuse, which both help manage test complexity. They are also useful for packaging and sharing tests with the public via the [Chef Supermarket](https://supermarket.chef.io/). You can use profiles to define custom resources that you would implement as regular Ruby classes.

To create an InSpec profile, you will use the `init` command. Enter this command to create the `PostgreSQL` profile:

    inspec init profile PostgreSQL

This creates the profile in a new directory with the same name as your profile, in this case `PostgreSQL`. Now, move into the new directory:

    cd PostgreSQL/

The directory structure will look like this:

    PostgreSQL/
    ├── controls
    │ └── example.rb
    ├── inspec.yml
    ├── libraries
    └── README.md

The `controls/example.rb` file contains a sample control that tests to see if the `/tmp` folder exists on the target system. This is present only as a sample and you will replace it with your own test.

Your first test will be to ensure that you have the package `postgresql-10` installed on your system and that you have the `postgresql` service installed, enabled, and running.

Rename the `controls/example.rb` file to `controls/postgresql.rb`:

    mv controls/example.rb controls/postgresql.rb

Next, open the file with your text editor:

    nano controls/postgresql.rb

Replace the content of the file with the following:

controls/postgresql.rb

    control '1-audit_installation' do
      impact 1.0
      title 'Audit PostgreSQL Installation'
      desc 'Postgres should be installed and running'
    
      describe package('postgresql-10') do
        it {should be_installed}
        its('version') {should cmp >= '10'}
      end
    
      describe service('postgresql@10-main') do
        it {should be_enabled}
        it {should be_installed}
        it {should be_running}
      end
    end

In the preceding code block, you begin by defining the control with its name and metadata.

In the first `describe` block, you use the `package` resource and pass in the PostgreSQL package name `postgresql-10` as a resource argument. The `package` resource provides the matcher `be_installed` to test that the named package is installed on the system. It returns **true** if you have the package installed, and **false** otherwise. Next, you used the `its` statement to validate that the version of the installed PostgreSQL package is at least 10. You are using `cmp` instead of `eq` because package version strings usually contain other attributes apart from the numerical version. `eq` returns **true** only if there is an exact match while `cmp` is less-restrictive.

In the second `describe` block, you use the `service` resource and pass in the PostgreSQL 10 service name `postgresql@10-main` as a resource argument. The `service` resource provides the matchers `be_enabled`, `be_installed`, and `be_running` and they return **true** if you have the named service installed, enabled, and running on the target system respectively.

Save and exit your file.

Next, you will run your profile. Make sure you’re in the `~/PostgreSQL` directory before running the following command:

    inspec exec .

Since you completed the PostgreSQL prerequisite tutorial, your test will pass. Your output will look similar to the following:

    OutputProfile: InSpec Profile (PostgreSQL)
    Version: 0.1.0
    Target: local://
    
      ✔ 1-audit_installation: Audit PostgreSQL Installation
         ✔ System Package postgresql-10 should be installed
         ✔ System Package postgresql-10 version should cmp >= "10"
         ✔ Service postgresql@10-main should be enabled
         ✔ Service postgresql@10-main should be installed
         ✔ Service postgresql@10-main should be running
    
    
    Profile Summary: 1 successful control, 0 control failures, 0 controls skipped
    Test Summary: 5 successful, 0 failures, 0 skipped

The output indicates that your control was successful. A control is successful if, and only if, all the tests in it are successful. The output also confirms that all your tests were successful.

Now that you’ve verified that the correct version of PostgreSQL is installed and the service is fine, you will create a new control that ensures that PostgreSQL is listening on the correct port, address, and protocol.

For this test, you will also use _attributes_. An InSpec attribute is used to parameterize a profile to enable easy re-use in different environments or target systems. You’ll define the `PORT` attribute.

Open the `inspec.yml` file in your text editor:

    nano inspec.yml

You’ll append the `port` attribute to the end of the file. Add the following at the end of your file:

inspec.yml

    ...
    attributes:
      - name: port
        type: string
        default: '5432'

In the preceding code block, you added the `port` attribute and set it to a default value of `5432` because that is the port PostgreSQL listens on by default.

Save and exit the file. Then run `inspec check` to verify the profile is still valid since you just edited `inspec.yml`:

    inspec check .

If there are no errors, you can proceed. Otherwise, open the `inspec.yml` file and ensure that the attribute is present at the end of the file.

Now you’ll create the control that checks that the PostgreSQL process is running and configured with the correct user. Open `controls/postgresql.rb` in your text editor:

    nano controls/postgresql.rb

Append the following control to the end of your current tests file `controls/postgresql.rb`:

controls/postgresql.rb

    ...
    PORT = attribute('port')
    
    control '2-audit_address_port' do
      impact 1.0
      title 'Audit Process and Port'
      desc 'Postgres port should be listening and the process should be running'
    
      describe port(PORT) do
        it {should be_listening}
        its('addresses') {should include '127.0.0.1'}
        its('protocols') {should cmp 'tcp'}
      end
    
      describe processes('postgres') do
        it {should exist}
        its('users') {should include 'postgres'}
      end
    
      describe user('postgres') do
        it {should exist}
      end
    end

Here you begin by declaring a `PORT` variable to hold the value of the `port` profile attribute. Then you declare the control and its metadata.

In the first `describe` block, you include the [`port`](https://www.inspec.io/docs/reference/resources/port/) resource to test basic port properties. The `port` resource provides the matchers `be_listening`, `addresses`, and `protocols`. You use the `be_listening` matcher to test that the named port is listening on the target system. It returns **true** if the port `5432` is listening and returns **false** otherwise. The `addresses` matcher tests if the specified address is associated with the port. In this case, PostgreSQL will be listening on the local address, `127.0.0.1`.  
The `protocols` matcher tests the Internet protocol the port is listening for, which can be `icmp`, `tcp`/`tcp6`, or `udp`/`udp6`. PostgreSQL will be listening for `tcp` connections.

In the second `describe` block, you include the [`processes`](https://www.inspec.io/docs/reference/resources/processes/) resource. You use the `processes` resource to test properties for programs that are running on the system. First, you verify that the `postgres` process exists on the system, then you use the `users` matcher to test that the `postgres` user owns the `postgres` process.

In the third `describe` block, you have the [`user`](https://www.inspec.io/docs/reference/resources/user/) resource. You include the `user` resource to test user properties for a user such as whether the user exists or not, the group the user belongs to, and so on. Using this resource, you test that the `postgres` user exists on the system. Save and exit `controls/postgresql.rb`.

Next, run your profile with the following command:

    inspec exec .

The tests will pass, and your output will resemble the following:

    OutputProfile: InSpec Profile (PostgreSQL)
    Version: 0.1.0
    Target: local://
    
      ✔ 1-audit_installation: Audit PostgreSQL Installation
         ✔ System Package postgresql-10 should be installed
         ✔ System Package postgresql-10 version should cmp >= "10"
         ✔ Service postgresql@10-main should be enabled
         ✔ Service postgresql@10-main should be installed
         ✔ Service postgresql@10-main should be running
      ✔ 2-audit_address_port: Audit Process and Port
         ✔ Port 5432 should be listening
         ✔ Port 5432 addresses should include "127.0.0.1"
         ✔ Port 5432 protocols should cmp == "tcp"
         ✔ Processes postgres should exist
         ✔ Processes postgres users should include "postgres"
         ✔ User postgres should exist
    
    
    Profile Summary: 2 successful controls, 0 control failures, 0 controls skipped
    Test Summary: 11 successful, 0 failures, 0 skipped

The output indicates that both of your controls and all of your tests were successful.

In this section, you have created your first InSpec profile and control and used them to organize your tests. You’ve used several InSpec resources to ensure that you have the correct version of PostgreSQL installed, the PostgreSQL service enabled and running correctly, and that the PostgreSQL user exists on the system. With this set up you’re ready to audit your configuration.

## Step 4 — Auditing Your PostgreSQL Configuration

In this step, you’ll audit some PostgreSQL configuration values, which will give you a foundation for working with these configuration files, allowing you to audit any PostgreSQL configuration parameters as desired.

Now that you have tests auditing the PostgreSQL installation, you’ll audit your PostgreSQL configuration itself. PostgreSQL has several configuration parameters that you can use to tune it as desired, and these are stored in the configuration file located by default at `/etc/postgresql/10/main/postgresql.conf`. You could have different requirements regarding PostgreSQL configuration for your various deployments such as logging, password encryption, SSL, and replication strategies — these requirements you specify in the configuration file.

You will be using the [`postgres_conf`](https://www.inspec.io/docs/reference/resources/postgres_conf/) resource that tests for specific, named configuration options against expected values in the contents of the PostgreSQL configuration file.

This test will assume some non-default PostgreSQL configuration values that you’ll set manually.

Open the PostgreSQL configuration file in your favorite text editor:

    sudo nano /etc/postgresql/10/main/postgresql.conf

Set the following configuration values. If the option already exists in the file but is commented out, uncomment it by removing the `#`, and set the value as provided:

/etc/postgresql/10/main/postgresql.conf

    password_encryption = scram-sha-256
    logging_collector = on
    log_connections = on
    log_disconnections = on
    log_duration = on

The configuration values you have set:

- Ensure that saved passwords are always encrypted with the scram-sha-256 algorithm.
- Enable the `logging collector`, which is a background process that captures log messages from the standard error (`stderr`) and redirects them to a log file.
- Enable logging of connection attempts to the PostgreSQL server as well as successful connections.
- Enable logging of session terminations.
- Enable logging of the duration of every completed statement.

Save and exit the configuration file. Then restart the PostgreSQL service:

    sudo service postgresql@10-main restart

You’ll test for only a few configuration options, but you can test any PostgreSQL configuration option with the `postgres_conf` resource.

You will pass in your PostgreSQL configuration directory, which is at `/etc/postgresql/10/main`, using a new profile attribute, `postgres_conf_dir`. This configuration directory is not the same across all operating systems and platforms, so by passing it in as a profile attribute, you’ll be making this profile easier to reuse in different environments.

Open your `inspec.yml` file:

    nano inspec.yml

Add this new attribute to the `attributes` section of `inspec.yml`:

inspec.yml

    ...
      - name: postgres_conf_dir
        type: string
        default: '/etc/postgresql/10/main'

Save and exit your file. Then run the following command to verify the InSpec profile is still valid because you just edited the `inspec.yml`:

    inspec check .

If there are no errors, you can proceed. Otherwise, open the `inspec.yml` file and ensure that the above lines are present at the end of the file.

Now you will create the control that audits the configuration values you are enforcing. Append the following control to the end of the tests file `controls/postgresql.rb`:

controls/postgresql.rb

    ...
    POSTGRES_CONF_DIR = attribute('postgres_conf_dir')
    POSTGRES_CONF_PATH = File.join(POSTGRES_CONF_DIR, 'postgresql.conf')
    
    control '3-postgresql' do
      impact 1.0
      title 'Audit PostgreSQL Configuration'
      desc 'Audits specific configuration options'
    
      describe postgres_conf(POSTGRES_CONF_PATH) do
        its('port') {should eq PORT}
        its('password_encryption') {should eq 'scram-sha-256'}
        its('ssl') {should eq 'on'}
        its('logging_collector') {should eq 'on'}
        its('log_connections') {should eq 'on'}
        its('log_disconnections') {should eq 'on'}
        its('log_duration') {should eq 'on'}
      end
    end

Here you define two variables:

- `POSTGRES_CONF_DIR` holds the `postgres_conf_dir` attribute as defined in the profile configuration.
- `POSTGRES_CONF_PATH` holds the absolute path of the configuration file by concatenating the configuration file name with the configuration directory using [`File.join`](https://ruby-doc.org/core-2.6.2/File.html#method-c-join).

Next, you define the control with its name and metadata. Then you use the `postgres_conf` resource together with the `eq` matcher to ensure your required values for the configuration options are correct. Save and exit `controls/postgresql.rb`.

Next, you will run the test with the following command:

    inspec exec .

The tests will pass, and your outputs will resemble the following:

    OutputProfile: InSpec Profile (PostgreSQL)
    Version: 0.1.0
    Target: local://
    
      ✔ 1-audit_installation: Audit PostgreSQL Installation
         ✔ System Package postgresql-10 should be installed
         ✔ System Package postgresql-10 version should cmp >= "10"
         ✔ Service postgresql@10-main should be enabled
         ✔ Service postgresql@10-main should be installed
         ✔ Service postgresql@10-main should be running
      ✔ 2-audit_address_port: Audit Process and Port
         ✔ Port 5432 should be listening
         ✔ Port 5432 addresses should include "127.0.0.1"
         ✔ Port 5432 protocols should cmp == "tcp"
         ✔ Processes postgres should exist
         ✔ Processes postgres users should include "postgres"
         ✔ User postgres should exist
      ✔ 3-postgresql: Audit PostgreSQL Configuration
         ✔ PostgreSQL Configuration port should eq "5432"
         ✔ PostgreSQL Configuration password_encryption should eq "scram-sha-256"
         ✔ PostgreSQL Configuration ssl should eq "on"
         ✔ PostgreSQL Configuration logging_collector should eq "on"
         ✔ PostgreSQL Configuration log_connections should eq "on"
         ✔ PostgreSQL Configuration log_disconnections should eq "on"
         ✔ PostgreSQL Configuration log_duration should eq "on"
    
    
    Profile Summary: 3 successful controls, 0 control failures, 0 controls skipped
    Test Summary: 18 successful, 0 failures, 0 skipped

The output indicates that your three controls and all your tests were successful without any skipped tests or controls.

In this step, you’ve added a new InSpec control that tests specific PostgreSQL configuration values from the configuration file using the [`postgres_conf`](https://www.inspec.io/docs/reference/resources/postgres_conf/) resource. You audited a few values in this section, but you can use it to test any configuration option from the configuration file.

## Step 5 — Auditing PostgreSQL Client Authentication

Now that you’ve written some tests for your PostgreSQL configuration, you’ll write some tests for client authentication. This is important for installations that need to ensure specific authentication methods for different kinds of users; for example, to ensure clients connecting to PostgreSQL locally always need to authenticate with a password, or to reject connections from a specific IP address or IP address range, and so on.

An important configuration for PostgreSQL installations where security is a concern is to only allow encrypted password authentications. PostgreSQL 10 [supports two password encryption methods](https://www.postgresql.org/docs/10/auth-methods.html#AUTH-PASSWORD) for client authentication: [`md5`](https://en.wikipedia.org/wiki/MD5) and [`scram-sha-256`](https://en.wikipedia.org/wiki/Salted_Challenge_Response_Authentication_Mechanism). This test will require password encryption for all clients so this means that the `METHOD` field for all clients in the client configuration file must be set to either `md5` or `scram-sha-256`. For these tests, you will use `scram-sha-256` since it is more secure than `md5`.

By default, `local` clients have their `peer` authentication method in the `pg_hba.conf` file. For the test, you need to change these to `scram-sha-256`. Open the `/etc/postgresql/10/main/pg_hba.conf` file:

    sudo nano /etc/postgresql/10/main/pg_hba.conf

The top of the file contains comments. Scroll down and look for uncommented lines where the authentication type is `local`, and change the authentication method from `peer` to `scram-sha-256`. For example, change:

/etc/postgresql/10/main/pg\_hba.conf

    ...
    local all postgres peer
    ...

to:

/etc/postgresql/10/main/pg\_hba.conf

    ...
    local all postgres scram-sha-256
    ...

At the end, your `pg_hba.conf` configuration will resemble the following:

/etc/postgresql/10/main/pg\_hba.conf

    ...
    local all postgres scram-sha-256
    
    # TYPE DATABASE USER ADDRESS METHOD
    
    # "local" is for Unix domain socket connections only
    local all all scram-sha-256
    # IPv4 local connections:
    host all all 127.0.0.1/32 scram-sha-256
    # IPv6 local connections:
    host all all ::1/128 scram-sha-256
    # Allow replication connections from localhost, by a user with the
    # replication privilege.
    local replication all scram-sha-256
    host replication all 127.0.0.1/32 scram-sha-256
    host replication all ::1/128 scram-sha-256
    ...

Save and exit the configuration file. Then restart the PostgreSQL service:

    sudo service postgresql@10-main restart

For this test, you’ll use the [`postgres_hba_conf`](https://www.inspec.io/docs/reference/resources/postgres_hba_conf/) resource. This resource is used to test the client authentication data defined in the `pg_hba.conf` file. You’ll pass in the path of your `pg_hba.conf` file as a parameter to this resource.

Your control will consist of two `describe` blocks that check the `auth_method` fields for both `local` and `host` clients respectively to ensure that they are both equal to `scram-sha-256`. Open `controls/postgresql.rb` in your text editor:

    nano controls/postgresql.rb

Append the following control to the end of the test file `controls/postgresql.rb`:

controls/postgresql.rb

    POSTGRES_HBA_CONF_FILE = File.join(POSTGRES_CONF_DIR, 'pg_hba.conf')
    
    control '4-postgres_hba' do
      impact 1.0
      title 'Require SCRAM-SHA-256 for ALL users, peers in pg_hba.conf'
      desc 'Require SCRAM-SHA-256 for ALL users, peers in pg_hba.conf. Do not allow untrusted authentication methods.'
    
      describe postgres_hba_conf(POSTGRES_HBA_CONF_FILE).where { type == 'local' } do
        its('auth_method') { should all eq 'scram-sha-256' }
      end
    
      describe postgres_hba_conf(POSTGRES_HBA_CONF_FILE).where { type == 'host' } do
        its('auth_method') { should all eq 'scram-sha-256' }
      end
    end

In this code block, you define a new variable `POSTGRES_HBA_CONF_FILE` to store the absolute location of your `pg_hba.conf` file. [`File.join`](https://ruby-doc.org/core-2.6.2/File.html#method-c-join) is a Ruby method to concatenate two file path segments with `/`. You use it here to join the `POSTGRES_CONF_DIR` variable, declared in the previous section, with the PostgreSQL configuration file `pg_hba.conf`. This will produce an absolute file path of the `pg_hba.conf` file and store it in the `POSTGRES_HBA_CONF_FILE` variable.

After that, you declare and configure the control and its metadata. The first `describe` block checks that all configuration entries where the client type is `local` also have `scram-sha-256` as their authentication methods. The second `describe` block does the same for cases where the client type is `host`. Save and exit `controls/postgresql.rb`.

You’ll execute this control as the `postgres` user because `Read` access to the PostgreSQL HBA configuration is granted only to Owner and Group, which is the `postgres` user. Execute the profile by running:

    sudo -u postgres inspec exec .

Your output will resemble the following:

    OutputProfile: InSpec Profile (PostgreSQL)
    Version: 0.1.0
    Target: local://
    
      ✔ 1-audit_installation: Audit PostgreSQL Installation
         ✔ System Package postgresql-10 should be installed
         ✔ System Package postgresql-10 version should cmp >= "10"
         ✔ Service postgresql@10-main should be enabled
         ✔ Service postgresql@10-main should be installed
         ✔ Service postgresql@10-main should be running
      ✔ 2-audit_address_port: Audit Process and Port
         ✔ Port 5432 should be listening
         ✔ Port 5432 addresses should include "127.0.0.1"
         ✔ Port 5432 protocols should cmp == "tcp"
         ✔ Processes postgres should exist
         ✔ Processes postgres users should include "postgres"
         ✔ User postgres should exist
      ✔ 3-postgresql: Audit PostgreSQL Configuration
         ✔ PostgreSQL Configuration port should eq "5432"
         ✔ PostgreSQL Configuration password_encryption should eq "scram-sha-256"
         ✔ PostgreSQL Configuration ssl should eq "on"
         ✔ PostgreSQL Configuration logging_collector should eq "on"
         ✔ PostgreSQL Configuration log_connections should eq "on"
         ✔ PostgreSQL Configuration log_disconnections should eq "on"
         ✔ PostgreSQL Configuration log_duration should eq "on"
      ✔ 4-postgres_hba: Require SCRAM-SHA-256 for ALL users, peers in pg_hba.conf
         ✔ Postgres Hba Config /etc/postgresql/10/main/pg_hba.conf with type == "local" auth_method should all eq "scram-sha-256"
         ✔ Postgres Hba Config /etc/postgresql/10/main/pg_hba.conf with type == "host" auth_method should all eq "scram-sha-256"
    
    
    Profile Summary: 4 successful controls, 0 control failures, 0 controls skipped
    Test Summary: 20 successful, 0 failures, 0 skipped

This output indicates that the new control you added, together with all of the previous controls, are successful. It also indicates that all the tests in your profile are successful.

In this step, you have added a control to your profile that successfully audited your PostgreSQL client authentication configuration to ensure that all clients are authenticated via `scram-sha-256` using the [`postgres_hba_conf`](https://www.inspec.io/docs/reference/resources/postgres_hba_conf/) resource.

## Conclusion

You’ve set up InSpec and successfully audited a PostgreSQL 10 installation. In the process, you’ve used a selection of InSpec tools, such as: the InSpec DSL, matchers, resources, profiles, attributes, and the CLI. From here, you can incorporate other resources that InSpec provides in the [Resources section](https://www.inspec.io/docs/reference/resources) of their documentation. InSpec also provides a mechanism for defining [custom resources](https://www.inspec.io/docs/reference/dsl_resource) for your specific needs. These custom resources are written as a regular Ruby class.

You can also explore the [`Compliance Profiles`](https://supermarket.chef.io/tools?type=compliance_profile) section of the [Chef supermarket](https://supermarket.chef.io/) that contains publicly shared InSpec profiles that you can execute directly or extend in your own profiles. You can also share your own profiles with the general public in the Chef Supermarket.

You can go further by exploring other tools in the Chef universe such as [`Chef`](https://www.chef.io/) and [`Habitat`](https://www.habitat.sh/). [InSpec is integrated with Habitat](https://www.inspec.io/docs/reference/habitat/) and this provides the ability to ship your compliance controls together with your Habitat-packaged applications and continuously run them. You can explore official and community InSpec tutorials on the [tutorials](https://www.inspec.io/tutorials/) page. For more advanced InSpec references, check the official [InSpec documentation](https://www.inspec.io/docs).
