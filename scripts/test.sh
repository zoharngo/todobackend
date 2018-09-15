#!/bin/bash

# Activate virtual environment
. /appenv/bin/activate

# Install application test requirements_test.txt
pip install -r requirements_test.txt

# Run test.sh arguments
wait-for-it.sh db:3306 -s -t 5 -- echo 'db up'

exec $@
