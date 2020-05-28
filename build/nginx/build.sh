#!/bin/bash

set -eux

# Use default config for nginx
mv /build/nginx.conf /etc/nginx/nginx.template
rm /etc/nginx/conf.d/default.conf
mv /build/default.conf /etc/nginx/conf.d/default.template
mv /build/default-ssl.conf /etc/nginx/conf.d/default-ssl.template

mkdir -p /skeleton/web
mv /app/web/cpresources /skeleton/web

# Cleanup
rm -r /build
