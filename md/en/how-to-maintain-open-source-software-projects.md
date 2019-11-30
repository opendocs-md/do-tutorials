---
author: Lisa Tagliaferri
date: 2016-10-06
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/how-to-maintain-open-source-software-projects
---

# How To Maintain Open-Source Software Projects

## Introduction

When you maintain an open-source software repository, you’re taking on a leadership role. Whether you’re the founder of a project who released it to the public for use and contributions, or you’re working on a team and are maintaining one specific aspect of the project, you are going to be providing an important service to the larger developer community.

While open-source [contributions through pull requests](how-to-create-a-pull-request-on-github) from the developer community are crucial for ensuring that software is as useful as it can be for end users, maintainers have a real impact on shaping the overall project. Repository maintainers are extremely involved in the open-source projects they manage, from day-to-day organization and development, to interfacing with the public and providing prompt and effective feedback to contributors.

This guide will take you through some tips for maintaining public repositories of open-source software. Being a leader of an open-source project comes with both technical and non-technical responsibilities to help foster a user-base and community around your project. Taking on the role of a maintainer is an opportunity to learn from others, get experience with project management, and watch your project grow and change as your users become invested contributors.

## Write Useful Documentation

Documentation that is thorough, well-organized, and serves the intended communities of your project will help expand your user base. Over time, your user base will become the contributors to your open-source project.

Since you’ll be thinking through the code you are creating anyway, and may even be jotting down notes, it can be worthwhile to incorporate documentation as part of your development process while it is fresh in your mind. You may even want to consider writing the documentation before the code, following the philosophy of a documentation-driven development approach that documents features first and develops those features after writing out what they will do.

Along with your code, there are a few files of documentation that you’ll want to keep in your top-level directory:

- `README.md` file that provides a summary of the project and your goals. 
- `CONTRIBUTING.md` file with contribution instructions.
- License for your software, which can encourage more contributions. [Read more about choosing an open-source license here](http://choosealicense.com/).

Documentation can come in many forms and can target different audiences. As part of your documentation, and depending on the scope of your work, you may decide to do one or more of the following:

- A **general guide** to introduce users to the project 
- **Tutorials** to walk people through different use cases
- **FAQs** to address frequently asked questions that users may have
- **Troubleshooting guides** to help users resolve problems
- An **API reference** to provides users with a quick way to look up API information
- **Release notes** with known bugs to let users know what to expect in each release
- **Planned features** to keep track of and explain what is coming up in the future 
- **Video walkthroughs** to provide users with a multimedia approach to your software

Your project may be better-suited to certain kinds of documentation than others, but providing more than one approach to the software will help your user base better understand how to interact with your work.

When writing documentation, or recording voice for a video, it is important to be as clear as possible. It is best to make no assumptions about the technical ability of your audience. You’ll also want to approach your documentation from the top down — that is, explain what your software does in a general way (e.g., automate server tasks, build a website, animate sprites for game development), before going into details.

Though English has become a universal language in the technology sphere, you’ll still want to consider who your expected users are and how to reach them. English may be the best choice to have access to a broad user base, but you’ll want to keep in mind that many people are approaching your documentation as non-native English speakers, so work to favor straight-forward language that will not confuse your readers or viewers.

Try to write documentation as though you are writing to a collaborator who needs to be brought up to speed on the current project; after all, you’ll want to encourage potential contributors to make pull requests to the project.

## Organize Issues

**Issues** are typically a way to keep track of or report bugs, or to request new features to be added to the code base. Open-source repository hosting services like GitHub, GitLab and Bitbucket will provide you with an interface for yourself and others to keep track of issues within your repository. When releasing open-source code to the public, you should expect to have issues opened by the community of users. Organizing and prioritizing issues will give you a good road map of upcoming work on your project.

Because any user can file an issue, not all issues will be reporting bugs or be feature requests; you may receive questions via the issue tracker tool, or you may receive requests for smaller enhancements to the user interface, for example. It is best to organize these issues as much as possible and to be communicative to the users who are creating these issues.

Issues should represent concrete tasks that need to be done on the source code, and you will need to prioritize them accordingly. You and your team will have an understanding of the amount of time and energy you or contributors can devote to filed issues, and together you can work collaboratively to make decisions and create an actionable plan. When you know you won’t be able to get to a particular issue within a quick timeframe, you can still comment on the issue to let the user know that you have read the issue and that you’ll get to it when you can, and if you are able to you can provide an expected timeline for when you can look at the issue again.

For issues that are feature requests or enhancements, you can ask the person who filed the issue whether they are able to contribute code themselves. You can direct them to the `CONTRIBUTORS.md` file and any other relevant documentation.

Since questions often do not represent concrete tasks, commenting on the issue to courteously direct the user to relevant documentation can be a good option to keep your interactions professional and kind. If documentation for this question does not exist, now is a great time to add the relevant documentation, and express your thanks to the user for identifying this oversight. If you are getting a lot of questions via issues, you may consider creating a FAQ section of your documentation, or a wiki or forum for others to participate in question-answering.

Whenever a user reports an issue, try to be as kind and gracious as possible. Issues are indicators that users like your software and want to make it better!

Working to organize issues as best you can will keep your project up to date and relevant to its community of users. Remove issues that are outside of the scope of your project or become stale, and prioritize the others so that you are able to make continuous progress.

## Make Contributing Rewarding

The more you welcome contributors to your project and reward their efforts, the more likely you’ll be to encourage more contributions. To get people started, you’ll want to include a `CONTRIBUTING.md` file in the top-level of your repository, and a pointer to that file in your `README.md` file.

A good file on contributing will outline how to get started working on the project as a developer. You may want to offer a step-by-step guide, or provide a checklist for developers to follow, explaining how to successfully get their code merged into the project through a pull request.

In addition to documentation on how to contribute to the project, don’t forget to keep the code consistent and readable throughout. Code that is easy to understand through comments and clear and consistent usage will go a long way to making contributors feel like they can jump in on the project.

Finally, maintain a list of contributors or authors. You can invite contributors to add themselves to the list no matter what their contribution (even fixing typos is valuable, and can lead to more contributions in the future). This provides a way to recognize contributors for their work on the project in a public-facing way that they can point to, while also making others aware of how well contributors are treated.

## Build Your Community

By empowering users through documentation, being responsive to issues, and encouraging them to participate, you are already well on your way to building out the community around your open-source project. Users that you keep happy and who you treat as collaborators will in turn promote your software.

Additionally, you can work to promote your project through various avenues:

- Blogging
- Releasing overview or walkthrough videos
- Maintaining a mailing list
- Being active on social media channels
- Collaborating with similar or related projects and cross-promoting them 

You’ll want to tailor your promotion to the scope of your project and the number of active team members and contributors you have working with you.

As your community grows, you can provide more spaces for contributors, users, and maintainers to interact. Some options you may consider include:

- Wikis that can provide documentation that is maintained at the community-level
- Forums for discussing possible features and answering questions
- A listserv for email-based community engagement

Consider your core user base and the scope of your project — including the number of people who are maintaining the project and the resources you have available — before rolling out these potential spaces, and seek feedback from your community about what works for them.

Above all, it is important to be kind and show some love in all of your interactions with your community. Being a gracious maintainer is not always easy, but it will pay off for your project down the line.

## Conclusion

Repository maintainers are incredibly important within the larger open-source community. Though it requires significant investment and hard work, it is often a rewarding experience that allows you to grow as a developer and a contributor. Being an approachable and kind maintainer can go a long way to advance the development of a project that you care about.
