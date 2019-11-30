---
author: Justin Ellingwood
date: 2017-07-24
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/ci-cd-tools-comparison-jenkins-gitlab-ci-buildbot-drone-and-concourse
---

# CI/CD Tools Comparison: Jenkins, GitLab CI, Buildbot, Drone, and Concourse

## Introduction

[Continuous integration, delivery, and deployment](an-introduction-to-continuous-integration-delivery-and-deployment) are strategies designed to help increase the velocity of development and the release of well-tested, usable products. Continuous integration encourages development teams to test and integrate their changes to a shared codebase early to minimize integration conflicts. Continuous delivery builds off of this foundation by removing barriers on the way to deployment or release. Continuous deployment goes one step further by deploying every build that passes the test suite automatically.

While the terminology above is primarily concerned with strategies and practices, software tooling plays a large role in allowing organizations to accomplish these goals. CI/CD software can help teams advance new changes through a series of stages automatically to reduce the time to feedback and remove friction from the process.

In this guide, we will compare some popular free and open-source continuous integration, delivery, and deployment servers designed to make collaborative software development easier. We will take a look at Jenkins, GitLab CI, Buildbot, Drone, and Concourse.

## Jenkins

[Jenkins](https://jenkins.io/) is one of the earliest open-source continuous integration servers and remains the most common option in use today. Originally a part of the [Hudson](http://hudson-ci.org/) project, the community and codebase split following trademark conflicts with Oracle after their acquisition of Sun Microsystems, the original developers. Hudson was originally released in 2005, while the first release as Jenkins was made in 2011.

Over the years, Jenkins has evolved into a powerful and flexible system of automating software-related tasks. Jenkins itself serves mainly as an automation framework with much of the important logic implemented through a library of plugins. Everything from listening for web hooks or watching repositories to building environments and language support is handled by plugins. While this provides a great deal of flexibility, your CI process may come to rely on numerous third-party plugins, which can be fragile.

Jenkins’ pipeline workflow—also provided through a plugin—is a relatively new addition, available as of 2016. The CI process can be defined either declaratively or imperatively using the [Groovy language](http://groovy-lang.org/) in files within the repository itself or through text boxes in the Jenkins web UI. One common criticism of Jenkins is that the plugin-centric configuration model and ability to define pipeline or build processes outside of repositories can sometimes make it difficult to easily replicate a configuration on a different Jenkins instance.

Jenkins is written in Java and released under an MIT license. Follow our guide on [how to install Jenkins on Ubuntu 16.04](how-to-install-jenkins-on-ubuntu-16-04) to configure a Jenkins server for your project.

## GitLab CI

[GitLab CI](https://about.gitlab.com/features/gitlab-ci-cd/) is a continuous integration tool built into [GitLab](https://about.gitlab.com/), a git repository hosting and development tools platform. Originally released as a standalone project, GitLab CI was integrated into the main GitLab software with the release of GitLab 8.0 in September, 2015.

The CI/CD process in GitLab CI is defined within a file in the code repository itself using a YAML configuration syntax. The work is then dispatched to machines called runners, which are easy to set up and can be provisioned on many different operating systems. When configuring runners, you can choose between different executors like Docker, shell, VirtualBox, or Kubernetes to determine how the tasks are carried out.

The tight coupling of GitLab CI with the GitLab repository platform has definite implications on the how the software can be used. GitLab CI is not an option for developers who use other repository hosting platforms. On the positive side, the integrated functionality allows GitLab users to set up a CI/CD environment without installing and learning an additional tool. Automated testing can begin by enabling a few options in the web interface, registering a runner machine, and adding a pipeline definition file into the repository. The close relationship also allows you to share runners between projects, see the current build status within the repository automatically, and keep build artifacts with the code that produced them.

GitLab and GitLab CI are written in Ruby and Go and released under an MIT license. You can follow our guide on [how to set up continuous integration pipelines with GitLab CI](how-to-set-up-continuous-integration-pipelines-with-gitlab-ci-on-ubuntu-16-04) to learn how to configure this functionality on your GitLab server.

## Buildbot

[Buildbot](https://buildbot.net/) is a continuous integration framework that offers tremendous amounts of flexibility. First released in 2003 as an alternative to Mozilla’s Tinderbox project, Buildbot was designed primarily as a way to automate build testing across a wide array of platforms.

Buildbot is released with GPL licensing and written in Python using the Twisted library. Rather than abstracting away the underlying language for the sake of simplified configuration, Buildbot’s configuration is written entirely in Python. This means that the configuration tends to be significantly more complex than other systems but administrators have more scope to design their ideal workflow and process. Each stage of the build is clearly separated and programmable. Buildbot positions itself as a framework with tools to build your own custom processes, comparable to how web frameworks allow you to build custom sites.

Buildbot’s history as a build testing platform means that it has support for many different operating systems and version control systems. Likewise, because it was designed with open-source testing in mind, its architecture allows users to easily submit workers with their preferred platforms to projects to expand the available test base. The user only needs to install a few Python packages on the system and then provide the credentials to the project.

To start using Buildbot to automate your build processes, follow our guide on [how to install Buildbot on Ubuntu 16.04](how-to-install-buildbot-on-ubuntu-16-04).

## Drone

[Drone](https://drone.io/) is a modern CI/CD platform built with a containers-first architecture. While the tools discussed above all include the option of running builds with Docker, a container-based workflow is at the core of Drone’s design. Drone is written in Go and was first released in 2014 under an Apache license.

Drone acts as a middle coordinating layer between Docker and a repository provider. Rather than starting up the CI/CD server and then hooking into a version control system hosting service afterwards, Drone requires the repository account information upfront to bootstrap its own authentication, user, and permissions models. As with all of its CI processes, Drone itself is run as a container. It supports multiple database backends and repository providers and has builtin support for setting up TLS/SSL certificates with [Let’s Encrypt](https://letsencrypt.org/) for transport encryption.

Drone looks for special YAML files within repositories for the pipeline definition. The syntax is designed to be easy to read and expressive so that anyone using the repository can understand the continuous integration process. Drone provides a plugin system, but it is used differently than the one in Jenkins. In Drone, plugins are special Docker containers used to drop preconfigured tasks into the regular workflow. This makes it easier to accomplish common tasks by calling the plugin with a few parameters rather than scripting the entire process manually. In this sense, Drone plugins are somewhat similar to Unix utility commands that are designed to do one narrowly-focused task well.

To learn how to set up a Drone server to automatically test your commits, follow our [how to install and configure Drone on Ubuntu 16.04](how-to-install-and-configure-drone-on-ubuntu-16-04) guide.

## Concourse

[Concourse](https://concourse.ci/) is a relatively new continuous integration platform initially released in 2014. Concourse’s approach to the CI/CD space is significantly different from the other tools we’ve looked at in that it attempts to take itself out of the equation as much as possible, minimizing state and abstracting every external factor into something it calls “resources”. The goal of this philosophy is to make the integration server entirely disposable so that the same processes can easily be run on any Concourse server.

Every part of the continuous integration process is composed from basic primitives that model different elements of the system. Each part of the process defines its dependencies explicitly. For example, the first task may require the latest commit to a VCS repository while later parts of the process may require the latest commit _that passed previous stages_. This method of constructing pipelines by mapping the exact dependencies of each step leads to strictly-defined behavior.

To further remove incidental state from the process, Concourse does not implicitly pass anything between jobs and does not provide any internal way of storing build artifacts. All information needed by the next stage must be explicitly defined, and potentially pushed to an external store to be pulled into the next step. By requiring explicit definitions, Concourse hopes to minimize the number of assumptions and unknown variables that the system has to account for.

Concourse is written in Go and released under an Apache license. If you would like to learn how to set up a Concourse server to automate your continuous integration processes, check out our guide on [how to install Concourse CI on Ubuntu 16.04](how-to-install-concourse-ci-on-ubuntu-16-04).

## Conclusion

Continuous integration, delivery, and deployment software are complex automation systems designed to make your processes dependable and repeatable. As you can gather from the descriptions above, there are many different ideas about how automated testing and release is best accomplished, with emphasis placed on different parts of the equation. No single tool will satisfy the needs of every project, but with so many high quality open source solutions available, there’s a good chance you will be able to find a system that meets your team’s needs.
