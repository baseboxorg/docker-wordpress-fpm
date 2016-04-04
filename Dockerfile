FROM php:fpm

ENV DBNAME wordpress
ENV DBUSER root
ENV DBPASS wordpress
ENV DBHOST localhost
ENV ADMIN_NAME admin123
ENV ADMIN_PASS Admin_passwoRD
ENV EMAIL admin@wordpress.org
ENV URL http://docker.vm
ENV TITLE WordPress

# install the PHP extensions we need
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd mysqli opcache

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

VOLUME /var/www/html

#
# Install WP-CLI
#
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli-nightly.phar \
    && chmod +x wp-cli-nightly.phar \
    && mv wp-cli-nightly.phar /usr/local/bin/wp

RUN wp core download --allow-root \
    && wp core config --allow-root \
      --dbname=$DBNAME \
      --dbuser=$DBUSER \
      --dbpass=$DBPASS \
      --dbhost=$DBHOST \
    && wp core install --allow-root \
      --admin_name=$ADMIN_NAME \
      --admin_password=$ADMIN_PASS \
      --admin_email=$EMAIL \
      --url=$URL \
      --title=$TITLE \
    && wp theme update --allow-root --all \
    && wp plugin update --allow-root --all \
    && chown -R www-data:www-data /usr/src/wordpress


COPY docker-entrypoint.sh /entrypoint.sh

# grr, ENTRYPOINT resets CMD now
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
