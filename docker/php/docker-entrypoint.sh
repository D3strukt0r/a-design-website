#!/bin/sh

set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- php-fpm "$@"
fi

# Setup php
if [ "$1" = 'php-fpm' ] || [ "$1" = 'php' ]; then
    PHP_INI_RECOMMENDED="$PHP_INI_DIR/php.ini-production"
    if [ "$ENVIRONMENT" != 'prod' ]; then
        PHP_INI_RECOMMENDED="$PHP_INI_DIR/php.ini-development"
    fi
    ln -sf "$PHP_INI_RECOMMENDED" "$PHP_INI_DIR/php.ini"

    # mkdir -p var/cache var/log

    if [ "$ENVIRONMENT" != 'prod' ] && [ -f /certs/localCA.crt ]; then
        ln -sf /certs/localCA.crt /usr/local/share/ca-certificates/localCA.crt
        update-ca-certificates
    fi

    if [ "$ENVIRONMENT" != 'prod' ]; then
        composer install --prefer-dist --no-interaction --no-plugins --no-scripts --no-progress --no-suggest
    fi

    # Guess the port, if not set
    if [ -z "$DB_PORT" ]; then
        if [ "$DB_DRIVER" = "mysql" ]; then
            DB_PORT=3306
        elif [ "$DB_DRIVER" = "pgsql" ]; then
            DB_PORT=5432
        fi
    fi

    echo 'Waiting for db to be ready...'
    ATTEMPTS_LEFT_TO_REACH_DATABASE=60
    if [ "$DB_DRIVER" = "mysql" ]; then
        until [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -eq 0 ] || mysql --host="$DB_SERVER" --port="$DB_PORT" --user="$DB_USER" --password="$DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
            sleep 1
            ATTEMPTS_LEFT_TO_REACH_DATABASE=$((ATTEMPTS_LEFT_TO_REACH_DATABASE - 1))
            echo "Still waiting for db to be ready... Or maybe the db is not reachable. $ATTEMPTS_LEFT_TO_REACH_DATABASE attempts left"
        done
    elif [ "$DB_DRIVER" = "pgsql" ]; then
        until [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -eq 0 ] || pg_isready --host="$DB_SERVER" --port="$DB_PORT" --username="$DB_USER" --dbname="$DB_DATABASE" >/dev/null 2>&1; do
            sleep 1
            ATTEMPTS_LEFT_TO_REACH_DATABASE=$((ATTEMPTS_LEFT_TO_REACH_DATABASE - 1))
            echo "Still waiting for db to be ready... Or maybe the db is not reachable. $ATTEMPTS_LEFT_TO_REACH_DATABASE attempts left"
        done
    else
        echo "Database not supported! Use either MySQL or PostgreSQL"
    fi

    if [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -eq 0 ]; then
        echo 'The db is not up or not reachable'
        exit 1
    else
        echo 'The db is now ready and reachable'
    fi

    {
        echo 'opcache.revalidate_freq = 0'
        if [ "$ENVIRONMENT" = 'prod' ]; then
            echo 'opcache.validate_timestamps = 0'
        fi
        echo "opcache.max_accelerated_files = $(find /app -type f -print | grep -c php)"
        echo 'opcache.memory_consumption = 192'
        echo 'opcache.interned_strings_buffer = 16'
        echo 'opcache.fast_shutdown = 1'
    } >"$PHP_INI_DIR/conf.d/opcache.ini"

    {
        echo 'apc.enable_cli = 1'
        echo 'date.timezone = UTC'
        echo 'session.auto_start = Off'
        echo 'short_open_tag = Off'
        echo "max_execution_time = $PHP_MAX_EXECUTION_TIME"
        echo "memory_limit = $PHP_MEMORY_LIMIT"
    } >"$PHP_INI_DIR/conf.d/misc.ini"

    {
        echo "post_max_size = $PHP_POST_MAX_SIZE"
        echo "upload_max_filesize = $PHP_UPLOAD_MAX_FILESIZE"
    } >"$PHP_INI_DIR/conf.d/upload-limit.ini"

    # echo 'Linking config/license.key from /data to /app ...'
    # if [ ! -d /data/config ]; then
    #     mkdir -p /data/config
    # fi
    # if [ ! -f /data/config/license.key ]; then
    #     touch /data/config/license.key
    # fi
    # ln -sf /data/config/license.key ./config/license.key

    # echo 'Linking storage/ from /data to /app ...'
    # if [ ! -d /data/storage ]; then
    #     # cp /skeleton/storage /data
    #     mkdir -p /data/storage
    # fi
    # ln -sf /data/storage ./storage

    # echo 'Linking web/cpresources/ from /data to /app ...'
    # if [ ! -d /data/web ]; then
    #     mkdir -p /data/web
    # fi
    # if [ ! -d /data/web/cpresources ]; then
    #     # cp /skeleton/web/cpresources /data/web
    #     mkdir -p /data/web/cpresources
    # fi
    # ln -sf /data/web/cpresources ./web/cpresources
fi

exec docker-php-entrypoint "$@"
