# -----------
# Build stage
# -----------
FROM composer AS build

ARG dev=--no-dev

WORKDIR /app
COPY . .
RUN composer install --ignore-platform-reqs --prefer-dist --no-ansi ${dev} --no-interaction --no-plugins --no-progress --no-scripts --no-suggest --optimize-autoloader

# ---------
# PHP stage
# ---------
FROM php:7.4-fpm-alpine AS php

WORKDIR /app

# Copy all the source files
# UID and GID is 82 for www-data
COPY --chown=82:82 config ./config
RUN mkdir /data/config -p
RUN touch /data/config/license.key
RUN ln -sf /data/config/license.key ./config/license.key

COPY --chown=82:82 modules ./modules

COPY --chown=82:82 storage /data/storage
RUN ln -s /data/storage .

COPY --chown=82:82 templates ./templates

COPY --chown=82:82 web ./web
RUN mkdir /data/web
RUN mv ./web/cpresources /data/web
RUN ln -s /data/web/cpresources ./web/cpresources

COPY --chown=82:82 .env.example /data/.env
RUN ln -s /data/.env ./.env

COPY --chown=82:82 craft .

COPY --from=build /app/vendor ./vendor

# Get all the requirements
RUN apk add --no-cache bash zip autoconf g++ imagemagick-dev make libpng-dev libzip-dev icu-dev
RUN docker-php-ext-install pdo_mysql gd zip intl
RUN pecl install imagick
RUN docker-php-ext-enable imagick

# Remove building tools for smaller container size
RUN rm -rf /tmp/pear
RUN apk del autoconf g++ make

VOLUME [ "/data" ]

# -----------
# Nginx stage
# -----------
FROM nginx:1.17-alpine AS nginx

WORKDIR /app

# Copy all the source files
COPY web ./web
RUN mkdir /data/web -p
RUN mv ./web/cpresources /data/web
RUN ln -s /data/web/cpresources ./web/cpresources

VOLUME [ "/data" ]
