---
title: DevOps in small companies – part I – configuration management
date: 2015-09-11T19:41:09+02:00
author: blelump
comments: true
layout: post
tags:
  - DevOps
  - Configuration management
  - Puppet
  - Ansible
---

So you are a team of 3--5 and run a small company. You are happy with that and so we are. As we are commited to our deliverables, we need to do our job smoothly. We need appropriate tools for the right time to let the business run (and to make money, right?). Altough our teams are small and resources are limited, we still can improve our velocity. It's actually inevitable if you want to stay on the market. Each such investment implies a non-zero cost, because of the learning curve etc. Thus it's essential to invest in something valuable, that would keep us on the front -- improve our throughput.

This set of posts aims to be somewhat a guideline of how to improve deliverables, by applying DevOps culture in a small company, or in particular -- the automation.

## Overview of current state

Did you hear about [the Joel test][1]? It's quite old from the IT point of view, but still valid. As a matter of fact, it's not an issue if you didn't, because it's somewhat a quality measurement, however very valuable, because it gives an overview of the current company state. So, how much points are you compliant with? Those twelve questions are the validator to help your business win so go and find them useful. Likewise, there are various aspects related to those questions and I'm going to touch some of them. In this case I mean managing the configuration.

## Where configuration meets automation

Well, automation of provisioning the environment is not a new topic, because people are doing it for years or perhaps even decades. Bash, Perl or Python were predecessors, but in the last few years the topic evolved vast. Actually, you're already at the gates of the Kingdom of Happiness even if you're doing it with simple Bash script, e.g. to install Nginx, configure firewall or whatever is needed to deliver your app. It is, because you have some configuration process that let's you provision the environment (or part of it) with reliability in any point of time.

As the above process remains valid, today we have some nicer toys to play with configuration, e.g. Chef, Puppet, Ansible, Salt or even Packer (it slightly [differs][2] from the others). These will help your company, because they push orchestration on completely new level of abstraction. OK, You'd say:

-- but I need only few tools to run my app -- why should I care?

-- read below.

![]({{ site.baseurl }}/static/img/20150911/mortal_kombat.jpg)

## The Kittens world

> Kittens are pets. Each cute little kitten has a name, get stroked every day, have special food and needs including "cuddles". Without constant attention your kittens will die. Common types of "kittens" are MSSQL databases, Sharepoint, Legacy apps and all Unix systems. Kitten class computing is expensive, stressful and time consuming.

Unfortunately, often these [Kittens][3] are our production environments, which in case of any failure, results in a huge blow--up. To give an example, imagine you're doing release upgrade on your Ubuntu LTS or just PostgreSQL version upgrade. Sure, you can put your app into maintenance mode and throw away all the users for a half day, but that's not the case these days. Some call this approach the [Phoenix Server Pattern][4] and some the [Immutable Deployments][5]. The point is to deliver profits with immutability. Instead of doing Ubuntu release upgrade, throw it away and provision new VM with latest release.

## Human failure

It's in our nature to make mistakes, however we can minimize them. Any process that brings some automation, also minimizes failure probability. Despite it's an investment, it's profitable.

In the Rubyist world, there's a tool called Bundler to manage dependencies. Bundler ensures that dependencies are consistent according to app needs. OSS world changes often and not always fluently to migrate from version X to Y. You need to manage these dependencies, e.g. to ensure version 1.2.3 of some dependency and 2.1.1 of some other. Bundler gives you extremely powerful engine to manage them and so CM tools give you the power to manage your environments. You always get the desired state.

## Build your environment

CM tools are somewhat like build tools, e.g. Maven or Gradle, but instead of getting the result as file or set of files, you get freshly baked environment. Baked according to the rules from Cookbooks (Chef), Manifests (Puppet) or Playbooks (Ansible).

Any of these tools also offer extra level of abstraction to ensure maximum flexibility, but yet, organized in some manner. Having a set of VM's, you can tell them to first configure some common context, e.g. a firewall or SSH, then a web--server, database, proxy or whatever is needed. For any given set of VM's, you get _the desired state_, with open ports 22 and 5432, but closed everything else. Then for any subset of these VM's, installed web--server or database. Any defined rule is applied where it's desired -- for a node (VM), set of nodes or even set of subset of nodes. It's all up to you how you manage it. There're some common patterns, e.g define roles (nodes), which include profiles (a set of rules to configure given tool, e.g. nginx). For Puppet it's [roles--profiles][6], whereas with Ansible it's somewhat enforced by default.

It's also worth noting that whatever rule you apply with desired CM tool, the applied rule is idempotent. It means that it will not apply firewall rules twice or more and mess with your setup, no matter how many times you'd apply that rule.

## Keep calm and scale

To some extent, it's just fine to scale vertically, however the cons are that it requires extra machine reboot and sometimes might be just a waste of resources utilization. On the other hand, to scale horizontally, it's essential to have new environment(s) prepared to the desired state. Sure, you'd use [the golden image][9] approach and scale just fine, but well, these days have passed. Just imagine a new library installation with golden image approach and you're off of this idea. CM tools give us much more flexibility to handle such cases.


## Where shall I start?

Before you'll start with anything, [these below][10] are your key points:

![]({{ site.baseurl }}/static/img/20150911/drawing.png)

In other words, gather requirements first. See how the business works and understand it, deeply. Now, blame me, but for me validation is just fine even if you do peer review as the underlying aim is not to overload ourselves. Then, finally, start playing with your desired tool. If you don't have any, yet, go and find whatever would be useful for you. I've used Puppet for some time, but switched to Ansible then, because of simplicity. Puppet has his own Ruby--based DSL to write manifests and is built upon master--agent pattern in its basis. However, it implies that each node needs Puppet--agent installed and set up SSL certs so that master and agents can talk to each other. For better node management, Puppet has some third party tools to better utilize his capabilities, e.g. Hiera to manage global environment config (e.g. to apply Ruby version 2.1 on a subset of nodes), or R10K to deal with any sort of environments (e.g. dev or production). There's one more caveat to Puppet, quite common actually -- because of Puppet design, if there isn't explicit rules (resources) hierarchy, Puppet would apply them in a random order, which may cause unexpected results. In order to prevent it, Puppet DSL implements dedicated ordering by setting [relationships][7] between resources.

Ansible Playbooks on the other hand are YAML--based and top--bottom applied rules. It means first rule in Playbook is applied first, then second, then third etc. Besides, Ansible doesn't implement master--agent architecture. Everything you need to run it on nodes is Python installed with `python-simplejson` library. I claim Ansible has also shorter learning curve according to Puppet, more modules supported by the Core team or just better docs. I've prepared simple Puppet vs. Ansible [comparison][8] (it needs Vagrant and VirtualBox) that simply configures SSH and firewall so you can play with both.

![]({{ site.baseurl }}/static/img/20150911/mortal_kombat2.png)

## Kill your Kitten and see what happen

The idea behind this post was to unveil that CM matters. Even if you're tiny player on the market and spinning new apache installation twice a year or doing whatever library upgrade ever less once in a while, it might be a valuable investment. Just after a few years, maintaining such Kitten becomes a pain, because no one ever remember what was there and what for. Keep your environments lean and auto--configurable and you'll notice the profit.


[1]: http://www.joelonsoftware.com/articles/fog0000000043.html
[2]: https://groups.google.com/forum/#!msg/packer-tool/4lB4OqhILF8/NPoMYeew0sEJ
[3]: http://etherealmind.com/cattle-vs-kittens-on-cloud-platforms-no-one-hears-the-kittens-dying/
[4]: https://www.thoughtworks.com/insights/blog/moving-to-phoenix-server-pattern-introduction
[5]: http://chadfowler.com/blog/2013/06/23/immutable-deployments/
[6]: https://techpunch.co.uk/development/how-to-build-a-puppet-repo-using-r10k-with-roles-and-profiles
[7]: https://docs.puppetlabs.com/puppet/3.8/reference/lang_relationships.html
[8]: https://github.com/blelump/garage
[9]: http://www.agilesysadmin.net/imaging-or-configuration-management
[10]: https://www.scriptrock.com/automation-enterprise-devops-doing-it-wrong