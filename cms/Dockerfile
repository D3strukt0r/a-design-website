# -----------
# Build stage
# -----------
FROM composer AS build

WORKDIR /app
COPY . .
RUN composer install --ignore-platform-reqs --prefer-dist --no-ansi --no-dev --no-interaction --no-plugins --no-progress --no-scripts --no-suggest --optimize-autoloader

# ---------
# PHP stage
# ---------
FROM php:7.4-fpm-alpine AS php

WORKDIR /app
COPY . .
COPY --from=build /app/vendor ./vendor

RUN apk add --no-cache bash zip autoconf g++ imagemagick-dev make libpng-dev libzip-dev icu-dev
RUN docker-php-ext-install pdo_mysql gd zip intl
RUN pecl install imagick
RUN docker-php-ext-enable imagick

RUN rm -rf /tmp/pear
RUN apk del autoconf g++ make

VOLUME [ "/app/storage", "/app/web/cpresources", "/app/config" ]

# -----------
# Nginx stage
# -----------
FROM nginx:1.17-alpine AS nginx

WORKDIR /app
COPY ./web ./web

VOLUME [ "/app/web/cpresources" ]
