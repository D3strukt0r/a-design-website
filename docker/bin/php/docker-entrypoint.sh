#!/usr/bin/env bash

set -eu

# If the user does not pass php-fpm, call whatever he wants to use (e. g. /bin/bash)
if [[ $1 != "php-fpm" ]]; then
	exec "$@"
	exit
fi

# Setup php
if [[ "$DEV" == "true" ]]; then
	cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
else
	cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
fi

{
	echo "opcache.revalidate_freq = 0"
	if [[ "$DEV" != "true" ]]; then
		echo "opcache.validate_timestamps = 0"
	fi
	echo "opcache.max_accelerated_files = $(find /app -type f -print | grep -c php)"
	echo "opcache.memory_consumption = 192"
	echo "opcache.interned_strings_buffer = 16"
	echo "opcache.fast_shutdown = 1"
} >"$PHP_INI_DIR/conf.d/opcache.ini"

{
	echo "max_execution_time = 120"
	echo "memory_limit = 256M"
} >"$PHP_INI_DIR/conf.d/misc.ini"

# Add custom upload limit
if [[ -n "${UPLOAD_LIMIT}" ]]; then
	echo "Adding the custom upload limit of $UPLOAD_LIMIT."
	{
		echo "upload_max_filesize = $UPLOAD_LIMIT"
		# TODO: "post_max_size" should be greater than "upload_max_filesize".
		echo "post_max_size = $UPLOAD_LIMIT"
	} >"$PHP_INI_DIR/conf.d/upload-limit.ini"
fi

# Link license.key
if [[ ! -d /data/config ]]; then
	mkdir -p /data/config
fi
if [[ ! -f /data/config/license.key ]]; then
	touch /data/config/license.key
fi
echo "Linking config/license.key from /data to /app ..."
ln -sf /data/config/license.key ./config/license.key

# Link storage/
echo "Linking storage/ from /data to /app ..."
if [[ ! -d /data/storage ]]; then
	cp /skeleton/storage /data
fi
ln -sf /data/storage .

# Link cpresources/
echo "Linking web/cpresources/ from /data to /app ..."
if [[ ! -d /data/web ]]; then
	mkdir -p /data/web
fi
if [[ ! -d /data/web/cpresources ]]; then
	cp /skeleton/web/cpresources /data/web
fi
ln -sf /data/web/cpresources ./web/cpresources

exec "$@"
