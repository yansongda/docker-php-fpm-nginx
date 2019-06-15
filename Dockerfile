FROM php:7.2.18-fpm

LABEL maintainer="yansongda <me@yansongda.cn>"

ENV TZ=Asia/Shanghai
ENV NGINX_VERSION   1.16.0

# php 
RUN apt-get update \
  && apt-get install -y libwebp-dev libmcrypt-dev libmemcached-dev libbz2-dev libpng-dev \
  && apt-get install -y libxpm-dev librabbitmq-dev libfreetype6-dev libjpeg-dev \
  && apt-get install -y curl gnupg git wget \
  && pecl install -o -f mongodb swoole redis memcached mcrypt amqp \
  && docker-php-ext-configure gd --with-gd --with-webp-dir --with-jpeg-dir \
      --with-png-dir --with-zlib-dir --with-xpm-dir --with-freetype-dir \
      --enable-gd-native-ttf \
  && docker-php-ext-install opcache bcmath bz2 gd iconv mysqli pdo pdo_mysql zip sockets \
  && docker-php-ext-enable opcache redis memcached mongodb swoole mcrypt amqp \
  && curl https://dl.laravel-china.org/composer.phar -o /usr/local/bin/composer \
  && chmod a+x /usr/local/bin/composer \
  && composer config -g repo.packagist composer https://packagist.laravel-china.org \
  && composer selfupdate

# nginx

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log



# 自定义
WORKDIR /www

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
  && apt-get -y remove libmcrypt-dev libmemcached-dev mcrypt libbz2-dev libpng-dev libjpeg-dev \
  && apt-get purge -y --auto-remove \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/pear ~/.pearrc

COPY sources.list /etc/apt/sources.list
COPY php.ini /usr/local/etc/php/conf.d/
COPY run.sh /root/run.sh

EXPOSE 80
EXPOSE 9000

CMD ["/bin/bash", "/root/run.sh"]
