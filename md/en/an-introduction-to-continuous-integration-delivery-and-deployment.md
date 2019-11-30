---
author: Justin Ellingwood
date: 2017-05-10
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-introduction-to-continuous-integration-delivery-and-deployment
---

# An Introduction to Continuous Integration, Delivery, and Deployment

## Introduction

Developing and releasing software can be a complicated process, especially as applications, teams, and deployment infrastructure grow in complexity themselves. Often, challenges become more pronounced as projects grow. To develop, test, and release software in a quick and consistent way, developers and organizations have created three related but distinct strategies to manage and automate these processes.

Continuous integration focuses on integrating work from individual developers into a main repository multiple times a day to catch integration bugs early and accelerate collaborative development. Continuous delivery is concerned with reducing friction in the deployment or release process, automating the steps required to deploy a build so that code can be released safely at any time. Continuous deployment takes this one step further by automatically deploying each time a code change is made.

In this guide, we will discuss each of these strategies, how they relate to one another, and how incorporating them into your application life cycle can transform your software development and release practices. To get a better idea of the differences between various open-source CI/CD projects, check out our [CI/CD tool comparison](ci-cd-tools-comparison-jenkins-gitlab-ci-buildbot-drone-and-concourse).

## What is Continuous Integration and Why Is It Helpful?

**Continuous integration** is a practice that encourages developers to integrate their code into a main branch of a shared repository early and often. Instead of building out features in isolation and integrating them at the end of a development cycle, code is integrated with the shared repository by each developer multiple times throughout the day.

The idea is to minimize the cost of integration by making it an early consideration. Developers can discover conflicts at the boundaries between new and existing code early, while conflicts are still relatively easy to reconcile. Once the conflict is resolved, work can continue with confidence that the new code honors the requirements of the existing codebase.

Integrating code frequently does not, by itself, offer any guarantees about the quality of the new code or functionality. In many organizations, integration is costly because manual processes are used to ensure that the code meets standards, does not introduce bugs, and does not break existing functionality. Frequent integration can create friction when the level of automation does not match the amount quality assurance measures in place.

To address this friction within the integration process, in practice, continuous integration relies on robust test suites and an automated system to run those tests. When a developer merges code into the main repository, automated processes kick off a build of the new code. Afterwards, test suites are run against the new build to check whether any integration problems were introduced. If either the build or the test phase fails, the team is alerted so that they can work to fix the build.

The end goal of continuous integration is to make integration a simple, repeatable process that is part of the everyday development workflow in order to reduce integration costs and respond to defects early. Working to make sure the system is robust, automated, and fast while cultivating a team culture that encourages frequent iteration and responsiveness to build issues is fundamental to the success of the strategy.

## What is Continuous Delivery and Why Is It Helpful?

**Continuous delivery** is an extension of continuous integration. It focuses on automating the software delivery process so that teams can easily and confidently deploy their code to production at any time. By ensuring that the codebase is always in a deployable state, releasing software becomes an unremarkable event without complicated ritual. Teams can be confident that they can release whenever they need to without complex coordination or late-stage testing. As with continuous integration, continuous delivery is a practice that requires a mixture of technical and organizational improvements to be effective.

On the technology side, continuous delivery leans heavily on deployment pipelines to automate the testing and deployment processes. A **deployment pipeline** is an automated system that runs increasingly rigorous test suites against a build as a series of sequential stages. This picks up where continuous integration leaves off, so a reliable continuous integration setup is a prerequisite to implementing continuous delivery.

At each stage, the build either fails the tests, which alerts the team, or passes the tests, which results in automatic promotion to the next stage. As the build moves through the pipeline, later stages deploy the build to environments that mirror the production environment as closely as possible. This way the build, the deployment process, and the environment can be tested in tandem. The pipeline ends with a build that can be deployed to production at any time in a single step.

The organizational aspects of continuous delivery encourage prioritization of “deployability” as a principle concern. This has an impact on the way that features are built and hooked into the rest of the codebase. Thought must be put into the design of the code so that features can be safely deployed to production at any time, even when incomplete. A number of techniques have emerged to assist in this area.

Continuous delivery is attractive because it automates the steps between checking code into the repository and deciding on whether to release well-tested, functional builds to your production infrastructure. The steps that help assert the quality and correctness of the code are automated, but the final decision about what to release is left in the hands of the organization for maximum flexibility.

## What is Continuous Deployment and Why Is It Helpful?

**Continuous deployment** is an extension of continuous delivery that automatically deploys each build that passes the full test cycle. Instead of waiting for a human gatekeeper to decide what and when to deploy to production, a continuous deployment system deploys everything that has successfully traversed the deployment pipeline. Keep in mind that while new code is automatically _deployed_, techniques exist to activate new features at a later time or for a subset of users. Deploying automatically pushes features and fixes to customers quickly, encourages smaller changes with limited scope, and helps avoid confusion over what is currently deployed to production.

This fully automated deploy cycle can be a source of anxiety for organizations worried about relinquishing control to their automation system of what gets released. The trade-off offered by automated deployments is sometimes judged to be too dangerous for the payoff they provide.

Other groups leverage the promise of automatic release as a method of ensuring that best practices are always followed and to extend the testing process into a limited production environment. Without a final manual verification before deploying a piece of code, developers must take responsibility for ensuring that their code is well-designed and that the test suites are up-to-date. This collapses the decision of what and when to commit to the main repository and what and when to release to production into a single point that exists firmly in the hands of the development team.

Continuous deployment also allows organizations to benefit from consistent early feedback. Features can immediately be made available to users and defects or unhelpful implementations can be caught early before the team devotes extensive effort in an unproductive direction. Getting fast feedback that a feature isn’t helpful lets the team shift focus rather than sinking more energy into an area with minimal impact.

## Key Concepts and Practices for Continuous Processes

While continuous integration, delivery, and deployment vary in the scope of their involvement, there are some concepts and practices that are fundamental to the success of each.

### Small, Iterative Changes

One of the most important practices when adopting continuous integration is to encourage small changes. Developers should practice breaking up larger work into small pieces and committing those early. Special techniques like branch by abstraction and feature flags (see below) help to protect the functionality of the main branch from in-progress code changes.

Small changes minimize the possibility and impact of integration problems. By committing to the shared branch at the earliest possible stage and then continually throughout development, the cost of integration is diminished and unrelated work is synchronized regularly.

### Trunk-Based Development

With trunk-based development, work is done in the main branch of the repository or merged back into the shared repository at frequent intervals. Short-lived feature branches are permissible as long as they represent small changes and are merged back as soon as possible.

The idea behind trunk-based development is to avoid large commits that violate of concept of small, iterative changes discussed above. Code is available to peers early so that conflicts can be resolved when their scope is small.

Releases are performed from the main branch or from a release branch created from the trunk specifically for that purpose. No development occurs on the release branches in order to maintain focus on the main branch as the single source of truth.

### Keep the Building and Testing Phases Fast

Each of the processes relies on automated building and testing to validate correctness. Because the build and test steps must be performed frequently, it is essential that these processes be streamlined to minimize the time spent on these steps.

Increases in build time should be treated as a major problem because the impact is compounded by the fact that each commit kicks off a build. Because continuous processes force developers to engage with these activities daily, reducing friction in these areas is a worthwhile pursuit.

When possible, running different sections of the test suite in parallel can help move the build through the pipeline faster. Care should also be taken to make sure the proportion of each _type_ of test makes sense. Unit tests are typically very fast and have minimal maintenance overhead. In contrast, automated system or acceptance testing is often complex and prone to breakage. To account for this, it is often a good idea to rely heavily on unit tests, conduct a fair number of integration tests, and then back off on the number of later, more complex testing.

### Consistency Throughout the Deployment Pipeline

Because a continuous delivery or deployment implementations is supposed to be testing release worthiness, it is essential to maintain consistency during each step of the process—the build itself, the deployment environments, and the deployment process itself:

- **Code should be built once at the beginning of the pipeline** : The resulting software should be stored and accessible to later processes without rebuilding. By using the exact same artifact in each phase, you can be certain that you are not introducing inconsistencies as a result of different build tools.
- **Deployment environments should be consistent** : A configuration management system can control the various environments, and environmental changes can be put through the deployment pipeline itself to ensure correctness and consistency. Clean deployment environments should be provisioned each test cycle to prevent legacy conditions from compromising the integrity of the tests. The staging environments should match the production environment as closely as possible to reduce unknown factors present when the build is promoted.
- **Consistent processes should be used to deploy the build in each environment** : Each deployment should be automated and each deployment should use the same centralized tools and procedures. Ad-hoc deployments should be eliminated in favor of deploying only with the pipeline tools.

### Decouple Deployment and Release

Separating the deployment of code from its release to users is an extremely powerful part of continuous delivery and deployment. Code can be deployed to production without initially activating it or making it accessible to users. Then, the organization decides when to release new functionality or features independent from deployment.

This gives organizations a great deal of flexibility by separating business decisions from technical processes. If the code is already on the servers, then deployment is no longer a delicate part of the release process, which minimizes the number of individuals and the amount of work involved at the time of release.

There are a number of techniques that help teams deploy the code responsible for a feature without releasing it. Feature flags set up conditional logic to check whether to run code based on the value of an environmental variable. Branch by abstraction allows developers to replace implementations by placing an abstraction layer between resource consumers and providers. Careful planning to incorporate these techniques gives you the ability to decouple these two processes.

## Types of Testing

Continuous integration, delivery, and deployment all rely heavily on automated tests to determine the efficacy and correctness of each code change. Different types of tests are needed throughout these processes to gain confidence in a given solution.

While the categories below in no way represent an exhaustive list, and although there is disagreement on the exact definition of each type, these broad categories of tests represent a variety of ways to evaluate code in different contexts.

### Smoke Testing

Smoke tests are a special kind of initial checks designed to ensure very basic functionality as well as some basic implementation and environmental assumptions. Smoke tests are generally run at the very start of each testing cycle as a sanity check before running a more complete test suite.

The idea behind this type of test is to help to catch big red flags in an implementation and to bring attention to problems that might indicate that further testing is either not possible or not worthwhile. Smoke tests are not very extensive, but should be extremely quick. If a change fails a smoke test, its an early signal that core assertions were broken and that you should not devote any more time to testing until the problem is resolved.

Context-specific smoke tests can be employed at the start of any new phase testing to assert that the basic assumptions and requirements are met. For instance, smoke tests can be used both prior to integration testing or deploying to staging servers, but the conditions to be tested will vary in each case.

### Unit Testing

Unit tests are responsible for testing individual elements of code in an isolated and highly targeted way. The functionality of individual functions and classes are tested on their own. Any external dependencies are replaced with stub or mock implementations to focus the test completely on the code in question.

Unit tests are essential to test the correctness of individual code components for internal consistency and correctness before they are placed in more complex contexts. The limited extent of the tests and the removal of dependencies makes it easier to hunt down the cause of any defects. It also is the best time to test a variety of inputs and code branches that might be difficult to hit later on. Often, after any smoke tests, unit tests are the first tests that are run when any changes are made.

Unit tests are typically run by individual developers on their own work station prior to submitting changes. However, continuous integration servers almost always run these tests again as a safe guard before beginning integration tests.

### Integration Testing

After unit tests, integration testing is performed by grouping together components and testing them as an assembly. While unit tests validate the functionality of code in isolation, integration tests ensure that components cooperate when interfacing with one another. This type of testing has the opportunity to catch an entirely different class of bugs that are exposed through interaction between components.

Typically, integration tests are performed automatically when code is checked into a shared repository. A continuous integration server checks out the code, performs any necessary build steps (usually performing a quick smoke test to make sure the build was successful) and then runs unit and integration tests. Modules are hooked together in different combinations and tested.

Integration tests are important for shared work because they protect the health of the project. Changes must prove that they do not break existing functionality and that they interact with other code as expected. A secondary aim of integration testing is to verify that the changes can be deployed into a clean environment. This is frequently the first testing cycle that is performed off of the developer’s own machines, so unknown software and environmental dependencies can also be discovered during this process. This is usually also the first time that new code is tested against real external libraries, services, and data.

### System Testing

Once integration tests are performed, another level of testing called system testing can begin. In many ways, system testing acts as an extension to integration testing. The focus of system tests are to make sure that groups of components function correctly as a cohesive whole.

Instead of focusing on the interfaces between components, system tests typically evaluate the outward functionality of a full piece of software. This set of tests ignores the constituent parts in order to gauge the composed software as a unified entity. Because of this distinction, system tests usually focus on user- or externally-accessible interfaces.

### Acceptance Testing

Acceptance tests are one of the last tests types that are performed on software prior to delivery. Acceptance testing is used to determine whether a piece of software satisfies all of the requirements from the business or user’s perspective. These tests are sometimes built against the original specification and often test interfaces for the expected functionality and for usability.

Acceptance testing is often a more involved phase that might extend past the release of the software. Automated acceptance testing can be used to make sure the technological requirements of the design were met, but manual verification also usually plays a role.

Frequently, acceptance testing begins by deploying the build to a staging environment that mirrors the production system. From here, the automated test suites can be run and internal users can access the system to check whether it functions the way they need it to. After release or offering beta access to customers, further acceptance testing is performed by evaluating how the software functions with real use and by collecting feedback from users.

## Additional Terminology

While we’ve discussed some of the broader ideas above, there are many related concepts that you may come across as you learn about continuous integration, delivery, and deployment. Let’s define a few other terms you are likely to see:

- **Blue-Green Deployments** : Blue-green deployments is a strategy for testing code in a production-like environment and for deploying code with minimal downtime. Two sets of production-capable environments are maintained, and code is deployed to the inactive set where testing can take place. When ready to release, production traffic is routed to the servers with the new code, instantly making the changes available.
- **Branch by Abstraction** : Branch by abstraction is a method of performing major refactoring operations in an active project without long-lived development branches in the source code repository, which continuous integration practices discourage. An abstraction layer is built and deployed between consumers and the existing implementation so that the new implementation can be built out behind the abstraction in parallel.
- **Build (noun)**: A build is a specific version of software created from source code. Depending on the language, this might be compiled code or a consistent set of interpreted code.
- **Canary Releases** : Canary releases are a strategy for releasing changes to a limited subset of users. The idea is to make sure everything works correctly with production workloads while minimizing the impact if there are problems.
- **Dark launch** : Dark launching is the practice of deploying code to production that receives production traffic but does not impact the user experience. New changes are deployed alongside existing implementations and the same traffic is often routed to both places for testing. The old implementation is still hooked up to the user’s interface, but behind the scenes, the new code can be evaluated for correctness using real user requests in the production environment.
- **Deployment Pipeline** : A deployment pipeline is a set of components that moves software through increasingly rigorous testing and deployment scenarios to evaluate its readiness for release. The pipeline typically ends by automatically deploying to production or providing the option to do so manually.
- **Feature Flags** or **Feature Toggles** : Feature flags are a technique of deploying new features behind conditional logic that determines whether or not to run based on the value of an environmental variable. New code can be deployed to production without being activated by setting the flag appropriately. To release the software, the value of the environmental variable is changed, causing the new code path to be activated. Feature flags often contain logic that allows for subsets of users to gain access to the new feature, creating a mechanism to gradually roll out the new code.
- **Promoting** : In the context of continuous processes, promoting means moving a software build through to the next stage of testing.
- **Soak Test** : Soak testing involves testing software under significant production or production-like load for an extended period of time.

## Conclusion

In this guide, we introduced continuous integration, continuous delivery, and continuous deployment and discussed how they can be used to build and release well-tested software safely and quickly. These processes leverage extensive automation and encourage constant code sharing to fix defects early. While the techniques, processes, and tools needed to implement these solutions represent a significant challenge, the benefits of a well-designed and properly used system can be enormous.

To find out which CI/CD solution might be right for your project, take a look at our [CI/CD tool comparison guide](ci-cd-tools-comparison-jenkins-gitlab-ci-buildbot-drone-and-concourse) for more information.
