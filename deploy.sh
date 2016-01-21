#!/usr/bin/env sh

# From: https://github.com/HashNuke/ansible-elixir-stack
ansible-playbook playbooks/deploy.yml
/home/deployer/projects/recruitx_backend/rel/recruitx_backend/bin/recruitx_backend upgrade "0.0.8-$(git rev-parse --short HEAD)"
