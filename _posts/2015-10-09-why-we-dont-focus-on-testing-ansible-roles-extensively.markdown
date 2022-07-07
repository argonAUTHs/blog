---
title: Why we don't focus on testing Ansible roles extensively
date: 2015-10-09T21:06:51+02:00
author: blelump
comments: true
layout: post
tags:
  - DevOps
  - Continuous integration
  - Ansible
  - Docker
  - Jenkins
  - test–kitchen
---

We provision our environments with Ansible and we want these to be super–reliable. However, having sometimes several daily deployments, how to ensure that any change will not ruin the production environment? Some whisper to move to the containers world and get rid of the traditional way of provisioning/maintaining environments. Here, in the middle of major Ops changes, we use private cluster working on bare metal and so, we have slightly different requirements than the cloud world. We don't use containers everywhere and we don't have a plan to do so, at least within apps related context. As we provision with Ansible we want to be sure that any change will not cause any environment outage.

Testing any CM tool is not a trivial task, because they essentially need an isolated environment to fire tests. It's not just a matter of amount of RAM or CPU cycles, but primarily of having the dedicated environment the services need to operate. Moreover, as we use private cluster whereas we don't manage it, we have just a bunch of VM's we can use in whatever manner is needed, but still without any easy way to drop or spin up new VM.

# Testing Ansible changes

The Ansible tool marvelously implements [roles–profiles][2] pattern, which give us the ability to test any particular service in isolation – let's call it as a service unit test. In Ansible terms, any service is simply a role that delivers some set of commands to ensure that service is up and running. Here, we can distinguish certain test levels criteria:

1. Service is up and running on localhost.
2. Service talks to authorized clients.
3. Service delivers appropriate content.

Testing the first level is often met by the role itself and since you'd use something out of the box, you've it included. Ansible has a bunch of predefined modules and another tons within Ansible Galaxy maintained by the vast community. Actually it's very likely any tool you'd imagine to use has already well–prepared role ready for deployment.

The next levels of tests are completely up to you, but you'd probably find, that it's getting complicated fast, even for a small change, e.g. adding another web–VM instance within `hba.conf` file to get access to PostgreSQL database. So we started to consider of having a CI for infrastructure provisioner, where:

1. The cost of environment preparation is relatively small.
2. Time of execution is as minimized as possible.

Having these assumptions defined, consider the schema below:

![]({{ site.baseurl }}/static/img/20151009/ansible_ci.png)

In short, when developer commits new change to Gerrit, Jenkins triggers new job for [test–kitchen][3] gem, which internally spawns Docker container(s) to perform change tests. Gem test–kitchen is able to establish more containers at once and run tests concurrently. To distinguish what roles have changed per commit:

{% highlight bash %}
git diff-tree --no-commit-id --name-only -r COMMIT_ID | grep -e 'roles\/'
{% endhighlight %}

I've built an [example][4] of how to use test–kitchen with predefined Docker image where tests run in a matter of seconds. It really works great, but in context of role, not the whole system. The awesomeness disappear when you realize it's not what you wanted to achieve, because in case of Ops – in my opinion – it's more important to focus on integration tests to provide more customer oriented environment, e.g. at least to test if given service is running or responding instead of focusing if directory exists or config has changed.

Indeed, if tests run per each role, it's easy to spin up test environments and run tests fast thanks to containers. Such tests, however, have the drawback that they don't give the value you'd expect – each role provides some service, but testing such single service without interaction with other services is quite meaningless. Nginx won't serve appropriate content without interaction with some webserver and so, webserver won't serve appropriate content without some database and so on.

On the other hand, blending all Docker–Jenkins–whatever tools to build CI just for testing for Nginx availability on port 80 is like using a sledgehammer to crack a nut. So we decided to discontinue such process, because of the overhead of preparation test environments to gain valuable results.


# The good the bad and the ugly

Nonetheless, the idea of role–oriented tests is definitely worth looking at. With some investment in scripting and perhaps Docker Compose on board, it would spin the environment with services talking to each other, but it's still an overhead to deal with. Besides, there're also Docker containers limitations regarding changes in container networking or firewall (need extra `--privileged` mode) and so they also should be discussed before entering containers.

As for our CI environment, so far we've ended up with testing Ansible changes using flags `--syntax-check --check` on appropriate playbook from within Jenkins job and doing peer review.

[2]: http://garylarizza.com/blog/2014/02/17/puppet-workflow-part-2/
[3]: https://github.com/test-kitchen/test-kitchen
[4]: https://github.com/blelump/garage/tree/master/ansible_docker_test_kitchen
