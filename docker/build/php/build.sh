#!/usr/bin/env bash

set -eux

# Alpine package for "imagemagick" contains ~120 .so files, see: https://github.com/docker-library/wordpress/pull/497
apk add --no-cache imagemagick

# Get all php requirements
# shellcheck disable=SC2086
apk add --no-cache --virtual .build-deps \
	$PHPIZE_DEPS \
	freetype-dev \
	libjpeg-turbo-dev \
	libpng-dev \
	icu-dev \
	libzip-dev \
	imagemagick-dev
docker-php-ext-configure gd --with-freetype --with-jpeg >/dev/null
docker-php-ext-install -j "$(nproc)" \
	gd \
	intl \
	opcache \
	pdo_mysql \
	zip \
	>/dev/null
pecl install imagick >/dev/null
docker-php-ext-enable imagick

# Find packages to keep, so we can safely delete dev packages
RUN_DEPS="$(
	scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions |
		tr ',' '\n' |
		sort -u |
		awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }'
)"
# shellcheck disable=SC2086
apk add --virtual .phpexts-rundeps $RUN_DEPS

# Remove building tools for smaller container size
apk del .build-deps
rm -r /tmp/pear

# Install composer
cd /usr/local/bin
/build/install-composer.sh
mv composer.phar composer

# Get all vendors
cd /build/src
if [[ "$DEV" == "true" ]]; then
	composer install --prefer-dist --no-interaction --no-plugins --no-scripts --no-suggest --optimize-autoloader
else
	composer install --prefer-dist --no-dev --no-interaction --no-plugins --no-scripts --no-suggest --optimize-autoloader
fi

# Copy the final app to /app
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
