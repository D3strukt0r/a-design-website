# -----------
# Build stage
# -----------
FROM composer AS build

ARG DEV=false

WORKDIR /app
COPY . .
RUN set -ex; \
if [[ "$DEV" == "true" ]]; then \
	composer install --ignore-platform-reqs --prefer-dist --no-interaction --no-plugins --no-scripts --no-suggest --optimize-autoloader; \
else \
	composer install --ignore-platform-reqs --prefer-dist --no-dev --no-interaction --no-plugins --no-scripts --no-suggest --optimize-autoloader; \
fi

# ---------
# PHP stage
# ---------
FROM php:7.4-fpm-alpine AS php

# Copy all the source files
# UID and GID is 82 for www-data
WORKDIR /app
COPY --chown=82:82 config ./config
COPY --chown=82:82 modules ./modules
COPY --chown=82:82 storage /data/storage
COPY --chown=82:82 templates ./templates
COPY --chown=82:82 web ./web
COPY --chown=82:82 .env.example /data/.env
COPY --chown=82:82 craft .
COPY --from=build /app/vendor ./vendor
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN set -ex; \
\
# Link license.key
mkdir /data/config -p; \
touch /data/config/license.key; \
ln -sf /data/config/license.key ./config/license.key; \
\
# Link storage/
ln -s /data/storage .; \
\
# Link cpresources/
mkdir /data/web; \
mv ./web/cpresources /data/web; \
ln -s /data/web/cpresources ./web/cpresources; \
\
# Link .env
ln -s /data/.env ./.env; \
\
# Get all php requirements
apk add --no-cache bash zip autoconf g++ imagemagick-dev make libpng-dev libzip-dev icu-dev; \
docker-php-ext-install pdo_mysql gd zip intl; \
pecl install imagick; \
docker-php-ext-enable imagick; \
\
# Remove building tools for smaller container size
rm -rf /tmp/pear; \
apk del autoconf g++ make; \
\
# Setup php
mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
{ \
	echo 'max_execution_time = 120'; \
	echo 'memory_limit = 256M'; \
} > $PHP_INI_DIR/conf.d/misc.ini

VOLUME [ "/data" ]

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["php-fpm"]

# -----------
# Nginx stage
# -----------
FROM nginx:1.17-alpine AS nginx

WORKDIR /app

# Copy all the source files
COPY web ./web

RUN set -ex; \
\
mkdir /data/web -p; \
mv ./web/cpresources /data/web; \
ln -s /data/web/cpresources ./web/cpresources

VOLUME [ "/data" ]
