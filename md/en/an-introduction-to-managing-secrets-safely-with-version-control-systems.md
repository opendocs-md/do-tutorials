---
author: Justin Ellingwood
date: 2017-08-31
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-managing-secrets-safely-with-version-control-systems
---

# An Introduction to Managing Secrets Safely with Version Control Systems

## Introduction

Version control software (VCS) is an essential part of most modern software development practices. Among other benefits, software like Git, Mercurial, Bazaar, Perforce, CVS, and Subversion allow developers to save snapshots of their project history to enable better collaboration, revert to previous states and recover from unintended code changes, and manage multiple versions of the same codebase. These tools allow multiple developers to safely work on the same project and provide significant benefits even if you do not plan to share your work with others.

Although it is important to save your _code_ in source control, it it is equally important for some project assets to be kept _out_ of your repository. Certain data like binary blobs and configuration files are best left out of source control for performance and usability reasons. But more importantly, sensitive data like passwords, secrets, and private keys should never be checked into a repository unprotected for security reasons.

In this guide, we will first talk about how to check for sensitive data already committed to your repository and introduce some mitigation strategies if any material is found. Afterwards, we will cover some tools and techniques for preventing the addition of secrets to repositories, ways to encrypt sensitive data before committing, and alternatives for secure secret storage.

## Checking your Git Repository for Sensitive Data

Before setting up a system to manage your sensitive data, it’s a good idea to check whether any secret material is already present in your project files.

### Scanning Your Projects

If you know an exact string that you want to search for, you can try using your VCS tool’s native search functionality to check whether the provided value is present in any commits. For example, with `git`, a command like this can search for a specific password:

    git grep my_secret $(git rev-list --all)

This will search your entire project history for the specified string.

A number of dedicated tools can help surface secrets more broadly. Tools like [gitrob](https://github.com/michenriksen/gitrob) can scan each repository in a GitHub organization for filenames matching those in a predefined list. The [git-secrets](https://github.com/awslabs/git-secrets) project can scan repositories locally for defined secrets, based on patterns in both the file paths and content. The [truffleHog](https://github.com/dxa4481/truffleHog) tool uses a different approach by searching repositories for high entropy strings which likely represent generated secrets used by applications. To combine some of this functionality into a single tool, [git-all-secrets](https://github.com/anshumanbh/git-all-secrets) glues together or reimplements the above tools in a unified interface.

### Mitigation Options

If you discover files or data that should not have been committed, it’s important to respond appropriately to mitigate the impact of the leaked data. The right course of action will depend on how widely the repository is shared, the nature of the exposed material, and whether you wish to scrub all mention of the leaked content or just invalidate it.

If credentials are committed to your project repository, your first step should be to immediately change the password or secret to invalidate the previous value. This step should be completed regardless of if or how widely the repository is shared for a few reasons. Collaboration requirements can change over the life of a project leading to greater exposure than previously anticipated. Even if you know you will never intentionally share your project, security incidents can leak data to unintended parties, so it’s best to be proactive in changing the current values.

While you should rotate your compromised credentials in all cases, you may wish to remove the leaked credentials or file from your VCS history entirely as well. This is especially important for sensitive data that cannot be changed, like any user data that was unintentionally committed. Removing the data from your repositories involves rewriting the VCS history to remove the file from previous commits. This can be done [using native `git` commands or with the help of some dedicated tools](https://help.github.com/articles/removing-sensitive-data-from-a-repository/). It is important to note that even if you remove all record of the data in the repository, anyone who had previously copied the codebase may still have access to the sensitive material. Keep this in mind when assessing the extent of the impact.

If you suspect that secrets were compromised, it is a good idea to review the log data associated with those programs or services to try to determine if there has been unusual access or behavior. This may take the form of unusual activity or requests that usually originate within your internal network coming from addresses you do not control. This investigation will help you determine appropriate next steps for protecting your infrastructure and data.

## Using VCS Features to Avoid Committing Secrets

Before looking at external tools, it is a good idea to familiarize yourself with some of the features and abilities native to your VCS tools to help prevent committing unwanted data to your repository.

### Ignoring Sensitive Files

The most basic way to keep files with sensitive data out of your repository is to leverage your VCS’s ignore functionality from the very beginning. VCS “ignore” files (like `.gitignore`) define patterns, directories, or files that should be excluded from the repository. These are a good first line of defense against accidentally exposing data. This strategy is useful because it does not rely on external tooling, the list of excluded items is automatically configured for collaborators, and it is easy to set up.

While VCS ignore functionality is useful as a baseline, it relies on keeping the ignore definitions up-to-date. It is easy to commit sensitive data accidentally prior to updating or implementing the ignore file. Ignore patterns only have file-level granularity, so you may have to refactor some parts of your project if secrets are mixed in with code or other data that should be committed.

### Using VCS Hooks to Check Files Prior to Committing

Most modern VCS implementations include a system called “hooks” for executing scripts before or after certain actions are taken within the repository. This functionality can be used to execute a script to check the contents of pending changes for sensitive material. The previously mentioned [git-secrets](https://github.com/awslabs/git-secrets) tool has the ability to install `pre-commit` hooks that implement automatic checking for the type of content it evaluates. You can add your own [custom scripts](how-to-use-git-hooks-to-automate-development-and-deployment-tasks) to check for whatever patterns you’d like to guard against.

Repository hooks provide a much more flexible mechanism for searching for and guarding against the addition of sensitive data at the time of commit. This increased flexibility comes at the cost of having to script all of the behavior you’d like to implement, which can potentially be a difficult process depending on the type of data you want to check. An additional consideration is that hooks are not shared as easily as ignore files, as they are not part of the repository that other developers copy. Each contributor will need to set up the hooks on their own machine, which makes enforcement a more difficult problem.

### Adding Files to the Staging Area Explicitly

While more localized in scope, one simple strategy that may help you to be more mindful of your commits is to only add items to the VCS staging area explicitly by name. While adding files by wildcard or expansion can save some time, being intentional about each file you want to add can help prevent accidental additions that might otherwise be included. A beneficial side effect of this is that it generally allows you to create more focused and consistent commits, which helps with many other aspects of collaborative work.

## Storing Encrypted Secrets in the Repository

While in many circumstances it is recommended to remove sensitive data entirely from your code repository, sometimes it is necessary or useful to include some sensitive data within a repository for other privileged users to access. To do so, various tools allow you to encrypt sensitive files within a repository while leaving the majority of files accessible to everyone.

### Implementations

There are a number of different pieces of software that simplify partial repository encryption. Most work from the same basic principles, but each offers a unique implementation that may offer some compelling advantages depending on your project needs.

A project called [git-secret](https://github.com/sobolevn/git-secret) (not to be confused with the `git-secrets` tool mentioned earlier) can encrypt the contents of secret files with the GPG keys of trusted collaborators. By leveraging an existing web of trust, `git-secret` users can manage access to files by specifying the users that should be able to decrypt each item. If the user has published their public key to a key server, you can provide them access to encrypted contents without ever asking them for their key directly.

The [git-crypt](https://github.com/AGWA/git-crypt) tool works similarly to `git-secret` in that it allows you to encrypt and commit portions of your repository and regulate access to other contributors using their GPG keys. The `git-crypt` project can alternatively use symmetric key encryption if your team doesn’t use GPG or if that management pattern is too complex for your use case. Additionally, `git-crypt` will automatically encrypt at the time of commit and decrypt on clone using the `git` filter and diff attributes, which simplifies management.

The [BlackBox project](https://github.com/StackExchange/blackbox) is yet another solution that relies on GPG to collaboratively encrypt content. Unlike the previous tools, BlackBox works with many different version control systems so that it can be used across different projects. Originally designed as a tool for the Puppet ecosystem, it was refactored to support a more open plugin-based system. BlackBox can encrypt and decrypt individual files at will, but also provides a mechanism to call a text editor transparently, which decrypts the file, opens an editor, and then re-encrypts upon saving.

Outside of the general solutions above, there are also some solutions built to work with specific types of repositories. For example, starting with version 5.1, Ruby on Rails projects can include [encrypted secrets within the repository](http://edgeguides.rubyonrails.org/5_1_release_notes.html#encrypted-secrets) using a system that sets up a master key outside of the repository.

### Advantages

Encrypting and committing your secret data to your repository can help keep your credentials up-to-date and in sync with the way the code uses them. This can avoid drift between changes in the confidential data format or labelling and the way that the code uses or accesses it. Changes can be made to the codebase without referencing an external resource.

Additionally, keeping your secrets with your code can simplify deployment considerably. Rather than pulling down information from multiple locations to get a fully functional system, the information is all packaged in a single unit, with some components requiring decryption. This can be very helpful if you do not have the infrastructure set up to support an external secret store or if you want to minimize the amount of coordination necessary to deploy your project.

The overall advantage of using a tool to encrypt sensitive information within a repository is that encryption is easy to implement without additional infrastructure or planning. Users can transition from storing secrets as plain text data to a secure, encrypted system in a few minutes. For projects with a single developer or a small, static team, these tools likely fill all secret management requirements without adding extensive complexity.

### Disadvantages

As with any solution, there are some trade-offs to this style of secret management.

Fundamentally, secrets are configuration data, not code. While the code deployed in various environments is likely the same, the configuration can vary quite a lot. By keeping secrets with the code in your repository, it becomes more difficult to maintain configuration across different environments and encourages credential reuse in ways that negatively impact security.

Similarly, configuring granular, multi-level access to encrypted secrets within a repository is often difficult. The required level of access control is often much more complex than what is easily modeled by the tools used to encrypt secrets in VCS, especially for large teams and projects. Bringing on collaborators or removing contributors from the project involves re-encrypting all of the files with sensitive data within the repository. While these utilities usually make it easy to change the encryption used to protect the files, the secrets within those files should _also_ be rotated in these circumstances, which can be a difficult, manual process.

An important point that is often overlooked is that the keys used to decrypt the data are often stored alongside the encrypted content. On a developer’s laptop, the GPG keys that can decrypt sensitive data are often present and usable without any further input. You can mitigate this somewhat by using a GPG passphrase, but this is difficult to enforce for a large team. If a team member’s laptop is compromised, access to the most sensitive data in your project may be accessible as if it were in plain text.

In general, protecting secrets within a repository over a long period of time can be difficult. Simple operations like rolling back code changes can accidentally reintroduce access that was previously removed. If a private key is exposed, historical values may be recovered and decrypted from the repository history. Although the VCS history provides a log of encryption changes, there is no method of auditing secret access to help determine unusual access.

## Using Configuration Management Systems for Secret Management

Many users’ first experience with more centralized secret management is with configuration management tools. Because these tools are responsible for coordinating the configuration of many different machines from a centralized location, some level of secret management is necessary to ensure that nodes can only access the values they require.

### Implementations

[Chef encrypted data bags](https://docs.chef.io/data_bags.html#encrypt-a-data-bag-item) and [chef-vault](https://docs.chef.io/chef_vault.html) provide some integrated secret management features for infrastructure managed by Chef. Encrypted data bags are used to protect sensitive values from appearing in revision history or to other machines using shared secrets. Chef-vault allows secrets to be encrypted using the target machine’s public key instead, offering further security that isolates decryption capabilities to the intended recipients.

Similarly, [Puppet’s Hiera](https://docs.puppet.com/puppet/latest/hiera_intro.html) key-value storage system can be used with [Hiera eyaml](https://github.com/voxpupuli/hiera-eyaml) to manage secrets securely for specific infrastructure components. Unlike some other systems, Hiera eyaml is aware of the syntax and structure of YAML, the data serialization format that Hiera uses, allowing it to encrypt just the sensitive values instead of the entire file. This makes it possible to work with files that contain encrypted data using normal tools for most tasks. Since the backends are pluggable, teams can implement GPG encryption to easily manage access.

Saltstack uses [Pillars](https://docs.saltstack.com/en/latest/topics/pillar/) to store data designated for certain machines. To protect these items, users can encrypt the YAML values using GPG and then configure the [GPG renderer](https://docs.saltstack.com/en/latest/ref/renderers/all/salt.renderers.gpg.html) to allow Salt to decrypt the values at runtime. Like Hiera eyaml, this system involves encrypting only the sensitive data rather than the full file, allowing normal file editing and diff tools to operate correctly.

Ansible includes [Ansible Vault](http://docs.ansible.com/ansible/latest/playbooks_vault.html), an encryption system and command line tool to encrypt sensitive YAML files within a playbook structure. Ansible can then transparently decrypt the secret files at runtime to combine the secret and non-secret data necessary to carry out given tasks. Ansible vault encrypts the entire file rather than the values, so editing requires decryption and diff tools cannot show accurate change information. However, as of Ansible 2.3, [single variables can be encrypted in variable files](http://docs.ansible.com/ansible/latest/playbooks_vault.html#single-encrypted-variable), giving users a choice in how they want to encrypt sensitive values.

### Advantages

These solutions are well-suited for some of the challenges involved with managing secrets in configuration management contexts. They are able to orchestrate access to secrets by leveraging the existing infrastructure inventory system and role designations which define the type of access each machine requires. The same mechanisms that ensure that each machine gets the correct configuration can ensure that secrets are only delivered to hosts that require them.

Using tools native to your existing infrastructure management and deployment systems minimizes the operational costs of implementing encryption. It’s easier to migrate secrets to encryption using tooling native to your environment and it’s simpler to incorporate runtime decryption of secrets without additional steps. If you are already using a configuration management system, using their included secret management mechanisms will probably be the easiest first step towards protecting your sensitive data.

### Disadvantages

The tight integration means that users can use their existing systems to manage their secrets, but it does mean that these solutions are locked to their respective configuration management tools. Using most of these strategies in other contexts would be difficult or impossible, which means that you are adding a dependency on the configuration management tools themselves. The tight integration to a single platform might also make it problematic for external systems requiring access to the data. Without an external API or callable command in some cases, the secrets can be effectively “trapped” unless accessed through the configuration management system, which can be limiting.

Many of the disadvantages of storing encrypted secrets in your application repository also apply when storing secrets with your configuration management system. Instead of having laptops with your application repositories being a vector for compromise, any laptop or computer with the configuration management repository will likewise be vulnerable. Fundamentally, any system that has both the encrypted values and the decryption key will be vulnerable to this type of compromise.

A related concern is that, while the configuration management system is able to ensure secrets are only accessible to the correct machines, defining fine grained access controls to restrict team members is often more difficult. Some systems can only encrypt with a single password or key, limiting the ability to partition team members’ access to secrets.

## Using an External Secret Management Service

An alternative to storing encrypted secrets alongside the code or in your configuration management system is to use a dedicated service to manage sensitive data for your infrastructure. These services encrypt and store sensitive data and respond to authorized requests with the decrypted values. This allows developers to move their sensitive material out of their repositories and into a system designed to orchestrate encryption, authorization, and authentication for both human users and applications.

### Implementations

Dedicated secret management services like [HashiCorp’s Vault](https://www.vaultproject.io/) offer great flexibility and powerful features to protect sensitive material while not sacrificing usability. Vault protects data at rest and in transit and is designed to use various “backends” to expose different functionality and manage the complexities of encryption, storage, and authentication. Several key features include the ability to configure dynamic secrets (short term credentials for connected services, created on the fly), data encryption as a service (encrypting and storing data from external services and serving the decrypted content again when requested to do so by an authorized party), and lease-based secret management (providing access for a given amount of time, after which access is automatically revoked). Vault’s pluggable architecture means that storage backends, authentication mechanisms, etc. are all swappable as business needs change.

Square’s [Keywhiz](https://square.github.io/keywhiz/) secret management system is another dedicated service used to provide general security for sensitive data. Like Vault, Keywhiz exposes APIs that clients and users can use to store and access secrets. One unique feature that Keywhiz offers is the ability to expose secrets using a FUSE filesystem, a virtual filesystem that clients can mount to access the sensitive data as pseudo-files. This mechanism allows many different types of programs to access the data they need without the help of an agent or wrapper and it allows administrators to lock down access using normal Unix filesystem permissions.

Pinterest’s [Knox](https://github.com/pinterest/knox) is another service for managing secrets. It provides many of the same features as Vault and Keywhiz. One feature not found in the other systems is the ability to rotate keys over time by providing explicit states for key versions. A key version can be marked as primary to indicate that it is the current preferred secret, active to indicate that it is the version can still be used, or inactive to disable the version. This system lets administrators roll keys across a fleet of machines over time without disrupting services.

### Advantages

Dedicated secret management services have many compelling advantages over other systems. Offloading the complexity of securing and managing sensitive data to a standalone system removes the need to address those concerns within application and configuration management repositories. This separation of responsibilities simplifies the operational security model by centralizing secret storage and governing access through strictly controlled interfaces. By providing generic interfaces for interacting with the system, authorized users or clients can access their secrets regardless of the configuration management system or VCS used.

From an administrative perspective, secret management systems provide many unique features not available in other tools. Easy rotation of encryption keys as well as the underlying secrets they protect is incredibly useful for large deployments and complex systems that require coordinating many different sensitive values. Access can be regulated and revoked easily without deploying code or making any fleet-wide changes. Features like dynamic secrets give secret management servers access to external services like databases to create per-use credentials on demand. Short term lease-based access to secrets function as an automatic mechanism for limiting or expiring access without requiring explicit revocation.

One of the most important improvements that centralized secret management provides is auditability. Each of the systems mentioned above maintain extensive records of when secrets are added, requested, accessed, or modified. This can be helpful to spot anomalies and detect suspicious behavior, and can also help assess the extent of any access in the event of a compromise. Having a holistic view of your organization’s sensitive data, the policies set to control access, and information about every successful and attempted change or retrieval puts teams in a good position to make informed decisions about infrastructure security.

### Disadvantages

The main disadvantage of a centralized secret management system is the additional overhead it requires, both in terms of infrastructure and management.

Setting up a centralized system requires a good deal of planning, testing, and coordination prior to deployment into a production environment. Once the infrastructure is up and running, clients must be updated to query the secret management server’s APIs or an agent process must be configured to obtain secrets on behalf of the processes that require it. Policies must be established to dictate which applications, infrastructure, and team members should have access to each protected value.

Due to the value of the data it protects, the secret management server becomes one of the most important security environments to manage. While centralization minimizes the surface area you need to protect, it makes the system itself a high-value target for malicious actors. While many solutions include features like lock-down modes, key-based restarts, and audit logs, unauthorized access to an active, decrypted secret store would require extensive remediation.

Beyond the initial cost of configuration and the security elements, serving all sensitive data from a single service introduces an additional mission critical component to your infrastructure. Since secrets are often required for for bootstrapping new applications and for routine operations, secret management downtime could cause major interruptions that may not be resolvable until the service can be restored. Availability is crucial for a system responsible for coordinating between so many different components.

## Wrapping Up

As you evaluate different methods of protecting sensitive data and coordinating the necessary access during deployments, it’s important to consider the balance between security, usability, and needs of your project. The solutions described above span a wide range of use cases and offer varying degrees scalability and protection.

The best choice for your project or organization will likely depend on the amount of sensitive data you have to protect, the size of your team, and the resources available to manage different solutions. In most cases, it makes sense to start small and to reassess your secret management needs as your circumstances change. While you may only need to protect a few secrets and collaborate with a small team now, in the future the trade-offs for dedicated solutions might become more compelling.
