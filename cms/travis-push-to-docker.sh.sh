#!/bin/bash

REPO="$DOCKER_USERNAME"/a-design-website-cms

echo "Choosing tag to upload to... (Branch: '$TRAVIS_BRANCH' | Tag: '$TRAVIS_TAG')"
if [ "$TRAVIS_BRANCH" == "master" ]; then
    DOCKER_PUSH_TAG=latest
elif [ "$TRAVIS_BRANCH" == "develop" ]; then
    DOCKER_PUSH_TAG=nightly
elif [ "$TRAVIS_TAG" != "" ]; then
    DOCKER_PUSH_TAG=$TRAVIS_TAG
else
    echo "Skipping deployment because it's neither master, develop or a versioned tag"
    exit 0;
fi

docker tag a-design-website-cms "$REPO":"$DOCKER_PUSH_TAG"
docker push "$REPO":"$DOCKER_PUSH_TAG"
