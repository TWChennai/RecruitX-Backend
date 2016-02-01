#!/usr/bin/env sh

# From: https://github.com/HashNuke/ansible-elixir-stack
export MIX_ENV=prod
ansible-playbook playbooks/migrate.yml
ansible-playbook playbooks/deploy.yml
