#!/bin/sh

yes | mix do deps.get, deps.compile
mix release --env=prod --verbose
