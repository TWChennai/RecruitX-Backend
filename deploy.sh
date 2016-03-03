#!/usr/bin/env sh

if [ -n "$1" -a -n "$2" ]
then
  git ls-remote --exit-code $1 &> /dev/null
  if [ $? -ne 0 ]
  then
    # create remote if not exists
    git remote add $1 $2
    echo "Added remote - $1"
  fi
  # deploy and migrate
  git push $1 master
  heroku run mix ecto.migrate --remote $1
else
  echo "Usage: ./deploy.sh remote_name URL"
fi
