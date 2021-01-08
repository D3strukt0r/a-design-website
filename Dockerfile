# The different stages of this Dockerfile are meant to be built into separate images
# https://docs.docker.com/develop/develop-images/multistage-build/#stop-at-a-specific-build-stage
# https://docs.docker.com/compose/compose-file/#target

# ---------
# PHP stage
# ---------
FROM alpine AS php

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV PHP_INI_DIR="/etc/php7" \
    COMPOSER_ALLOW_SUPERUSER=1 \
    PATH="${PATH}:/root/.composer/vendor/bin"

WORKDIR /app

# Setup Alpine
# hadolint ignore=DL3018
RUN set -eux; \
    \
    apk update; \
    apk add --no-cache \
        bash \
        bash-completion \
        ca-certificates \
        curl \
        # https://github.com/docker-library/php/issues/494
        openssl \
        # Alpine package for "imagemagick" contains ~120 .so files,
        # see: https://github.com/docker-library/wordpress/pull/497
        imagemagick \
        # Required to check connectivity
        mysql-client \
        postgresql-client \
        # Required for healthcheck
        fcgi; \
    \
    # Custom bash config
    { \
        echo 'source /etc/profile.d/bash_completion.sh'; \
        # <green> user@host <normal> : <blue> dir <normal> $#
        echo 'export PS1="🐳 \e[38;5;10m\u@\h\e[0m:\e[38;5;12m\w\e[0m\\$ "'; \
    } >"$HOME/.bashrc"; \
    \
    # Ensure www-data user exists
    addgroup -g 82 -S www-data; \
    adduser -u 82 -D -S -G www-data www-data
    # 82 is the standard uid/gid for "www-data" in Alpine
    # https://git.alpinelinux.org/aports/tree/main/apache2/apache2.pre-install?h=3.9-stable
    # https://git.alpinelinux.org/aports/tree/main/lighttpd/lighttpd.pre-install?h=3.9-stable
    # https://git.alpinelinux.org/aports/tree/main/nginx/nginx.pre-install?h=3.9-stable

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Build PHP 7.4
# hadolint ignore=DL3018,SC2086
RUN set -eux; \
    \
    apk update; \
    apk add --no-cache \
        php7 \
        php7-curl \
        php7-ctype \
        php7-dom \
        php7-fileinfo \
        php7-fpm \
        php7-gd \
        php7-iconv \
        php7-intl \
        php7-json \
        php7-mbstring \
        php7-opcache \
        php7-pdo \
        php7-pdo_mysql \
        php7-pdo_pgsql \
        php7-phar \
        php7-session \
        php7-soap \
        php7-tokenizer \
        php7-xml \
        php7-xmlwriter \
        php7-zip \
        php7-pecl-imagick \
        php7-pecl-apcu

# Setup PHP
COPY docker/php/php-development.ini $PHP_INI_DIR/php.ini-development
COPY docker/php/php-production.ini $PHP_INI_DIR/php.ini-production
RUN set -eux; \
    \
    # Set default php configuration
    rm "$PHP_INI_DIR/php.ini"; \
    ln -s "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
    \
    # Setup fpm
    sed -i 's/user = nobody/user = www-data/g' "$PHP_INI_DIR/php-fpm.d/www.conf"; \
    sed -i 's/group = nobody/group = www-data/g' "$PHP_INI_DIR/php-fpm.d/www.conf"; \
    { \
        echo '[global]'; \
        echo 'error_log = /proc/self/fd/2'; \
        echo; \
        echo '; https://github.com/docker-library/php/pull/725#issuecomment-443540114'; \
        echo 'log_limit = 8192'; \
        echo; \
        echo '[www]'; \
        echo '; if we send this to /proc/self/fd/1, it never appears'; \
        echo 'access.log = /proc/self/fd/2'; \
        echo; \
        echo 'clear_env = no'; \
        echo; \
        echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
        echo 'catch_workers_output = yes'; \
        echo 'decorate_workers_output = no'; \
    } | tee $PHP_INI_DIR/php-fpm.d/docker.conf; \
    { \
        echo '[global]'; \
        echo 'daemonize = no'; \
        echo; \
        echo '[www]'; \
        echo 'listen = 9000'; \
    } | tee $PHP_INI_DIR/php-fpm.d/zz-docker.conf; \
    \
    # Install composer
    curl -fsSL -o composer-setup.php https://getcomposer.org/installer; \
    EXPECTED_CHECKSUM="$(curl -fsSL https://composer.github.io/installer.sig)"; \
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"; \
    \
    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then \
        >&2 echo 'ERROR: Invalid installer checksum'; \
        rm composer-setup.php; \
        exit 1; \
    fi; \
    \
    php composer-setup.php --quiet; \
    rm composer-setup.php; \
    mv composer.phar /usr/bin/composer

# Prevent the reinstallation of vendors at every changes in the source code
COPY composer.json composer.lock ./
RUN set -eux; \
    composer install --prefer-dist --no-dev --no-interaction --no-plugins --no-scripts --no-progress --no-suggest --optimize-autoloader; \
    composer clear-cache

# Setup application
COPY craft ./
COPY config ./config
COPY modules ./modules
COPY storage ./storage
COPY templates ./templates
COPY web ./web
RUN set -eux; \
    \
    # Fix permission
    chown www-data:www-data -R .; \
    find . -type d -exec chmod 755 {} \;; \
    find . -type f -exec chmod 644 {} \;; \
    chmod +x craft

# https://github.com/renatomefi/php-fpm-healthcheck
RUN curl -fsSL -o /usr/local/bin/php-fpm-healthcheck https://raw.githubusercontent.com/renatomefi/php-fpm-healthcheck/master/php-fpm-healthcheck; \
    chmod +x /usr/local/bin/php-fpm-healthcheck; \
    echo 'pm.status_path = /status' >> $PHP_INI_DIR/php-fpm.d/zz-docker.conf
HEALTHCHECK --interval=10s --timeout=3s --start-period=30s --retries=3 CMD php-fpm-healthcheck || exit 1

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/17baa87faddc2550def3ae7314236826bc1b1398/sapi/fpm/php-fpm.8.in#L163
STOPSIGNAL SIGQUIT

EXPOSE 9000

COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm7"]

# -----------
# Nginx stage
# -----------
# Depends on the "php" stage above
FROM nginx:1.19-alpine AS nginx

WORKDIR /app/web

# Setup Alpine
# hadolint ignore=DL3018
RUN set -eux; \
    \
    apk update; \
    apk add --no-cache \
        bash \
        bash-completion \
        openssl; \
    \
    # Custom bash config
    { \
        echo 'source /etc/profile.d/bash_completion.sh'; \
        # <green> user@host <normal> : <blue> dir <normal> $#
        echo 'export PS1="🐳 \e[38;5;10m\u@\h\e[0m:\e[38;5;12m\w\e[0m\\$ "'; \
    } >"$HOME/.bashrc"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Setup Nginx
COPY --from=php /app/web/ ./

COPY docker/nginx/nginx.conf       /etc/nginx/nginx.template
COPY docker/nginx/default.conf     /etc/nginx/conf.d/default.template
COPY docker/nginx/default-ssl.conf /etc/nginx/conf.d/default-ssl.template

RUN set -eux; \
    \
    # Remove default config, will be replaced on startup with custom one
    rm /etc/nginx/conf.d/default.conf; \
    \
    # Empty all php files (to reduce container size). Only the file's existence is important
    find . -type f -name "*.php" -exec sh -c 'i="$1"; >"$i"' _ {} \;; \
    \
    # Fix permission
    adduser -u 82 -D -S -G www-data www-data

HEALTHCHECK --interval=10s --timeout=3s --start-period=30s --retries=3 CMD curl -f http://localhost/ || exit 1

COPY docker/nginx/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]
CMD ["nginx", "-g", "daemon off;"]
