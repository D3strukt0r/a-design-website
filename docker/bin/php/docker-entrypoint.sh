#!/bin/bash

set -eu

# If the user does not pass php-fpm, call whatever he wants to use (e. g. /bin/bash)
if [[ $1 != "php-fpm" ]]; then
	exec "$@"
	exit
fi

# Add custom upload limit
if [[ ! -z "${UPLOAD_LIMIT}" ]]; then
    echo "Adding the custom upload limit."
    {
		echo "upload_max_filesize = $UPLOAD_LIMIT"
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

# Setup php
if [[ "$DEV" == "true" ]]; then
	cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
else
	cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
fi

if [[ "$DEV" == "true" ]]; then
	sed -i "s/opcache.validate_timestamps=0/#opcache.validate_timestamps=0/g" $PHP_INI_DIR/conf.d/opcache.ini
fi
# TODO: For max_accelerated_files find the number of php files (find . -type f -print | grep php | wc -l)


exec "$@"
