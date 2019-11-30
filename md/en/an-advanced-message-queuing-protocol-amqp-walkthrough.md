---
author: O.S Tezer
date: 2013-12-23
language: en
license: cc by-nc-sa
source: https://www.digitalocean.com/community/tutorials/an-advanced-message-queuing-protocol-amqp-walkthrough
---

# An Advanced Message Queuing Protocol (AMQP) Walkthrough

## Introduction

* * *

In contrast with their closed-source counterparts, open-source applications are free, relatively fast, and have strong development cycles combined with readily available community support. This makes them very strong alternatives tor many developers, product managers, and general users when it comes to making long term choices.

One of the key elements that provide success to community developed applications (i.e. having a lot of people working on one or more interworking projects) is commonly agreed upon grounds during the process of continuous development– what makes applications usable is mostly their ability to _talk_ with each other and work together.

In this DigitalOcean article, we are going to try something new and help developers (and anyone else interested) get thoroughly familiar with the **Advanced Message Queueing Protocol**. It’s an open [technical] standard (_a common ground_) designed to allow development of applications which are tailored to work as middleware in brokering of messages between different processes, applications, or even unrelated systems that need to talk to each other and pass on messages.

## What are Technical Standards and Open Standards?

* * *

### Technical Standards

* * *

Technical standards consist of rules, norms, definitions etc. for the development and usage of applications and other technical systems powering them. They are made of well-defined methods and processes to act as theoretical frameworks.

### Open Standards

* * *

In the domain of technical systems, open standards are instructions which can be adapted and used - _royalty-free_ - for the implementation and development of applications. Depending on the body developing them, open standards can be created and maintained by an “open body” through an “open process”.

## What is Open System Interconnection?

* * *

Open System Interconnection (OSI) is an ISO (International Organization for Standardization) standard which was developed in the 1970s to “homogenize” the way different networks - and therefore computer systems communicating through them - work together.

This standard constitutes of a framework (i.e. a base to develop on) created to implement communication protocols in seven successive layers:

1. **Physical Layer** - forms the physical (i.e. hardware) base for OSI to work.

2. **Data Link Layer** - transfers the data between network [nodes].

3. **Network Layer** - directs the traffic (i.e. forwarding) between places.

4. **Transport Layer** - works to ensure reliability, data flow (i.e. rate) control and its stream.

5. **Session Layer** - responsible of managing the session between applications.

6. **Presentation (Syntax) Layer** - working to shape and present the data to be processed.

7. **Application Layer** - setting and ensuring common grounds - reaching the applications - for communication. (This is where AMQP lives!)

## What is Application Layer?

* * *

Application layer - which is where AMQP lives - is one of the above pieces forming the Open System Interconnection standard. If we were to elaborate, application layer can be thought of as the [only] one that users interact with and as the one which defines how process-to-process (or application to application) communications take place.

Some [common] examples to application layer - other than AMQP - would be:

- IRC
- DNS
- FTP
- IMAP
- SSH
- and more.

## What are Communication Protocols?

* * *

Each communication protocol is made of rules and regulations clearly defined to form a shared language spoken between different application with the end result of being able to communicate regardless how they might be originally set to work.

These protocols have elements such as data formats, definition of parties using the protocol, routings and flow (rate) control.

## What is Advanced Message Queuing Protocol?

* * *

The Advanced Message Queuing Protocol (AMQP) creates interoperability between clients and brokers (i.e. messaging middleware). Its goal of creation was to enable a wide range of different applications and systems to be able to work together, regardless of their internal designs, standardizing enterprise messaging on industrial scale.

AMQP includes the definitions for both the way networking takes place and the way message broker applications work. This means the specifications for:

- Operations of routing and storage of messages with the message brokers and set of rules to define how components involved work

- And a wire protocol to implement how communications between the clients and the brokers performing the above operations work

## Reasons for AMQP’s Creation and Use

* * *

Before AMQP, there used to be different message brokering and transferring applications created and set in use by different vendors. However, they had one big problem and it was their lack of interoperability. There was simply not a way for one to work with another. The only method that could be used to get different systems using different protocols to work was by introducing an additional layer for converting messages called _messaging bridge_. These systems, using individual adapters to be able to receive messages like regular clients, would be used to connect multiple and different messaging systems (e.g. WebSphere MQ and another).

AMQP, by offering the clearly defined rules and instructions as we explained above, creates a common ground which can be used for all message queuing and brokering applications to work and interoperate.

## What are AMQP Use Cases?

* * *

Whenever there is a need for high-quality and safe delivery of messages between applications and processes, AMQP implementing message brokering solutions can be considered for use.

### AMQP ensures

* * *

- Reliability of message deliveries

- Rapid and ensured delivery of messages

- Message acknowledgements

### These capabilities make it ideal for

* * *

- Monitoring and globally sharing updates

- Connecting different systems to talks to each other

- Allowing servers to respond to immediate requests quickly and delegate time consuming tasks for later processing

- Distributing a message to multiple recipients for consumption

- Enabling offline clients to fetch data at a later time

- Introducing fully asynchronous functionality for systems

- Increasing reliability and uptime of application deployments

## AMQP Assembly and Terminology

* * *

Understanding and working with AMQP involves being familiar with quite a few different terms and terminology. In this section, we will go over these key parts:

- **Broker (Server):** An application - implementing the AMQP model - that accepts connections from clients for message routing, queuing etc.

- **Message:** Content of data transferred / routed including information such as payload and message attributes.

- **Consumer:** An application which receives message(s) - put by a producer - from queues.

- **Producer:** An application which put messages to a queue via an exchange.

**Note:** The payload of messages are not defined by the AMQP; various and differing types of data, therefore, can be transferred using the protocol.

## Main AMQP Components

* * *

The AMQP Model defining how messages are received, routed, stored, queued and how application parts handling these tasks work rely on the clear set definitions of the below components:

- **Exchange:** A part of the broker (i.e. server) which receives messages and routes them to _queues_

- **Queue (message queue):** A named entity which messages are associated with and from where consumers receive them

- **Bindings:** Rules for distributing messages from exchanges to queues

## How Do AMQP Message Brokers Work?

* * *

In AMQP, “message brokers” translate to applications which receive the actual messages and route (i.e. transfer) them to relevant parties.

    APPLICATION EXCHANGE TASK LIST WORKER
       [DATA] -------> [DATA] ---> [D]+[D][D][D] ---> [DATA]
     Publisher EXCHANGE Queue Consumer

## How does AMQP Exchanges Work?

* * *

After receiving messages from publishers (i.e. clients), the exchanges process them and route them to one or more queues. The type of routing performed depend on the type of the exchange and there are currently four of them.

### Direct Exchange

* * *

Direct exchange type involves the delivery of messages to queues based on routing keys. Routing keys can be considered as additional data defined to set where a message will go.

Typical use case for direct exchange is load balancing tasks in a round-robin way between workers.

### Fanout Exchange

* * *

Fanout exchange completely ignores the routing key and sends any message to all the queues bound to it.

Use cases for fanout exchanges usually involve distribution of a message to multiple clients for purposes similar to notifications:

- Sharing of messages (e.g. chat servers) and updates (e.g. news)

- Application states (e.g. configurations)

### Topic Exchange

* * *

Topic exchange is mainly used for pub/sub (publish-subscribe) patterns. Using this type of transferring, a routing key alongside binding of queues to exchanges are used to match and send messages.

Whenever a specialized involvement of a consumer is necessary (such as a single working set to perform a certain type of actions), topic exchange comes in handy to distribute messages accordingly based on keys and patterns.

### Headers Exchange

* * *

Headers exchange constitutes of using additional headers (i.e. message attributes) coupled with messages instead of depending on routing keys for routing to queues.

Being able to use types of data other than strings (which are what routing keys are), headers exchange allow differing routing mechanism with more possibilities but similar to direct exchange through keys.

## How Does AMQP Message Brokering Differ From E-Mailing?

* * *

Given that mailing consists of sending of a message (i.e. publishing), its reception and processing by the mail server (i.e. brokering) to relevant mailboxes (i.e. queues) finally followed by requesting and obtaining the said message (i.e. consuming), the process and the task of transferring messages defined by AMQP can be seen as similar.

Besides the fundamentals actually differing quite a bit, the main thing that separates AMQP from e-mailing is the targeted Quality of Service (QoS). AMQP, by its nature, strives for reliability, security, standards compliance and safety.

Features such as persistence, delivery of a message to multiple consumers, possibility to ensure and prevent multiple consumption, and the protocol operating at high-speeds are the main factors separating the two.

For business-level usage and adaption, the requirements for authentication to sending messages (i.e. publishing) to exchanges (and queues) means prevention of unwanted ones (such as spam), playing a key role for establishing the QoS.

Submitted by: [O.S. Tezer](https://twitter.com/ostezer)
