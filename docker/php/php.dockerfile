ARG ENVIRONMENT

FROM dunglas/frankenphp:1.1-php8.3-alpine as base

# Prepare redis extension
RUN curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/6.0.2.tar.gz \
    && mkdir -p /usr/src/php/ext/redis \
    && tar xfz /tmp/redis.tar.gz --directory /usr/src/php/ext/redis \
    && rm -r /tmp/redis.tar.gz

# Install Composer and enable all necessary dependencies for laravel to function
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && apk add --no-cache git curl-dev libxml2-dev oniguruma-dev linux-headers \
    && docker-php-ext-install -j$(nproc) \
           bcmath curl mbstring pcntl pdo pdo_mysql xml \
           redis/phpredis-6.0.2

# Install a CRON alternative which is designed to work with containers!
RUN wget -q "https://github.com/aptible/supercronic/releases/download/v0.2.29/supercronic-linux-amd64" \
         -O /usr/bin/supercronic \
    && chmod +x /usr/bin/supercronic

# For security do never run any process inside the PHP container with ROOT
RUN addgroup --gid 1000 composer \
    && adduser --disabled-password --ingroup composer --uid 1000 composer

FROM base as development

# This is necessary to make minio to work locally
COPY ca-certificates/*.pem /usr/local/share/ca-certificates

# Install xDebug
RUN curl -L -o /tmp/xdebug.tar.gz https://github.com/xdebug/xdebug/archive/3.3.1.tar.gz \
    && mkdir -p /usr/src/php/ext/xdebug \
    && tar xfz /tmp/xdebug.tar.gz --directory /usr/src/php/ext/xdebug \
    && rm -r /tmp/xdebug.tar.gz

RUN apk add --no-cache ca-certificates alpine-sdk \
    && update-ca-certificates \
    && docker-php-ext-install -j$(nproc) xdebug/xdebug-3.3.1 \
    # This is necessary to make minio work on .localhost domains, related to this: https://github.com/curl/curl/issues/11104
    && wget -q "https://github.com/curl/curl/releases/download/curl-7_84_0/curl-7.84.0.zip" \
            -O /tmp/curl-7.84.0.zip \
    && cd /tmp \
    && unzip /tmp/curl-7.84.0.zip \
    && cd curl-7.84.0 \
    && ./configure --with-openssl \
    && make \
    && make install \
    && apk del alpine-sdk \
    && rm -rf /tmp/curl-*

RUN mkdir -p /opt/phpstorm-coverage \
    && chown -R 1000:1000 /opt/phpstorm-coverage

# Copy the config files to the right places
RUN mv /usr/local/etc/php/php.ini-development /usr/local/etc/php/conf.d/php.ini-development

COPY ./config/php-config.development.ini /usr/local/etc/php/conf.d/php-config.development.ini

FROM base as production

# Copy the config files to the right places
RUN mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/conf.d/php.ini-production

COPY ./config/php-config.production.ini /usr/local/etc/php/conf.d/php-config.production.ini

FROM ${ENVIRONMENT}

COPY ./config/Caddyfile /etc/caddy/Caddyfile

USER composer

WORKDIR /srv
