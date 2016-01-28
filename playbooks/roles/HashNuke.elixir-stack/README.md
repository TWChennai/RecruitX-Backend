# ansible-elixir-stack

Tool to deploy [Elixir](http://elixir-lang.org/) & [Phoenix](http://www.phoenixframework.org) apps to servers.

**Docs**: [[Configuration](docs/configuration.md)], [[Hot code-reloading](docs/hot-code-reloading.md)], [[prod.secret.exs file](docs/prod-secret-file.md)], [[Logs](docs/logs.md)]

## Features

* **1-command setup & deploys**
* Ships with Postgres support
* Automatically creates a [`prod.secret.exs`](docs/prod-secret-file.md) file
* Deploy multiple hobby apps on a $5 DigitalOcean server
* Custom domains
* Hot code-reloading using [exrm](https://github.com/bitwalker/exrm)
* Monitoring & automatic restarts using `monit`
* Organized as an Ansible role, BUT requires no knowledge of Ansible

> To deploy to Heroku, use the [Heroku Elixir buildpack](https://github.com/HashNuke/heroku-buildpack-elixir) instead.

## Install

```sh
$ pip install ansible
$ cd to/your/project/dir
$ mkdir playbooks
$ cd playbooks
$ wget https://raw.githubusercontent.com/arunvelsriram/ansible-elixir-stack/master/ansible_requirements.yml
$ ansible-galaxy install -p roles -r ansible_requirements.yml

# assuming your SSH key is called `id_rsa`
# run this everytime you start your computer
$ ssh-add ~/.ssh/id_rsa
```

> If the above commands fail, try with `sudo`.
> For Mac OS X, Ansible is also available on homebrew.

## Setup your project

1.) Add [exrm](https://github.com/bitwalker/exrm) as your project's dependency in mix.exs

```elixir
defp deps do
  [{:exrm, "~> 0.18.1"}]
end
```

2.) Move `elixir-stack.sh` in to your project's root directory

```sh
$ cd your_project/
$ mv playbooks/roles/ansible_elixir_stack/elixir-stack.sh elixir-stack.sh
```

3.) Edit remote_user, add your server's IP addresses in `elixir-stack.sh`.

4.) Run the script

```sh
$ sh elixir-stack.sh
```

**FOLLOW INSTRUCTIONS GIVEN BY ABOVE COMMAND**

> Checkout the [documentation on configuration options](docs/configuration.md)

## Deploy your project

Assuming you have root SSH access to the server

##### To deploy the first time

```sh
$ ansible-playbook playbooks/setup.yml
```

##### To update your project

```sh
$ ansible-playbook playbooks/deploy.yml
```

> By default the application is restarted on each deploy. [Read how to enable hot code-reloading](docs/hot-code-reloading.md).

## Problems you might face  
**postgresql repo for different Ubuntu versions**  

In `tasks/postgres.yml`
  * use `apt_repository: repo="deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main"` for precise.
  * use `apt_repository: repo="deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main"` for trusty.  


**rebar installation failure**  

Sometimes the default mirror will not respond. So use a different mirror for installing rebar.  

In `tasls/project.yml` add `command: bash -lc "mix hex.config cdn_url https://s3-ap-southeast-1.amazonaws.com/s3.hex.pm/installs/1.0.0/rebar-2.3.1"` under `install rebar` task.

## FAQ

* **Is this only meant for small $5 servers?**  
Should fit servers of any size. In that case you could also increase the swap and npm

* **How to have different set of servers for staging and production?**  
Use the `inventory` file as a template and maintain different inventory files for staging and production. Let's say your staging inventory file is called `staging.inventory`, then you could do `ansible-playbook setup.yml -i staging.inventory` (and similar for deploy). Notice the `-i` switch.
*B/w if you are going this way, you probably should learn Ansible or hire someone who knows it*


## Misc

* [ansible-galaxy guide](http://docs.ansible.com/galaxy.html#installing-roles)
