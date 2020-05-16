#!/bin/bash

# Login to make sure we have access to private dockers
if [[ -v DOCKER_PASSWORD && -v DOCKER_USERNAME ]]; then
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
else
    echo "No login information available"
    exit 0;
fi

# Build
REPO_PHP="$DOCKER_USERNAME"/a-design-cms-php
REPO_PHP_LOCAL=a-design-cms-php
if [[ "$TRAVIS_BRANCH" == "master" ]]; then
	docker build --target php --build-arg dev="--no-dev" -t "$REPO_PHP_LOCAL":latest .
elif [[ "$TRAVIS_BRANCH" == "develop" ]]; then
	docker build --target php --build-arg dev="" -t "$REPO_PHP_LOCAL":latest .
elif [[ "$TRAVIS_TAG" != "" ]]; then
	docker build --target php --build-arg dev="--no-dev" -t "$REPO_PHP_LOCAL":latest .
else
    echo "Skipping deployment because it's neither master, develop or a versioned tag"
    exit 0;
fi

REPO_NGINX="$DOCKER_USERNAME"/a-design-cms-nginx
REPO_NGINX_LOCAL=a-design-cms-nginx
docker build --target nginx -t "$REPO_NGINX_LOCAL":latest .

# Upload
echo "Choosing tag to upload to... (Branch: '$TRAVIS_BRANCH' | Tag: '$TRAVIS_TAG')"
if [[ "$TRAVIS_BRANCH" == "master" ]]; then
    DOCKER_PUSH_TAG=latest
elif [[ "$TRAVIS_BRANCH" == "develop" ]]; then
    DOCKER_PUSH_TAG=nightly
elif [[ "$TRAVIS_TAG" != "" ]]; then
    DOCKER_PUSH_TAG=$TRAVIS_TAG
else
    echo "Skipping deployment because it's neither master, develop or a versioned tag"
    exit 0;
fi

docker tag "$REPO_PHP_LOCAL" "$REPO_PHP":"$DOCKER_PUSH_TAG"
docker push "$REPO_PHP":"$DOCKER_PUSH_TAG"

docker tag "$REPO_NGINX_LOCAL" "$REPO_NGINX":"$DOCKER_PUSH_TAG"
docker push "$REPO_NGINX":"$DOCKER_PUSH_TAG"
