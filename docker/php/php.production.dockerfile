FROM dunglas/frankenphp:sha-d4c313f-php8.3-alpine

# Prepare redis extension
RUN curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/6.0.2.tar.gz \
    && mkdir -p /usr/src/php/ext/redis \
    && tar xfz /tmp/redis.tar.gz --directory /usr/src/php/ext/redis \
    && rm -r /tmp/redis.tar.gz

# Install Composer and enable all necessary dependencies for laravel to function
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    apk add --no-cache curl-dev libxml2-dev oniguruma-dev linux-headers && \
    docker-php-ext-install -j$(nproc) \
        bcmath curl mbstring pcntl pdo pdo_mysql xml \
        redis/phpredis-6.0.2

# Install a CRON alternative which is designed to work with containers!
RUN wget -q "https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64" \
         -O /usr/bin/supercronic && \
    chmod +x /usr/bin/supercronic

# For security do never run any process inside the PHP container with ROOT
RUN addgroup --gid 1000 composer && \
    adduser --disabled-password --ingroup composer --uid 1000 composer && \
    chown -R composer:composer /data /config

# Copy the config files to the right places
RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/conf.d/php.ini-production

COPY ./config/php-config.production.ini /usr/local/etc/php/conf.d/php-config.production.ini
COPY ./config/Caddyfile /etc/caddy/Caddyfile

USER composer

WORKDIR /srv
