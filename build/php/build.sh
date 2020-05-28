#!/bin/bash

set -eux

cd /build/src
if [[ "$DEV" == "true" ]]; then
	composer install --ignore-platform-reqs --prefer-dist --no-interaction --no-plugins --no-scripts --no-suggest --optimize-autoloader
else
	composer install --ignore-platform-reqs --prefer-dist --no-dev --no-interaction --no-plugins --no-scripts --no-suggest --optimize-autoloader
fi

mkdir /app
mkdir -p /skeleton/web

mv ./config /app
mv ./modules /app
mv ./storage /skeleton
mv ./templates /app
mv ./vendor /app
mv ./web /app
mv /app/web/cpresources /skeleton/web
mv ./craft /app

# Fix permission
cd /app
chown www-data:www-data -R .
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;

cd /skeleton
chown www-data:www-data -R .
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;

# Cleanup
rm -r /build
rm /usr/bin/composer
