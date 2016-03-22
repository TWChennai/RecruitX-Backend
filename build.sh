#!/usr/bin/env sh

set -e

MIX_ENV=test mix ecto.migrate
mix commit
