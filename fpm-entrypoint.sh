#!/usr/bin/env sh
set -e

FPM_CONFIG_PATH="${FPM_CONFIG_PATH:-/usr/local/etc/php-fpm.conf}";

FPM_PORT="${FPM_PORT:-9000}";
FPM_USER="${FPM_USER:-root}";
FPM_GROUP="${FPM_GROUP:-root}";

sed -i "s#%FPM_PORT%#${FPM_PORT}#g" "$FPM_CONFIG_PATH";
sed -i "s#%FPM_USER%#${FPM_USER}#g" "$FPM_CONFIG_PATH";
sed -i "s#%FPM_GROUP%#${FPM_GROUP}#g" "$FPM_CONFIG_PATH";

sed -i '$ a\xdebug.remote_host=docker.for.mac.host.internal' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
sed -i '$ a\xdebug.remote_enable=1' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
sed -i '$ a\xdebug.remote_autostart=1' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
sed -i '$ a\xdebug.idekey=PHPSTORM' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
sed -i '$ a\xdebug.remote_connect_back=0' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
sed -i '$ a\xdebug.remote_port=9001' /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

exec "$@";
