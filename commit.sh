#!/bin/bash

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

# download function abstraction
function download_and_unzip() {
    # download the current directory from the remote server
    # ignore .git directory
    ssh $REMOTE_USER@$REMOTE_HOST "cd ~/$REPO_NAME && tar -czf ../$REPO_NAME.tar.gz --exclude='.git *.tar.gz' ."
    scp $REMOTE_USER@$REMOTE_HOST:~/$REPO_NAME.tar.gz ../
    tar -xf ../$REPO_NAME.tar.gz
}

function zip_and_upload() {
    # zip the current directory
    tar -czf ../$REPO_NAME.tar.gz --exclude='.git *.tar.gz' .
    # upload to remote server
    scp ../$REPO_NAME.tar.gz $REMOTE_USER@$REMOTE_HOST:~/
}

function unzip_on_remote() {
    # unzip the file on remote server
    ssh $REMOTE_USER@$REMOTE_HOST "mkdir -p ~/$REPO_NAME"
    ssh $REMOTE_USER@$REMOTE_HOST "cd ~/$REPO_NAME && tar -xf ../$REPO_NAME.tar.gz"
}

function sync_remote() {
    zip_and_upload
    unzip_on_remote
} 

if [ "$1" == "upload" ]; then
    # upload the current directory to the remote server

    sync_remote
    download_and_unzip

# download from remote
elif [ "$1" == "download" ]; then
    download_and_unzip

elif [ "$1" == "commit" ]; then
    COMMIT_MESSAGE=$2
    # commit the changes to the remote server
    if [ -z "$COMMIT_MESSAGE" ]; then
        echo "Commit message is required"
        echo "e.g ./commit.sh commit 'your commit message'"
        exit 1
    fi

    # ssh to remote server and commit the changes
    ssh $REMOTE_USER@$REMOTE_HOST "cd ~/$REPO_NAME && git commit -m '$COMMIT_MESSAGE'"

elif [ "$1" == "add" ]; then
    sync_remote
    ssh $REMOTE_USER@$REMOTE_HOST "cd ~/$REPO_NAME && git $@"

elif [ "$1" == "status" ]; then
    sync_remote
    ssh $REMOTE_USER@$REMOTE_HOST "cd ~/$REPO_NAME && git $@"

elif [ "$1" == "diff" ]; then
    sync_remote
    ssh $REMOTE_USER@$REMOTE_HOST "cd ~/$REPO_NAME && git $@"

# pull
elif [ "$1" == "pull" ]; then
    # pull the changes from the remote server
    ssh $REMOTE_USER@$REMOTE_HOST "cd ~/$REPO_NAME && git pull"
    # then copy the changes to the local machine
    download_and_unzip

else

    ssh $REMOTE_USER@$REMOTE_HOST "cd ~/$REPO_NAME && git $@"

fi