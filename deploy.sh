#!/usr/bin/env sh

# From: https://github.com/HashNuke/ansible-elixir-stack
ansible-playbook playbooks/deploy.yml

# TODO: Due to a bug in the ansible-playbook, we need to explicitly restart the service outside it
# TODO: Hard-coded location of the elixir app-executable on the target machine - try to remove hardcoding
sudo /home/deployer/projects/recruitx_backend/rel/recruitx_backend/bin/recruitx_backend stop
sudo /home/deployer/projects/recruitx_backend/rel/recruitx_backend/bin/recruitx_backend start
