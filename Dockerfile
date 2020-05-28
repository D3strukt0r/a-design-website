# ---------
# PHP stage
# ---------
# Uses php:7.4-fpm-alpine
FROM d3strukt0r/php-craftcms AS php

ARG DEV=false

COPY bin/php /usr/local/bin
COPY build/php /build
COPY . /build/src
COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN set -eux; \
    apk update; \
    apk add --no-cache bash nano; \
    /build/build.sh

ENV UPLOAD_LIMIT=10M \
	DEV=false \
	ENVIRONMENT= \
	SECURITY_KEY= \
	DB_DSN= \
	DB_USER= \
	DB_PASSWORD= \
	DB_SCHEMA= \
	DB_TABLE_PREFIX= \
	DEFAULT_SITE_URL=

VOLUME ["/data"]
WORKDIR /app
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]

# -----------
# Nginx stage
# -----------
FROM nginx:1.17-alpine AS nginx

COPY bin/nginx /usr/local/bin
COPY build/nginx /build
COPY web /app/web

RUN set -eux; \
    apk update; \
    apk add --no-cache bash nano openssl; \
    /build/build.sh

ENV UPLOAD_LIMIT=10M \
    USE_HTTPS=false

VOLUME ["/data"]
WORKDIR /app
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
