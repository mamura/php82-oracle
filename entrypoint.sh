#!/bin/bash

if [ ! -z "$PROJECT_WEBROOT" ]
then
    sed -i -e "s|/src/;|$PROJECT_WEBROOT;|g" /etc/nginx/conf.d/app.conf
    ln -s /etc/nginx/conf.d/app.conf /etc/nginx/sites-available/app
    ln -s /etc/nginx/conf.d/app.conf /etc/nginx/sites-enabled/app
    rm /etc/nginx/sites-enabled/default
fi

if [ ! -d /run/php/ ]
then
    mkdir /run/php/
    chown www-data:www-data /run/php/
fi

# Restart PHP-FPM service
/etc/init.d/php8.2-fpm restart