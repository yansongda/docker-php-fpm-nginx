FROM php:7.2.19-fpm

LABEL maintainer="yansongda <me@yansongda.cn>"

# ENV for Global 
ENV TZ=Asia/Shanghai
ENV DEPENDENCIES curl gnupg git wget gcc 
ENV WORKING_DIR /www/software

# ENV for PHP
ENV PHP_DEPENDENCIES \
                    libwebp-dev libmcrypt-dev libmemcached-dev libbz2-dev libpng-dev \
                    libxpm-dev librabbitmq-dev libfreetype6-dev libjpeg-dev
ENV PHP_EXT_INSTALLED \
                    mongodb swoole redis memcached mcrypt amqp
ENV PHP_COMPOSER_URL https://dl.laravel-china.org/composer.phar
ENV PHP_COMPOSER_REPO https://packagist.laravel-china.org

# ENV for Nginx
ENV NGINX_VERSION   1.16.0
ENV NGINX_DEPENDENCIES \
                    libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev openssl
ENV NGINX_CONFIGURE \
                --user=www-data --group=www-data \
                --prefix=/etc/nginx \
                --sbin-path=/usr/sbin/nginx \
                --modules-path=/usr/lib64/nginx/modules \
                --conf-path=/etc/nginx/nginx.conf \
                --error-log-path=/var/log/nginx/error.log \
                --http-log-path=/var/log/nginx/access.log \
                --pid-path=/var/run/nginx.pid \
                --lock-path=/var/run/nginx.lock \
                --http-client-body-temp-path=/var/cache/nginx/client_temp \
                --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
                --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
                --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
                --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
                --with-compat --with-file-aio --with-threads \
                --with-http_addition_module --with-http_auth_request_module \
                --with-http_dav_module --with-http_flv_module --with-http_gunzip_module \
                --with-http_gzip_static_module --with-http_mp4_module \
                --with-http_random_index_module --with-http_realip_module \
                --with-http_secure_link_module --with-http_slice_module \
                --with-http_ssl_module --with-http_stub_status_module \
                --with-http_sub_module --with-http_v2_module --with-mail \
                --with-mail_ssl_module --with-stream --with-stream_realip_module \
                --with-stream_ssl_module --with-stream_ssl_preread_module \
                --add-module=$WORKING_DIR/nginx-module-vts

# INSTALL PHP 
RUN apt-get update \
  && apt-get install -y $PHP_DEPENDENCIES $DEPENDENCIES \
  && pecl install -o -f $PHP_EXT_INSTALLED \
  && docker-php-ext-configure gd --with-gd --with-webp-dir --with-jpeg-dir \
      --with-png-dir --with-zlib-dir --with-xpm-dir --with-freetype-dir \
  && docker-php-ext-install opcache bcmath bz2 gd iconv mysqli pdo pdo_mysql zip sockets \
  && docker-php-ext-enable opcache redis memcached mongodb swoole mcrypt amqp \
  && curl $PHP_COMPOSER_URL -o /usr/local/bin/composer \
  && chmod a+x /usr/local/bin/composer \
  && composer config -g repo.packagist composer $PHP_COMPOSER_REPO \
  && mkdir -p $WORKING_DIR && cd $WORKING_DIR \
  && git clone https://github.com/chuan-yun/Molten.git \
  && cd $WORKING_DIR/Molten && phpize && ./configure && make && make install

# INSTALL Nginx
RUN apt-get update \
  && apt-get install -y $NGINX_DEPENDENCIES $DEPENDENCIES \
  && mkdir -p $WORKING_DIR /var/cache/nginx/client_temp \
  && mkdir -p /var/cache/nginx/proxy_temp /var/cache/nginx/fastcgi_temp \
  && mkdir -p /var/cache/nginx/uwsgi_temp /var/cache/nginx/scgi_temp \
  && cd $WORKING_DIR \
  && wget https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz \
  && git clone https://github.com/vozlt/nginx-module-vts.git \
  && tar -xzvf nginx-$NGINX_VERSION.tar.gz \
  && cd nginx-$NGINX_VERSION \
  && ./configure $NGINX_CONFIGURE \
  && make && make install \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

# After build
WORKDIR /www

COPY sources.list /etc/apt/sources.list
COPY php-ext-molten.ini /usr/local/etc/php/conf.d/
COPY php.ini /usr/local/etc/php/
COPY php-fpm-www.conf /usr/local/etc/php-fpm.d/www.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY run.sh /root/run.sh

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
  && chmod a+x /root/run.sh \
  && apt-get -y remove $DEPENDENCIES \
  && apt-get purge -y --auto-remove \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/pear ~/.pearrc \
  && rm -rf $WORKING_DIR

EXPOSE 80
EXPOSE 8085
EXPOSE 9000

CMD ["/bin/bash", "/root/run.sh"]
