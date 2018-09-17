#!/bin/bash

# Activate virtual environment
. /appenv/bin/activate

# Download requirements to build cache
pip download -d /build -r requirements_test.txt --no-input 

# Install application test requirements
pip install --no-index -f /build -r requirements_test.txt

# Run test.sh arguments
wait-for-it.sh db:3306 -s -t 5 -- echo 'db up'

exec $@
