#!/usr/bin/env sh

# From: https://github.com/HashNuke/ansible-elixir-stack
ansible-playbook playbooks/deploy.yml
sudo /home/deployer/projects/recruitx_backend/rel/recruitx_backend/bin/recruitx_backend stop
sudo /home/deployer/projects/recruitx_backend/rel/recruitx_backend/bin/recruitx_backend start
