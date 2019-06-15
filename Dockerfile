FROM php:7.2.18-fpm

LABEL maintainer="yansongda <me@yansongda.cn>"

ENV TZ=Asia/Shanghai
ENV NGINX_VERSION   1.16.0

# php 
RUN apt-get update && apt-get install -y libmcrypt-dev libmemcached-dev mcrypt libbz2-dev libpng-dev libjpeg-dev \
  && pecl install -o -f mongodb swoole redis mcrypt memcached \
  && docker-php-ext-enable mongodb swoole redis mcrypt memcached \
  && docker-php-ext-install bcmath opcache bz2 gd iconv mysqli pdo pdo_mysql zip \
  && curl https://dl.laravel-china.org/composer.phar -o /usr/local/bin/composer \
  && chmod a+x /usr/local/bin/composer \
  && composer config -g repo.packagist composer https://packagist.laravel-china.org \
  && composer selfupdate

# nginx

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

# 自定义
WORKDIR /www

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
  && apt-get -y remove libmcrypt-dev libmemcached-dev mcrypt libbz2-dev libpng-dev libjpeg-dev \
  && apt-get purge -y --auto-remove \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/pear ~/.pearrc

COPY sources.list /etc/apt/sources.list
COPY php.ini /usr/local/etc/php/conf.d/
