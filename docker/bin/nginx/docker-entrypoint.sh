#!/bin/bash

set -eu

# If the user does not pass php-fpm, call whatever he wants to use (e. g. /bin/bash)
if [[ $1 != "nginx" ]]; then
	exec "$@"
	exit
fi

# Prepare nginx
# https://github.com/docker-library/docs/issues/496#issuecomment-287927576
envsubst "$(printf '${%s} ' $(bash -c "compgen -A variable"))" </etc/nginx/nginx.template >/etc/nginx/nginx.conf
if [[ $USE_HTTPS == "true" ]]; then
    if [[ ! -f "/data/certs/website.crt" || ! -f "/data/certs/website.key" ]]; then
        echo "Creating SSL certificate ..."
        openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out website.crt -keyout website.key -subj "/C=/ST=/L=/O=/OU=/CN="

        if [[ ! -d /data/certs ]]; then
            mkdir -p /data/certs
        fi
        mv website.crt /data/certs
        mv website.key /data/certs

        # Delete files if already exist (Docker saving files)
        if [[ -f "/etc/ssl/certs/website.crt" ]]; then
            rm /etc/ssl/certs/website.crt
        fi
        if [[ -f "/etc/ssl/certs/website.key" ]]; then
            rm /etc/ssl/certs/website.key
        fi
    fi

    # Link files
    echo "Linking certificates to /etc/ssl/certs/* ..."
    if [[ -f /etc/ssl/certs/website.crt ]]; then
        rm /etc/ssl/certs/website.crt
    fi
    if [[ -f /etc/ssl/certs/website.key ]]; then
        rm /etc/ssl/certs/website.key
    fi
    ln -s /data/certs/website.crt /etc/ssl/certs/website.crt
    ln -s /data/certs/website.key /etc/ssl/certs/website.key

    echo "Enabling HTTPS for nginx ..."
    if [[ ! -f /etc/nginx/conf.d/default-ssl.conf ]]; then
        envsubst "$(printf '${%s} ' $(bash -c "compgen -A variable"))" </etc/nginx/conf.d/default-ssl.template >/etc/nginx/conf.d/default-ssl.conf
    fi
else
    echo "Enabling HTTP for nginx ..."
    envsubst "$(printf '${%s} ' $(bash -c "compgen -A variable"))" </etc/nginx/conf.d/default.template >/etc/nginx/conf.d/default.conf
fi

# Empty all php files (to reduce size). Only the file's existence is important
find . -type f -name "*.php" -exec sh -c 'i="$1"; >"$i"' _ {} \;

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
