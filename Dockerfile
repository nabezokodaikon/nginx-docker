FROM ubuntu:14.04
MAINTAINER nabezokodaikon

ENV DEBIAN_FRONTEND noninteractive
ENV NGINX_VERSION 1.7.4

# リポジトリを日本語向けに変更します。
RUN sed -e 's;http://archive;http://jp.archive;' -e 's;http://us\.archive;http://jp.archive;' -i /etc/apt/sources.list
RUN [ ! -x /usr/bin/wget ] && \
        apt-get update && \
        apt-get install -y wget && \
        touch /.get-wget
RUN wget -q https://www.ubuntulinux.jp/ubuntu-ja-archive-keyring.gpg -O- | apt-key add - && \
    wget -q https://www.ubuntulinux.jp/ubuntu-jp-ppa-keyring.gpg -O- | apt-key add - && \
    wget https://www.ubuntulinux.jp/sources.list.d/trusty.list -O /etc/apt/sources.list.d/ubuntu-ja.list

# システムを更新します。
RUN apt-get update && \
    apt-get dist-upgrade -y
RUN apt-get upgrade

# タイムゾーンを日本標準時刻に設定します。
RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
RUN echo 'Asia/Tokyo' > /etc/timezone

# ハードウェアクロックをローカルタイムに設定します。
RUN sed -e 's;UTC=yes;UTC=no;' -i /etc/default/rcS

RUN apt-get install -y build-essential
RUN apt-get install -y libpcre3 libpcre3-dev
RUN apt-get install -y zlib1g zlib1g-dev
RUN apt-get install -y openssl libssl-dev
RUN apt-get install -y curl

RUN apt-get install -y lua5.1 liblua5.1-0 liblua5.1-0-dev
RUN ln -s /usr/lib/x86_64-linux-gnu/liblua5.1.so /usr/lib/liblua.so
ENV LUA_LIB=/usr/lib
ENV LUA_INC=/usr/include/lua5.1

RUN mkdir /root/build
RUN cd /root/build

RUN curl -O https://github.com/simpl/ngx_devel_kit/archive/v0.2.19.tar.gz
RUN curl -O https://github.com/openresty/lua-nginx-module/archive/v0.9.12.tar.gz
RUN curl -O https://github.com/openresty/lua-nginx-module/archive/v0.9.7.tar.gz
RUN curl -O http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz

RUN tar zxf nginx_devkit.tar.gz
RUN tar zxf nginx_lua.tar.gz
RUN tar zxf nginx-$NGINX_VERSION.tar.gz

RUN cd nginx-$NGINX_VERSION/
RUN ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
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
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-file-aio \
    --with-http_spdy_module \
    --with-cc-opt='-g -O2 -fstack-protector \
    --param=ssp-buffer-size=4 -Wformat -Wformat-security -Wp,-D_FORTIFY_SOURCE=2' \
    --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed' \
    --with-ipv6 \
    --add-module=../ngx_devel_kit-0.2.19 \
    --add-module=../lua-nginx-module-0.97

RUN make
RUN make install

RUN rm -rf /root/build

RUN sed -ri 's/^error_log  \/var\/log\/nginx\/error.log warn;/error_log  \/var\/log\/nginx\/error.log debug;/g' /etc/nginx/nginx.conf

VOLUME ["/var/log/nginx"] 

# default
EXPOSE 80

# gitbucket
ADD ./conf.d/gitbucket.conf /etc/nginx/conf.d/gitbucket.conf
EXPOSE 8080

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]

