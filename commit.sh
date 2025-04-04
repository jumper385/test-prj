#!/bin/bash

# zips up current directory
# scp to remote server
# unzips on remote server with repo
# pushes commit from repo to remote server

# options
# - commit
# - push
# - pull

# usage
# ./commit.sh commit "commit message"
# ./commit.sh push
# ./commit.sh pull <branch_name>

# configured with .env
# load .env file

ENV_FILEPATH=".env"

if [ ! -f $ENV_FILEPATH ]; then
    echo ".env file not found!"
    exit 1
fi

# load multiline .env file
# for each line in the file, export the variable
for line in $(cat $ENV_FILEPATH | grep -v '^#' | xargs); do
    export "$(echo "$line" | cut -d '=' -f 1)"="$(echo "$line" | cut -d '=' -f 2-)"
done

# check if required variables are set
if [ -z "$REMOTE_USER" ]; then
    echo "REMOTE_USER is not set in .env file"
    exit 1
fi
if [ -z "$REMOTE_HOST" ]; then
    echo "REMOTE_HOST is not set in .env file"
    exit 1
fi
if [ -z "$REPO_NAME" ]; then
    echo "REPO_NAME is not set in .env file"
    exit 1
fi

# check if required variables are set
# zip up the current directory in a tar.gz

# git add 
if [ -z "$1" ]; then
    echo "No argument provided"
    exit 1
fi

if [ "$1" == "upload" ]; then
    # upload the current directory to the remote server

    tar -czf ../$REPO_NAME.tar.gz . 
    # scp to remote server
    scp ../$REPO_NAME.tar.gz $REMOTE_USER@$REMOTE_HOST:~/
    ssh $REMOTE_USER@$REMOTE_HOST "mkdir -p ~/$REPO_NAME"
    ssh $REMOTE_USER@$REMOTE_HOST "tar -xf ~/$REPO_NAME.tar.gz -C ~/$REPO_NAME"
fi

# check if the first argument is add
if [ "$1" == "add" ]; then
    # check if the second argument is set
    if [ -z "$2" ]; then
        echo "No file or directory provided"
        exit 1
    fi
    # add the file or directory
    ssh $REMOTE_USER@$REMOTE_HOST "cd ~/$REPO_NAME && git add $2"
fi

# check if the first argument is commit
if [ "$1" == "commit" ]; then
    # check if the second argument is set
    if [ -z "$2" ]; then
        echo "No commit message provided"
        exit 1
    fi
    # commit the changes
    ssh $REMOTE_USER@$REMOTE_HOST "cd ~/$REPO_NAME && git commit -m '$2'"
fi

# check if the first argument is push
if [ "$1" == "push" ]; then
    # push the changes
    ssh $REMOTE_USER@$REMOTE_HOST "cd ~/$REPO_NAME && git push"
fi