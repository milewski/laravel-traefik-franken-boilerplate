ARG ENVIRONMENT

FROM dunglas/frankenphp:1.7-php8.4-alpine AS base

# Prepare redis extension
RUN curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/6.2.0.tar.gz && \
    mkdir -p /usr/src/php/ext/redis && \
    tar zxf /tmp/redis.tar.gz --directory /usr/src/php/ext/redis && \
    rm -f /tmp/redis.tar.gz

# Install Composer and enable all necessary dependencies for laravel to function
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN apk add --no-cache curl-dev git icu-dev libxml2-dev libzip-dev libpng-dev oniguruma-dev linux-headers \
    && docker-php-ext-install -j$(nproc) \
           bcmath gd intl pcntl pdo_mysql zip \
           redis/phpredis-6.2.0

# For security do never run any process inside the PHP container with ROOT
RUN addgroup --gid 1000 composer \
    && adduser --disabled-password --ingroup composer --uid 1000 composer

FROM base AS development

# Copy the config files to the right places
RUN cp $PHP_INI_DIR/php.ini-development $PHP_INI_DIR/php.ini

RUN mkdir -p /opt/phpstorm-coverage \
    && chown -R 1000:1000 /opt/phpstorm-coverage

FROM base AS production

# Copy the config files to the right places
RUN cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini

FROM ${ENVIRONMENT}

COPY ./config/Caddyfile /etc/frankenphp/Caddyfile

USER composer

WORKDIR /srv
