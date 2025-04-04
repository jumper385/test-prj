#!/bin/bash

# Check if the .env file exists
ENV_FILEPATH=".env"
if [ ! -f $ENV_FILEPATH ]; then
    # if not, create it
    echo ".env file not found! Creating a new one."
    touch $ENV_FILEPATH
    echo "REMOTE_HOST=172.105.254.131" >> $ENV_FILEPATH
    echo "REPO_NAME=test-prj" >> $ENV_FILEPATH
fi

# load multiline .env file
# for each line in the file, export the variable
for line in $(cat $ENV_FILEPATH | grep -v '^#' | xargs); do
    export "$(echo "$line" | cut -d '=' -f 1)"="$(echo "$line" | cut -d '=' -f 2-)"
done

# check if required variables are set
if [ -z "$REMOTE_HOST" ]; then
    echo "REMOTE_HOST is not set in .env file"
    exit 1
fi

if [ -z "$REMOTE_USER" ]; then
    # prompt for remote username
    read -p "Enter remote username: " REMOTE_USER
    # write to .env file
    echo "REMOTE_USER=$REMOTE_USER" >> $ENV_FILEPATH
fi