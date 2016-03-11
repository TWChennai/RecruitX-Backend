#!/usr/bin/env sh

set -e

if [ $# -eq 3 ]
then
  git remote rm $1
  git remote add $1 $2
  git push $1 $3:master --force
else
  echo "Usage: ./deploy.sh remote_name remote_url branch"
fi
