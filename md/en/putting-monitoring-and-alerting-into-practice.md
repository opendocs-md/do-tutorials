---
author: Justin Ellingwood
date: 2018-01-18
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/putting-monitoring-and-alerting-into-practice
---

# Putting Monitoring and Alerting into Practice

## Introduction

Monitoring systems help increase visibility into your infrastructure and applications and define acceptable ranges of performance and reliability. By understanding which components to measure and the most appropriate metrics to focus on for different scenarios, you can begin to plan a monitoring strategy that covers all critical parts of your services. In our guide about [gathering metrics from your infrastructure and applications](gathering-metrics-from-your-infrastructure-and-applications), we introduced a popular framework to identify high value metrics and then broke a deployment into layers to discuss what to gather at various stages.

In this guide, we will talk about the components that make up a monitoring system and how to use them to implement your monitoring strategy. We will begin by reviewing the basic responsibilities of an effective, reliable monitoring system. Afterwards, we will cover how the elements of a monitoring system fulfill those functional requirements. Then, we’ll talk about how best to translate your monitoring policies into dashboards and alert policies that provide your team with the information they need without requesting their attention at unwarranted times.

## Review of Important Qualities of a Metrics, Monitoring, and Alerting System

In one of the final sections of our [introduction to metrics, monitoring, and alerting](an-introduction-to-metrics-monitoring-and-alerting) guide, we discussed some of [the most important qualities of an effective monitoring system](an-introduction-to-metrics-monitoring-and-alerting#important-qualities-of-a-metrics,-monitoring,-and-alerting-system). Since we’ll be looking at the core components of these systems momentarily, it’s useful to review the characteristics that we identified as being useful or necessary:

- **Independent from Most Other Infrastructure** : To accurately collect data and avoid negatively impacting performance, most monitoring components should use dedicated resources separate from other applications.
- **Reliable and Trustworthy** : Since monitoring is used to assess the health of other systems, it is important to make sure the monitoring system itself is both correct and available.
- **Easy to Use Summary and Detail Views** : Data is not useful if it is not comprehensible or actionable. Allowing operators to see summary views and then discover more details in areas that are important is incredibly valuable during investigations.
- **Effective Strategy for Maintaining Historical Data** : It is important to understand what typical patterns are like in order to recognize anomalies. Over longer timelines, this might require access to older data that your system must be able to retrieve and access.
- **Able to Correlate Factors from Different Sources** : Displaying information from disparate parts of your deployments in an organized way is important for identifying patterns and correlated factors.
- **Easy to Start Tracking New Metrics or Infrastructure** : Your monitoring system must evolve as your applications and infrastructure change. Stale or incomplete monitoring coverage decreases trust in your tooling and data.
- **Flexible and Powerful Alerting** : The alerting functionality must be capable of sending notifications in a variety of channels and priorities depending on conditions you define.

With these attributes in mind, let’s take a look at what makes up a monitoring system.

## Parts of a Monitoring System

Monitoring systems are comprised of a few different components and interfaces that all work together to collect, visualize, and report on the health of your deployment. We will cover the basic individual parts below.

### Distributed Monitoring Agents and Data Exporters

While the bulk of the monitoring system might be deployed to a dedicated server or servers, data needs to be gathered from many different sources throughout your infrastructure. To do this, a monitoring agent—a small application designed to collect and forward data to a collection endpoint—is installed on each individual machine throughout the network. These agents gather statistics and usage metrics from the host where they are installed and send them to the central monitoring software.

Agents run as always-on daemons on each host throughout the system. They may include a basic configuration to authenticate securely with the remote data endpoint, define the data frequency or sampling policies, and set unique identifiers for the hosts’ data. To reduce the impact on other services, the agent must use minimal resources and be able to operate with little to no management. Ideally, it should be trivial to install an agent on a new node and begin sending metrics to the central monitoring system.

Monitoring agents typically collect generic, host-level metrics, but agents to monitor software like web or database servers are available as well. For most specialized types of software, however, data will have to be collected and exported by either modifying the software itself, or building your own agent by creating a service that parses the software’s status endpoints or log entries. Many popular monitoring solutions have libraries available to make it easier to add custom instrumentation to your services. As with agent software, care must be taken to ensure that your custom solutions minimize their footprint to avoid impacting the health or performance of your applications.

So far, we’ve made some assumptions about a push-based architecture for monitoring, where the agents push data to a central location. However, pull-based designs are also available. In pull-based monitoring systems, individual hosts are responsible for gathering, aggregating, and serving metrics in a known format at an accessible endpoint. The monitoring server polls the metrics endpoint on each host to gather the metrics data. The software that collects and presents the data through the endpoint has many of the same requirements as an agent, but often requires less configuration since it does not need to know how to access other machines.

### Metrics Ingress

One of the busiest part of a monitoring system at any given time is the metrics ingress component. Because data is constantly being generated, the collection process needs to be robust enough to handle a high volume of activity and coordinate with the storage layer to correctly record the incoming data.

For push-based systems, the metrics ingress endpoint is a central location on the network where each monitoring agent or stats aggregator sends its collected data. The endpoint should be able to authenticate and receive data from a large number of hosts simultaneously. Ingress endpoints for metrics systems are often load balanced or distributed at scale both for reliability and to keep up with high volumes of traffic.

For pull-based systems, the corresponding component is the polling mechanism that reaches out and parses the metrics endpoints exposed on individual hosts. This has some of the same requirements, but some responsibilities are reversed. For instance, if individual hosts implement authentication, the metrics gathering process must be able to provide the correct credentials to log in and access the secure endpoint.

### Data Management Layer

The data management layer is responsible for organizing and recording incoming data from the metrics ingress component and responding to queries and data requests from the administrative layers. Metrics data is usually recorded in a format called a **time series** which represents changes in value over time. Time series databases—databases that specialize in storing and querying this type of data—are frequently used within monitoring systems.

The data management layer’s primary responsibility is to store incoming data as it is received or collected from hosts. At a minimum, the storage layer should record the metric being reported, the value observed, the time the value was generated, and the host that produced it.

For persistence over longer periods of time, the storage layer needs to provide a way to export data when the collection exceeds the local limitations for processing, memory, or storage. As a result, the storage layer also needs to be able to import data in bulk to re-ingest historic data into the system when necessary.

The data management layer also needs to provide organized access to the stored information. For systems using time series databases, this functionality is provided by built-in querying languages or APIs. These can be used for interactive querying and data exploration, but the primary consumers will likely be the data presentation dashboards and the alert system.

### Visualization and Dashboard Layer

Built on top of the data management layer are the interfaces that you interact with to understand the data being collected. Since metrics are time series data, data is best represented as a graph with time on the x-axis. This way, you can easily understand how values change over time. Metrics can be visualized over various time scales to understand trends over long periods of time as well as recent changes that might be affecting your systems currently.

The visualization and data management layers are both involved in ensuring that data from various hosts or from different parts of your application stack can be overlaid and viewed holistically. Luckily, time series data provides a consistent scale which helps identify events or changes that happened concurrently, even when the impact is spread across different types of infrastructure. Being able to select which data to overlay interactively allows operators to construct visualizations most useful for the task at hand.

Commonly used graphs and data are often organized into saved dashboards. These are useful in a number of contexts, either as a continual representation of current health metrics for always-on displays, or as focused portals for troubleshooting or deep diving into specific areas of your system. For instance, a dashboard with a detailed breakdown of physical storage capacity throughout a fleet can be important when capacity planning, but might not need to be referenced for daily administration. Making it easy to construct both generalized and focused dashboards can help make your data more accessible and actionable.

### Alerting and Threshold Functionality

While graphs and dashboards will be your go-to tools for understanding the data in your system, they are only useful in contexts where a human operator is viewing the page. One of the most important responsibilities of a monitoring system is to relieve team members from actively watching your systems so that they can pursue more valuable activities. To make this feasible, the system must be able to ask for your attention when necessary so that you can be confident you will be made aware of important changes. Monitoring systems use user-defined metric thresholds and alert systems to accomplish this.

The goal of the alert system is to reliably notify operators when data indicates an important change and to leave them alone otherwise. Since this requires the system to know what you consider to be a significant event, you must define your alerting criteria. Alert definitions are composed of a notification method and a metric threshold that the system continuously evaluates based on incoming data. The threshold usually defines a maximum or minimum average value for a metric over a specified time frame while the notification method describes how to send out the alert.

One of the most difficult parts of alerting is finding a balance that allows you to be responsive to issues while not over alerting. To accomplish this, you need to understand which metrics are the best indications of real problems, which problems require immediate attention, and what notification methods are best suited for different scenarios. To support this, the threshold definition language must be powerful enough to adequately describe your criteria. Similarly, the notification component must offer methods of communicating appropriate for various levels of severity.

## Black-Box and White-Box Monitoring

Now that we’ve described how various parts of the monitoring system contribute to improving visibility into your deployment, we can talk about some of the ways that you can define thresholds and alerts to best serve your team. We’ll begin by discussing the difference between black-box and white-box monitoring.

Black-box and white-box monitoring describe different models for monitoring. They are not mutually exclusive, so often systems use a mixture of each type to take advantage of their unique strengths.

**Black-box monitoring** describes an alert definition or graph based only on externally visible factors. This style of monitoring takes an outside perspective to maintain a focus on the public behavior of your application or service. With no special knowledge of the health of the underlying components, black-box monitoring provides you with data about the functionality of your system from a user perspective. While this view might seem restrictive, this information maps closely to issues that are actively affecting customers, so they are good candidates for alert triggers.

The alternative, **white-box monitoring** , is also incredibly useful. White-box monitoring describes any monitoring based on privileged, inside information about your infrastructure. Because the amount of internal processes vastly exceeds the externally visible behavior, you will likely have a much higher proportion of white-box data. And since it operates with more comprehensive information about your systems, white-box monitoring has the opportunity to be predictive. For instance, by tracking changes in resource use, it can notify you when you may need to scale certain services to meet new demand.

Black-box and white-box are merely ways of categorizing different types of perspectives into your system. Having access to white-box data, where the internals of your system are visible, is helpful in investigating issues, assessing root causes, and finding correlated factors when an issue is known or for normal administration purposes. Black-box monitoring, on the other hand, helps detect severe issues quickly by immediately demonstrating user impact.

## Matching Severity with Alert Type

Alerting and notifications are some of the most important parts of your monitoring system to get right. Without notifications about important changes, your team will either not be aware of events impacting your systems or will need to actively monitor your dashboards to stay informed. On the other hand, overly aggressive messaging with a high percentage of false positives, non-urgent events, or ambiguous messaging can do more harm than good.

In this section, we’ll talk about different tiers of notifications and how to best use each to maximize their effectiveness. Afterwards, we’ll discuss some criteria for choosing what to alert on and what the notification should accomplish.

### Pages

Starting with the highest priority alert type, **pages** are notifications that attempt to urgently call attention to a critical issue with the system. This category of alert should be used for situations that demand immediate resolution due to their severity. A reliable, aggressive way of reaching out to people with the responsibility and power to work on resolving the problem is required for the paging system.

Pages should be reserved for critical issues with your system. Because of the type of issues they represent, they are the most important alerts your system sends. Good paging systems are reliable, persistent, and aggressive enough that they cannot be reasonably ignored. To ensure a response, paging systems often include an option to notify a secondary person or group if the first page is not acknowledged within a certain amount of time.

Because pages are, by nature, incredibly disruptive, they should be used sparingly: only when it is clear that there is an operationally unacceptable problem. Often, this means that pages are tied to observed symptoms in your system using black-box techniques. While it might be difficult to determine the impact of a backend web host maxing out connections, the significance of your domain being unreachable is much less ambiguous and might demand a page.

### Secondary Notifications

Stepping down in severity are **notifications** like emails and tickets. These are designed to leave a persistent reminder that operators should investigate a developing situation when they are in a good position to do so. Unlike pages, notification-style alerts are not meant to indicate that immediate action is required, so they are typically handled by working staff rather than alerting an on-call employee. If your business does not have administrators working at all times, notifications should be aligned to situations that can wait until the next working day.

Tickets and emails generated by monitoring help teams understand the work they should be focusing on when they’re next active. Because notifications should not be used for critical issues currently affecting production, they are frequently based on white-box indicators that can predict or identify evolving issues that will need to be resolved soon.

Other times, notification alerts are set to monitor the same behavior as paging alerts, but set to lower, less critical thresholds. For instance, you might define a notification alert when your application is showing a small increase in latency over a period of time and have a corresponding page sent when the latency grows to an unreasonable amount.

In general, notifications are most appropriate in situations that require a response, but don’t pose an immediate threat to the stability of your system. In these cases, you want to bring awareness to an issue so that your team can investigate and mitigate _before_ it impacts users or transforms to a larger problem.

### Logging Information

While not technically an alert, sometimes you may wish to note specific observed behavior in a place you can easily access later without bringing it to anyone’s attention immediately. In these situations, setting up thresholds that will simply _log_ information can be useful. These can be written to a file or used to increment a counter on a dashboard within your monitoring system. The goal is to provide readily compiled information for investigative purposes to cut down on the number of queries operators must construct to gather information.

This strategy only makes sense for scenarios that are very low priority and need no response on their own. Their largest utility is correlating related factors and summarizing point-in-time data that can be referenced later as supplemental sources. You will probably not have many triggers of this type, but they might be useful in cases where you find yourself looking up the same data each time an issue comes up. Alternatives that provide some of the same benefits are saved queries and custom investigative dashboards.

## When To Avoid Alerting

It’s important to be clear on what alerts should indicate to your team. Each alert should signify that a problem is occurring that requires manual human action or input on a decision. Because of this focus, as you consider metrics to alert on, note any opportunities where reactions could be automated.

Automated remediation can be designed in cases where:

- A recognizable signature can reliably identify the problem
- The response will always be the same
- The response does not require any human input or decision making

Some responses are simpler to automate than others, but generally, any scenario that fits the above criteria can be scripted away. The response can still be tied to alert thresholds, but instead of sending a message to a person, the trigger can kick off the scripted remediation to solve the problem. Logging each time this occurs can provide valuable information about your system health and the effectiveness of your metric thresholds and automated measures.

It’s important to keep in mind that automated processes can experience problems as well. It is a good idea to add extra alerting to your scripted responses so that an operator is notified when automation fails. This way, a hands-off response will handle the majority of cases and your team will be notified of incidents that require intervention.

## Designing Effective Thresholds and Alerts

Now that we’ve covered the different alert mediums available and some of the scenarios that are appropriate for each, we can talk about the characteristics of good alerts.

### Triggered by Events with Real User Impact

As mentioned previously, alerts based on scenarios with real user impact are best. This means analyzing different failure or performance degrading scenarios and understanding how and when they may bubble up to layers that users interact with.

This requires a good understanding of your infrastructure redundancy, the relationship of different components, and your organization’s goals for availability and performance. Your aim is to discover the symptomatic metrics that can reliably indicate present or impending user-impacting problems.

### Thresholds with Graduated Severity

After you’ve identified symptomatic metrics, the next challenge is identifying the appropriate values to use as thresholds. You might have to use trial and error to discover the right thresholds for some metrics.

If available, check historic values to determine what scenarios required remediation in the past. For each metric, it’s good to define an “emergency” threshold that will trigger a page and one or several “canary” thresholds that are associated with lower priority messaging. After defining new alerts, ask for feedback on whether the thresholds were overly aggressive or not sensitive enough so that you can fine tune the system to best align to your team’s expectations.

### Contain Appropriate Context

Minimizing the time it takes for responders to begin investigating issues helps you recover from incidents faster. To this end, it is useful to try to provide context within the alert text so operators can understand the situation quickly and start working on appropriate next steps.

Alerts should clearly indicate the components and systems affected, the metric threshold that was triggered, and the time that the incident began. The alert should also provide links that can be used to get further information. These may be links to specific dashboards associated with the triggered metric, links to your ticketing system if automated tickets were generated, or links to your monitoring system’s alerts page where more detailed context is available.

The goal is to give the operator enough information to guide their initial response and help them focus on the incident at hand. Providing every piece of information you have about the event is neither required nor recommended, but giving basic details with a few options for where to go next can shorten the initial discovery phase of your response.

### Sent to the Right People

Alerts are not useful if they are not actionable. Often, whether an alert is actionable depends on the level of knowledge, experience, and permission that the responding individual has. For organizations of a certain size, deciding on the appropriate person or group to message is straightforward in some cases and ambiguous in others. Developing an on-call rotation for different teams and designing a concrete escalation plan can remove some of the ambiguity in these decisions.

The on-call rotations should include enough capable individuals to avoid burnout and alert fatigue. It is best if your alerting system includes a mechanism for scheduling on-call shifts, but if not, you can develop procedures to manually rotate the alert contacts based on your schedules. You may have multiple on-call rotations populated by the owners of specific parts of your systems.

An escalation plan is a second tool to make sure incidents go to the correct people. If you have staff covering your systems 24 hours a day, it is best to send alerts generated from the monitoring system to on-shift employees rather than the on-call rotation. The responders can then perform mitigation themselves or decide to manually page on-call operators if they need additional help or expertise. Having a plan that outlines when and how issues are escalated can minimize unnecessary alerts and preserve the sense of urgency that pages are meant to represent.

## Conclusion

In this guide, we’ve talked about how monitoring and alerting work in real systems. We began by looking at how the different parts of a monitoring system work to fulfill organizational needs for awareness and responsiveness. We discussed the difference between black- and white-box monitoring as a framework for thinking about different alerting cues. Afterwards, we discussed different types of alerts and how best to match incident severity with an appropriate alert medium. Lastly, we covered the characteristics of an effective alert process to help you design a system that increases your team’s responsiveness.
