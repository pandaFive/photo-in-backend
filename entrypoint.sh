#!/bin/bash

set -e

rm -f /api/tmp/pids/server.pid

if [ "$RAILS_ENV" = "production" ]; then
  # bundle exec rails db:create
  # bundle exec rails db:migrate
fi

exec "$@"
