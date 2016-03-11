#!/usr/bin/env sh

# Run this after deploy.sh

set -e

if [ $# -eq 1 ]
then
  heroku run "mix ecto.migrate" --remote $1
else
  echo "Usage: ./migrate.sh remote_name"
fi
