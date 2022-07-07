---
title: DevOps in small companies – part II – entering automation
date: 2016-01-14T17:24:53+01:00
author: blelump
comments: true
layout: post
tags:
  - DevOps
  - Configuration management
  - Automation
  - Ansible
  - Jenkins
  - Gerrit
---

A few months ago I've written [first post][1] in this series and it seems it's time to continue the discussion, because things didn't stop. Not at all.

The investment in configuration, or to be more specific, in automating things isn't free. It depends on many factors, obviously, and here it was a compromise between _what needs to be done_ and _what could be done_. In our case automation, configuration management (CM) or whatever in between was the second one. The world wouldn't end while not having CM solutions on board. Especially here, where we don't manage a farm of VM's in a cloud environment and to be honest, where any action could be done _manually_.

### Even though you manage even one simple VM, I'd automate this

During last months we've done a lot in case of automation. We've also learned a lot, I mean not only the new tools, but the two–words I'd call 'good practices' in case of the overall environment management. We manage about 10 VM's so it's not much and these are in private University cluster. We're not clouded with all of its pros and cons, but we try (or apply eventually) some cloud–solutions, e.g. we really value the cattle vs. kittens paradigm (covered in [first blog post][2] of this series).

Although we don't manage big clusters or clouds, we managed some good practices that apply in any environment. We believe that:

1. Any taken action closer to automation makes your environments less error–prone. It's insanely important in any environment, whether you have a huge cluster or a single VM, because tools works fine until someone touches it, right? If so, don't let anyone touch anything directly, automate it.
2. Any part of automated configuration is recreatable, repeatable, and so it's testable! You can test whatever you want in a way however you want to before putting it into production environment.
3. Any part of automated configuration can be reused and applied within any other environment. These are so–called roles and you can re–use them for any environment you'd like to provision.
4. Automation standarizes your environment, either a huge cluster or a single VM. It encourages you or any other person in the team to do things in a specific way, so any other person after any period of time can handle this. Whether edit some config of important tool or just add another package to the system, it all lies in one place.

### Automating things isn't free

Daily work still needs to be done, because automation isn't a top priority. Having said that, most of the CM–related work we've made during spare time. Week after week another components joined to the "automated WALL·E family". We've used Ansible as the CM–tool and I believe personally it was a good choice, because it simply let us do the job. We've also introduced a few tools to achieve simple CI and so we added Jenkins, which integrates with our Gerrit to perform code review so each Ansible change has been tested upon staging environment before merge into master branch. Furthermore, for any master branch merge, Gerrit triggered an event and so Jenkins would run production build. The complete process is shown below:

![]({{ site.baseurl }}/static/img/20160114/opensoftware_CI.png)

### However, running automated things, is so don't keep dinosaurs

Once you've built automated configuration, your environments are no more pets or dinosaurs. They're easily recreatable and configurable at scale if needed. However, the 'scale' word is not necessary here at all. Even having just a single VM, e.g. company developer tools VM, would be a good practice to [clean it up][3] and automate, because such VM's become dinosaurs fast. Once the toolset has been installed, it's better to not touch it at all, because who would ever remember why they're exist in a such way.

To give certain examples, we've entered automated configuration world and gather profits from:

* Standarization, where these old dinosaur–like VM's again became manageable.
* Changes testability, where each change can be tested before putting into prodution environment.
* Recreatable environments, so we can forget about VM major system upgrade and instead create exactly the same VM, but with newer environment version – this is so–called zero downtime migration.
* Monitoring things. It's a shame to say that, but we weren't monitor our services until that time. It's quite interesting what metrics could tell you about particular service or the whole system. I mean, among other things, counting or measuring requests response time for certain views (actually it's a topic for another blog post).
* ...each other, because all these configs, packages and other manageable things lie in one place and so anyone can enter the repository and see how exactly that thing has been performed or installed. It's all way more transparent.

Don't feel ashamed and start automating things today.

[1]: /2015/09/11/devops-in-small-companies-part-i/
[2]: /2015/09/11/devops-in-small-companies-part-i/#the-kittens-world
[3]: /2015/09/11/devops-in-small-companies-part-i/#where-shall-i-start
