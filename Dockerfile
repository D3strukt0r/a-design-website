# The different stages of this Dockerfile are meant to be built into separate images
# https://docs.docker.com/develop/develop-images/multistage-build/#stop-at-a-specific-build-stage
# https://docs.docker.com/compose/compose-file/#target

# https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
ARG PHP_VERSION=7.4
ARG NGINX_VERSION=1.19

# ---------
# PHP stage
# ---------
FROM php:${PHP_VERSION}-fpm-alpine AS php

# Build for production
ARG APCU_VERSION=5.1.18

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    PATH="${PATH}:/root/.composer/vendor/bin" \
    PHP_MAX_EXECUTION_TIME=120 \
    # 'memory_limit' has to be larger than 'post_max_size' and 'upload_max_filesize'
    PHP_MEMORY_LIMIT=256M \
    # Important for upload limit. 'post_max_size' has to be larger than 'upload_max_filesize'
    PHP_POST_MAX_SIZE=100M \
    PHP_UPLOAD_MAX_FILESIZE=100M \
    # The environment Craft is currently running in (dev, staging, production, etc.)
    ENVIRONMENT=prod \
    # The application ID used to to uniquely store session and cache data, mutex locks, and more
    APP_ID=CraftCMS \
    # The secure key Craft will use for hashing and encrypting data
    SECURITY_KEY= \
    # The database driver that will be used (mysql or pgsql)
    DB_DRIVER=mysql \
    # The database server name or IP address
    DB_SERVER=db \
    # The port to connect to the database with
    DB_PORT= \
    # The name of the database to select
    DB_DATABASE= \
    # The database username to connect with
    DB_USER=root \
    # The database password to connect with
    DB_PASSWORD= \
    # The database schema that will be used (PostgreSQL only)
    DB_SCHEMA=public \
    # The prefix that should be added to generated table names (only necessary if multiple
    # things are sharing the same database)
    DB_TABLE_PREFIX= \
    DEFAULT_SITE_URL=

WORKDIR /app

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY . .

RUN set -eux; \
    rm -r docker; \
    \
    apk update; \
    apk add --no-cache \
        # Alpine package for "imagemagick" contains ~120 .so files,
        # see: https://github.com/docker-library/wordpress/pull/497
        imagemagick \
        # Required to check connectivity
        mysql-client \
        postgresql-client \
        # Required for healthcheck
        fcgi; \
    \
    # Get all php requirements
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        # Required for gd
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        # Required for intl
        icu-dev \
        # Required for pdo_pgsql
        postgresql-dev \
        # Required for soap
        libxml2-dev \
        # Required for zip
        libzip-dev \
        # Required for imagick
        imagemagick-dev; \
    docker-php-ext-configure gd --with-freetype --with-jpeg >/dev/null; \
    docker-php-ext-install -j "$(nproc)" \
        gd \
        intl \
        opcache \
        pdo_mysql \
        pdo_pgsql \
        soap \
        zip \
        >/dev/null; \
    pecl install imagick >/dev/null; \
    pecl install apcu-${APCU_VERSION} >/dev/null; \
    pecl clear-cache; \
    docker-php-ext-enable \
        imagick \
        apcu \
        opcache; \
    \
    # Find packages to keep, so we can safely delete dev packages
    RUN_DEPS="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions | \
            tr ',' '\n' | \
            sort -u | \
            awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-cache --virtual .phpexts-rundeps $RUN_DEPS; \
    \
    # Remove building tools for smaller container size
    apk del .build-deps; \
    \
    # Set default php configuration
    ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini; \
    \
    # Prevent the reinstallation of vendors at every changes in the source code
    composer install --prefer-dist --no-dev --no-interaction --no-plugins --no-scripts --no-progress --no-suggest --optimize-autoloader; \
    composer clear-cache; \
    \
    # Fix permission
    chown www-data:www-data -R .; \
    find . -type d -exec chmod 755 {} \;; \
    find . -type f -exec chmod 644 {} \;

VOLUME ["/data"]

# https://github.com/renatomefi/php-fpm-healthcheck
RUN wget -O /usr/local/bin/php-fpm-healthcheck https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck; \
    chmod +x /usr/local/bin/php-fpm-healthcheck; \
    echo 'pm.status_path = /status' >> /usr/local/etc/php-fpm.d/zz-docker.conf
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["php-fpm-healthcheck"]

COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]

# -----------
# Nginx stage
# -----------
# Depends on the "php" stage above
FROM nginx:${NGINX_VERSION}-alpine AS nginx

ENV NGINX_CLIENT_MAX_BODY_SIZE=100M \
    USE_HTTPS=false

WORKDIR /app/web

COPY --from=php /app/web/ ./

COPY docker/nginx/nginx.conf       /etc/nginx/nginx.template
COPY docker/nginx/default.conf     /etc/nginx/conf.d/default.template
COPY docker/nginx/default-ssl.conf /etc/nginx/conf.d/default-ssl.template

RUN set -eux; \
    \
    apk update; \
    apk add --no-cache \
        bash \
        openssl; \
    \
    # Remove default config, will be replaced on startup with custom one
    rm /etc/nginx/conf.d/default.conf; \
    \
    # Empty all php files (to reduce container size). Only the file's existence is important
    find . -type f -name "*.php" -exec sh -c 'i="$1"; >"$i"' _ {} \;

VOLUME ["/data"]

HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["test", "-e", "/var/run/nginx.pid", "||", "exit", "1"]

COPY docker/nginx/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]
CMD ["nginx", "-g", "daemon off;"]
