# -------
# Builder
# -------

FROM bitnami/php-fpm:7.4 as builder

COPY . /app
WORKDIR /app

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer install

# -------
# Final Container
# -------

FROM bitnami/php-fpm:7.4-prod

COPY --from=builder /app /app

WORKDIR /app
EXPOSE 9000
CMD ["php-fpm", "-F", "--pid" , "/opt/bitnami/php/tmp/php-fpm.pid", "-c", "/opt/bitnami/php/conf/php-fpm.conf"]
