FROM php:7.2-fpm-alpine
LABEL Description="Application container"
LABEL Version="v2"

ENV PS1='\[\033[1;32m\]🐳  \[\033[1;36m\][\u@\h] \[\033[1;34m\]\w\[\033[0;35m\] \[\033[1;36m\]# \[\033[0m\]'

ENV COMPOSER_VERSION 1.7.2
## Looked here: <https://github.com/prooph/docker-files/blob/master/php/7.2-cli>
ENV PHP_REDIS_VERSION 4.1.1
ENV PHP_XDEBUG_VERSION 2.6.1

RUN rm -rf /home/app \
        && mkdir /home/app \
        && chmod 777 /home/app \
        && chown ${USER_ID:-1000}:${GROUP_ID:-1000} /home/app

RUN addgroup -g ${GROUP_ID:-1000} app && \
    adduser -D -u ${USER_ID:-1000} -h /home/app -G app app

RUN apk add --update --no-cache git openssh-client

# persistent / runtime deps
ENV PHPIZE_DEPS \
    autoconf \
    cmake \
    file \
    g++ \
    gcc \
    libc-dev \
    pcre-dev \
    make \
    git \
    pkgconf \
    re2c \
    # for GD
    freetype-dev \
    libpng-dev  \
    libjpeg-turbo-dev \
    libxslt-dev

RUN apk add --no-cache --virtual .persistent-deps \
    # for intl extension
    icu-dev \
    # for postgres
    postgresql-dev \
    # for soap
    libxml2-dev \
    # for GD
    freetype \
    libpng \
    libjpeg-turbo \
    # for bz2 extension
    bzip2-dev \
    # for intl extension
    libintl gettext-dev libxslt \
    # etc
    bash nano

# workaround for rabbitmq linking issue
RUN set -xe \
    && ln -s /usr/lib /usr/local/lib64 \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
    && docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure bcmath --enable-bcmath \
    && docker-php-ext-configure intl --enable-intl \
    && docker-php-ext-configure pcntl --enable-pcntl \
    && docker-php-ext-configure mysqli --with-mysqli \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql \
    && docker-php-ext-configure pdo_pgsql --with-pgsql \
    && docker-php-ext-configure mbstring --enable-mbstring \
    && docker-php-ext-configure soap --enable-soap
#    && docker-php-ext-configure opcache --enable-opcache \

RUN docker-php-ext-install \
        gd \
        bcmath \
        intl \
        pcntl \
        mysqli \
        pdo_mysql \
        pdo_pgsql \
#        mbstring \
        soap \
#        iconv \
        bz2 \
        calendar \
        exif \
        gettext \
        shmop \
        sockets \
        sysvmsg \
        sysvsem \
        sysvshm \
        wddx \
        xsl \
        zip

#        opcache \
#    && echo -e "opcache.memory_consumption=128\n\
#opcache.interned_strings_buffer=8\n\
#opcache.max_accelerated_files=4000\n\
#opcache.revalidate_freq=60\n\
#opcache.fast_shutdown=1\n\
#opcache.enable_cli=1\n\
#opcache.enable=1\n" > /usr/local/etc/php/conf.d/opcache.ini \


# For phpunit coverage
RUN pecl install xdebug-${PHP_XDEBUG_VERSION} \
    && docker-php-ext-enable xdebug \
    && git clone --branch ${PHP_REDIS_VERSION} https://github.com/phpredis/phpredis /tmp/phpredis \
        && cd /tmp/phpredis \
        && phpize  \
        && ./configure  \
        && make  \
        && make install \
        && make test \
        && echo 'extension=redis.so' > /usr/local/etc/php/conf.d/redis.ini \
    && apk del .build-deps \
    && rm -rf /tmp/* \
    && rm -rf /app \
    && mkdir /app \
    && rm -rf /scripts \
    && mkdir /scripts \
    && mkdir -p /scripts/aliases \
    && rm -f /docker-entrypoint.sh \
    && rm -f /usr/local/etc/php-fpm.d/*

COPY ./etc/php/php.ini $PHP_INI_DIR/php.ini
COPY ./etc/php/php-fpm.conf /usr/local/etc/php-fpm.conf

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp
ENV PATH /scripts:/scripts/aliases:$PATH

RUN set -xe \
    && mkdir -p "$COMPOSER_HOME" \
    # install composer
    && php -r "copy('https://getcomposer.org/installer', '/tmp/composer-setup.php');" \
    && php -r "if(hash_file('SHA384','/tmp/composer-setup.php')==='93b54496392c062774670ac18b134c3b3a95e5a5e5c8f1a9f'.\
    '115f203b75bf9a129d5daa8ba6a13e2cc8a1da0806388a8'){echo 'Verified';}else{unlink('/tmp/composer-setup.php');}" \
    && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/bin --filename=composer --version=$COMPOSER_VERSION \
    && composer --ansi --version --no-interaction \
    && composer --no-interaction global require 'hirak/prestissimo' \
    && composer clear-cache \
    && rm -rf /tmp/composer-setup.php /tmp/.htaccess \
    # show php info
    && php -v \
    && php-fpm -v \
    && php -m

COPY ./keep-alive.sh /scripts/keep-alive.sh
COPY ./scheduler.sh /scripts/scheduler.sh
COPY ./fpm-entrypoint.sh /fpm-entrypoint.sh
COPY ./aliases/* /scripts/aliases/

WORKDIR /app
ENTRYPOINT []
CMD []
