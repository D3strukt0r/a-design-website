#!/bin/sh

set -e

# export SCRIPT_NAME=/ping
export SCRIPT_NAME=/
# export SCRIPT_FILENAME=/ping
export SCRIPT_FILENAME=/
export REQUEST_METHOD=GET

if cgi-fcgi -bind -connect 127.0.0.1:9000; then
    exit 0
else
    exit 1
fi
