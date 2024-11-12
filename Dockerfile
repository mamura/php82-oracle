FROM ubuntu:latest

# Essentials
ENV TZ=America/Fortaleza
RUN echo $TZ > /etc/timezone \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -yqq \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    libaio-dev \
    g++ \
    make \
    zip \
    unzip \
    curl \
    nano \
    supervisor \
    bash \
    wget

RUN add-apt-repository ppa:ondrej/php \
    && apt-get -yqq update

WORKDIR /src

# NodeJS
RUN curl -sL https://deb.nodesource.com/setup_16.x 565 | bash - \
    && apt-get install nodejs

# NGINX
RUN apt-get -y install nginx
COPY app.conf /etc/nginx/conf.d/app.conf

# PHP82
RUN apt-get update \
    && apt-get install -yqq php8.2 \
    php8.2-common \
    php8.2-fpm \
    php8.2-dev \
    php8.2-pdo \
    php8.2-opcache \
    php8.2-zip \
    php8.2-phar \
    php8.2-iconv \
    php8.2-cli \
    php8.2-curl \
    php8.2-mbstring \
    php8.2-tokenizer \
    php8.2-fileinfo \
    php8.2-xml \
    php8.2-xmlwriter \
    php8.2-simplexml \
    php8.2-dom \
    php8.2-tokenizer \
    php8.2-redis \
    php8.2-xdebug \
    php8.2-gd \
    php8.2-mysql \
    php8.2-ldap 

# Configuracoes do PHP
RUN linhas=$(grep -m1 -n "listen =" /etc/php/8.2/fpm/pool.d/www.conf | cut -f1 -d:) \
    && sed -i "${linhas}d" /etc/php/8.2/fpm/pool.d/www.conf \
    && sed -i "${linhas}i listen=127.0.0.1:9000" /etc/php/8.2/fpm/pool.d/www.conf

RUN max_cli=$(grep -m1 -n "max_execution_time" /etc/php/8.2/cli/php.ini | cut -f1 -d:) \
    && sed -i "${max_cli}d" /etc/php/8.2/cli/php.ini \
    && sed -i "${max_cli}i max_execution_time = 240" /etc/php/8.2/cli/php.ini 

RUN max_fpm=$(grep -m1 -n "max_execution_time" /etc/php/8.2/fpm/php.ini | cut -f1 -d:) \
    && sed -i "${max_fpm}d" /etc/php/8.2/fpm/php.ini \
    && sed -i "${max_fpm}i max_execution_time = 240" /etc/php/8.2/fpm/php.ini

RUN filesize_cli=$(grep -m1 -n "upload_max_filesize" /etc/php/8.2/cli/php.ini | cut -f1 -d:) \
    && sed -i "${filesize_cli}d" /etc/php/8.2/cli/php.ini \
    && sed -i "${filesize_cli}i upload_max_filesize = 200M" /etc/php/cli/php.ini

RUN filesize_fpm=$(grep -m1 -n "upload_max_filesize" /etc/php/8.2/fpm/php.ini | cut -f1 -d:) \
    && sed -i "${filesize_fpm}d" /etc/php/8.2/fpm/php.ini \
    && sed -i "${filesize_fpm}i upload_max_filesize = 200M" /etc/php/fpm/php.ini

RUN post_cli=$(grep -m1 -n "post_max_size" /etc/php/8.2/cli/php.ini | cut -f1 -d:) \
    && sed -i "${post_cli}d" /etc/php/8.2/cli/php.ini \
    && sed -i "${post_cli}i post_max_size = 200M" /etc/php/8.2/cli/php.ini

RUN post_fpm=$(grep -m1 -n "post_max_size" /etc/php/8.2/fpm/php.ini | cut -f1 -d:) \
    && sed -i "${post_fpm}d" /etc/php/8.2/fpm/php.ini \
    && sed -i "${post_fpm}i post_max_size = 200M" /etc/php/8.2/fpm/php.ini

RUN memory_cli=$(grep -m1 -n "memory_limit" /etc/php/8.2/cli/php.ini | cut -f1 -d:) \
    && sed -i "${memory_cli}d" /etc/php/8.2/cli/php.ini \
    && sed -i "${memory_cli}i memory_limit = 512M" /etc/php/8.2/cli/php.ini

RUN memory_fpm=$(grep -m1 -n "memory_limit" /etc/php/8.2/fpm/php.ini | cut -f1 -d:) \
    && sed -i "${memory_fpm}d" /etc/php/8.2/fpm/php.ini \
    && sed -i "${memory_fpm}i memory_limit = 512M" /etc/php/8.2/fpm/php.ini

RUN /etc/init.d/php8.2-fpm restart

    # Xdebug
COPY xdebug.ini "${PHP_INI_DIR}/conf.d"

# Composer
ARG HASH="`curl -sS https://composer.github.io/installer.sig`"
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === $HASH) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php --install-dir=/bin --filename=composer
RUN php -r "unlink('composer-setup.php');"

# OCI extension | Orcle InstantClient
RUN mkdir -p /opt/oracle
RUN wget https://download.oracle.com/otn_software/linux/instantclient/218000/instantclient-basic-linux.x64-21.8.0.0dbru.zip
RUN wget https://download.oracle.com/otn_software/linux/instantclient/218000/instantclient-sdk-linux.x64-21.8.0.0dbru.zip
RUN unzip -o ./instantclient-basic-linux.x64-21.8.0.0dbru.zip -d /opt/oracle
RUN unzip -o ./instantclient-sdk-linux.x64-21.8.0.0dbru.zip -d /opt/oracle
RUN rm instantclient-basic-linux.x64-21.8.0.0dbru.zip
RUN rm instantclient-sdk-linux.x64-21.8.0.0dbru.zip
RUN ln -s /opt/oracle/instantclient/sqlplus /usr/bin/sqlplus
RUN ln -s /opt/oracle/instantclient_21_8 /opt/oracle/instantclient
RUN echo /opt/oracle/instantclient_21_8 > /etc/ld.so.conf.d/oracle-instantclient.conf
RUN ldconfig
RUN echo 'instantclient./opt/oracle/instantclient' | pecl install oci8-3.2.1
RUN echo "extension=oci8.so" >> /etc/php/8.2/mods-available/oci8.ini \
    && ln -s /etc/php/8.2/mods-available/oci8.ini /etc/php/8.2/cli/conf.d/20-oci8.ini \
    && ln -s /etc/php/8.2/mods-available/oci8.ini /etc/php/8.2/fpm/conf.d/20-oci8.ini \
    && echo "LD_LIBRARY_PATH=\"/opt/oracle/instantclient\"" >> /etc/environment \
    && echo "ORACLE_HOME=\"/opt/oracle/instantclient\"" >> /etc/environment

# Supervisor
RUN mkdir -p /etc/supervisor.d/
COPY supervisord.ini /etc/supervisor.d/supervisord.ini

# Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

CMD [ "supervisord", "-c", "/etc/supervisor.d/supervisord.ini" ]