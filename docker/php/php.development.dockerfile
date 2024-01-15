FROM dunglas/frankenphp:sha-d4c313f-php8.3-alpine

## Install Composer and Enable all necessary dependencies for laravel to function
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    apk add --no-cache curl-dev libxml2-dev oniguruma-dev && \
    docker-php-ext-install -j$(nproc) bcmath curl mbstring pcntl pdo pdo_mysql xml

## Install a CRON alternative which is designed to work with containers!
RUN wget -q "https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64" \
         -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic

## For security do never run any process inside the PHP container with ROOT
RUN addgroup --gid 1000 composer && \
    adduser --disabled-password --ingroup composer --uid 1000 composer && \
    chown -R composer:composer /data /config

RUN mkdir -p /opt/phpstorm-coverage && \
    chown -R 1000:1000 /opt/phpstorm-coverage

## Copy the config files to the right places
RUN mv /usr/local/etc/php/php.ini-development /usr/local/etc/php/conf.d/php.ini-development

COPY ./config/php-config.development.ini /usr/local/etc/php/conf.d/php-config.development.ini
COPY ./config/Caddyfile /etc/caddy/Caddyfile

USER composer

WORKDIR /srv
