#!/bin/bash

# Activate virtual environment
. /appenv/bin/activate

# Wait until DB service is ready
wait-for-it.sh db:3306 -s -t 10 -- echo 'db up'

exec $@

