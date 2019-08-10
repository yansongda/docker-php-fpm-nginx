FROM registry.cn-shenzhen.aliyuncs.com/yansongda/php-fpm:7.2

LABEL maintainer="yansongda <me@yansongda.cn>"

# ENV for Global 
ENV DEPENDENCIES curl gnupg git wget gcc 
ENV WORKING_DIR /www/software

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
  && apt-get install -y $DEPENDENCIES \
  && mkdir -p $WORKING_DIR && cd $WORKING_DIR \
  && git clone https://github.com/chuan-yun/Molten.git \
  && cd $WORKING_DIR/Molten && phpize && ./configure && make && make install\
  && mkdir -p /var/log/tracing && chmod -R 777 /var/log/tracing \
# INSTALL Nginx
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

COPY php-ext-molten.ini /usr/local/etc/php/conf.d/
COPY nginx.conf /etc/nginx/nginx.conf
COPY run.sh /root/run.sh

RUN chmod a+x /root/run.sh \
  && apt-get -y remove $DEPENDENCIES \
  && apt-get purge -y --auto-remove \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /tmp/pear ~/.pearrc \
  && rm -rf $WORKING_DIR

EXPOSE 80
EXPOSE 8085

CMD ["/bin/bash", "/root/run.sh"]
