---
title: "First solution isn't always the smartest – a few thoughts about using Ansible"
date: 2015-11-30T12:23:14+01:00
author: blelump
comments: true
layout: post
tags:
  - Ansible
  - Configuration Management
---

Basically, this post is a continuation of [Why we don't focus on testing Ansible roles extensively][2] and essentially touches [Ansible][1] and expands, among other things, a few thoughts about using this tool within a CI environment.

## The problem: execution time of Ansible playbook takes too long

#### The context
Having a set of VM's and several roles to execute, I've started to think how to shorten the execution time within the cluster.

#### First solution – extract and execute only the code that's been changed
As we use here a CI for Ansible, the first idea was to execute only the role that's been changed. It sounds quite reasonable, because only concrete piece of playbook lifecycle is executed, without touching all the rest, unchanged. However, it works smootly until it concerns internal roles.
Let me explain the current solution for staging environment. What's executed after a change is being pushed into repository, is distinguished with a piece of Bash script:

{% highlight bash %}
tags=`git show --pretty="format:" --name-only $GIT_COMMIT | grep -v 'roles/requirements.yml' | grep -e 'roles\/' | awk -F "/" '{print $2}' | paste -sd "," -`
if ! [ -z "$tags" ]; then
  echo "Running for tags: $tags"
  ansible-playbook --tags="$tags" -i staging_inv site.yml
else
  # Execute all stuff
  ansible-playbook -i staging_inv site.yml
fi
{% endhighlight %}

In particular, it extracts what's been changed from a Git tree and enforces to run build for concrete tags. These tags match role names, e.g. if any file of role _common_ has been changed, build executes only for role _common_. Unfortunately, it shines until you add an external role. Given that, lets say the main directory playbook structure looks like:
{% highlight bash %}
$ tree ./ -L  1
├── ansible.cfg
├── files
├── group_vars
├── host_vars
├── roles
│   ├── ...
│   ├── requirements.yml
├── site.yml
└── staging_inv
{% endhighlight %}

When you add an external role, what you do – in most cases – is extending _*vars_ with some configuration variables related to the role and that's all. It provides great flexibility for including additional roles, however it also reduces the possibility of extraction only certain roles to execute (based on the piece of code showed above). For such _nginx_ external role example, you'd only need to add some variables related to the role so the above extraction script wouldn't match any code from within roles directory and hence, peform all tasks defined within a playbook.

#### Second solution – build a wrapper role

Any Ansible role may depend on any other role, where dependent roles are executed first. Role dependencies are given within host role _meta/main.yml_:
{% highlight yaml %}
---
dependencies:
  - ansible-role-nginx
{% endhighlight %}

The host role (one that's having dependencies) would provide all essential variables for the dependent roles and it plays nicely. Basically, the nginx wrapper role looks like:
{% highlight bash %}
$ tree ./roles/nginx/ -L 1
├── defaults
├── meta
├── tasks
└── vars
{% endhighlight %}

where _vars_ provide common variables for _ansible-role-nginx_ role. The _common_ word is on purpose, because what if you'd like to deliver configuration for several nginx instances, where each instance differs slightly (e.g. is having different SSL cert)? The whole wrapper role plan crashes, because it needs to be distinguished somehow what plays where, so the solution would likely to use either _group_ or *host_ vars*, whereas the extraction script doesn't know anything about these directories (because they reside within playbook main dir).

However, there's a light for such approach, I mean using wrapper roles:

1. _nginx_ role–case is quite unusual. In most cases it will be sufficient to use wrapper role _vars_ and define essential variables there.
2. External role common code has his own isolated environment with the ability to test it, using the above Bash script.
3. Wrapper role may include additional tasks and these are applied right after all dependent roles are applied. However, to apply pre–role tasks, different approach is needed.

## The problem – applying pre–role tasks for certain role

#### The context

The current design of applying pre or post tasks of certain roles is limited to concrete [pre/post tasks][3] defined within a playbook. Such approach, however, implies that playbook becomes both, the declaration and definition of roles and tasks, which sounds like a straight way of having a speghetti code.

#### Everything should be roleized

Because it keeps your code clean and readable, no matter whether it's a bunch of tasks or just one that creates a directory. Be consistent in what you do and that will cause profits. Instead of adding _pre\_tasks_ to your playbook, create another role, e.g. _pre-nginx_ that simply creates cache directory or whatever is needed before role is executed.


## The problem – complex role configuration and staying DRY

#### The context

Lets say you have [nginx][6] role on board and it manages many Nginx instances. Some of them need various SSL certs or are working with different application servers. How to manage that and stay DRY?

#### Cheat with Jinja2 features

Ansible uses YAML language for tasks definition and despite its simplicity, it has some limitations (e.g. config inheritance). Here comes [Jinja2][5] template language that would help in such cases. Let me explain it on an example, e.g. with this [nginx][6] role. The role is used upon the wrapper role pattern described above and contains:
{% highlight yaml %}
# meta/main.yml
---
dependencies:
  - ansible-role-nginx

# vars/main.yml
---

common_conf: |
  index index.html;

  location /favicon.ico {
    return 204;
    access_log     off;
    log_not_found  off;
  }

  location /robots.txt {
    alias {{ root_dir }};
  }

  ...

nginx_configs:
  ssl:
    - ssl_certificate_key {{ssl_certs_path}}/cert.key
    - ssl_certificate     {{ssl_certs_path}}/cert.pem
  upstream:
    - upstream {{ upstream }}

nginx_http_params:
  - proxy_cache_path  /var/www/nginx-cache/  levels=1:2 keys_zone=one:10m inactive=7d  max_size=200m
  - proxy_temp_path   /var/www/nginx-tmp/
{% endhighlight %}

Then, for a concrete host or group vars of your inventory, specify final configuration. Lets say you have _foo_ app and you'd like to provide config for _bar_ host that reside within your inventory file. Given that:
{% highlight yaml %}
# host_vars/bar/nginx.yml
---
root_dir: /var/www/foo/public/
location_app: |
  proxy_pass http://some_cluster;
  proxy_set_header X-Accel-Buffering no;
  ...

{% raw %}
location_app_https:
  - "{{ location_app }}"
  - proxy_set_header X-Forwarded-Proto https;

app_common_conf: |
  server_name bar.example.com;
  root {{ root_dir }};

  location / {
    try_files $uri $uri/index.html $uri.html @app;
  }
nginx_sites:
  status:
    - listen 80
    - server_name 127.0.0.1
    - location /status { allow 127.0.0.1; deny all; stub_status on; }
  app:
    - listen 80
    - "{{ common_conf }}"
    - "{{app_common_conf}}"
    - |
      location @app {
        {{ location_app }}
      }
  app_ssl:
    - listen 443 ssl
    - "{{common_conf}}"
    - "{{app_common_conf}}"
    - |
      location @app {
        {{ location_app_https | join(" ") }}
      }

{% endraw %}
upstream:
  some_cluster { server unix:/var/www/foo/tmp/sockets/unicorn.sock fail_timeout=0; }
{% endhighlight %}

And certs file, encrypted with _ansible-vault_ is given as:

{% highlight yaml %}
# host_vars/bar/cert.yml
---
ssl_certs_privkey: |
  -----BEGIN CERTIFICATE-----
  ...
  -----END CERTIFICATE-----

ssl_certs_cert: |
  -----BEGIN PRIVATE KEY-----
  ...
  -----END PRIVATE KEY-----
{% endhighlight %}

The [nginx][6] role doesn't install SSL certs itself so it's up to you how and where you'd like to put them. However, it might be simply achieved with these tasks, applied before nginx role:
{% highlight yaml %}
{% raw %}
- name: Ensure SSL folder exist
  file: >
    path={{ssl_certs_path}}
    state=directory
    owner="{{ssl_certs_path_owner}}"
    group="{{ssl_certs_path_group}}"
    mode=700

- name: Provide nginx SSL cert.pem
  copy: >
    content="{{ ssl_certs_privkey }}"
    dest={{ssl_certs_path}}/cert.pem
    owner="{{ssl_certs_path_owner}}"
    group="{{ssl_certs_path_group}}"
    mode=700

- name: Provide nginx SSL cert.key
  copy: >
    content="{{ ssl_certs_cert }}"
    dest={{ssl_certs_path}}/cert.key
    owner="{{ssl_certs_path_owner}}"
    group="{{ssl_certs_path_group}}"
    mode=700
{% endraw %}
{% endhighlight %}

Note the difference between _\>_ and _\|_ in YAML. The former is the folded style and means that any newline in YAML will be replaced with space character, whereas the latter preserves newline character.

[Jinja2][5] templates in conjunction of YAML features, provide great flexibility in config definition. However, as of Ansible 2.0, it's likely that it will change slightly, because it will be possible to use Jinja2 [combine][7] feature for merging hashes.

[1]: http://www.ansible.com/
[2]: 2015/10/09/why-we-dont-focus-on-testing-ansible-roles-extensively/
[3]: http://docs.ansible.com/ansible/playbooks_roles.html#roles
[4]: https://github.com/ansible/ansible/issues/13228
[5]: http://docs.ansible.com/ansible/playbooks_filters.html
[6]: https://github.com/jdauphant/ansible-role-nginx
[7]: http://docs.ansible.com/ansible/playbooks_filters.html#combining-hashes-dictionaries
