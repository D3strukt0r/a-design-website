# ----------------------
# Global build variables
# ----------------------
ARG DEV=false

# -----------
# Build stage
# -----------
FROM composer AS build
ARG DEV

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
# Uses php:7.4-fpm-alpine
FROM d3strukt0r/php-craftcms AS php

ARG DEV

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
# Setup php
if [[ "$DEV" == "true" ]]; then \
	cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"; \
else \
	cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
fi; \
\
# For max_accelerated_files find the number of php files (find . -type f -print | grep php | wc -l)
if [[ "$DEV" == "true" ]]; then \
	sed -i "s/opcache.validate_timestamps=0/#opcache.validate_timestamps=0/g" opcache.ini; \
fi

VOLUME [ "/data" ]

ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["php-fpm"]

# -----------
# Nginx stage
# -----------
FROM nginx:1.17-alpine AS nginx

# Copy all the source files
WORKDIR /app
COPY web ./web

RUN set -ex; \
\
mkdir /data/web -p; \
mv ./web/cpresources /data/web; \
ln -s /data/web/cpresources ./web/cpresources

VOLUME [ "/data" ]
