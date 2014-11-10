FROM ubuntu:14.04
MAINTAINER nabezokodaikon

ENV DEBIAN_FRONTEND noninteractive
ENV NGINX_VER 1.7.4

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

RUN apt-get install -y lua5.1 liblua5.1-0 liblua5.1-0-dev
RUN ln -s /usr/lib/x86_64-linux-gnu/liblua5.1.so /usr/lib/liblua.so
ENV LUA_LIB /usr/lib
ENV LUA_INC /usr/include/lua5.1

RUN mkdir /root/build
WORKDIR /root/build

RUN wget -O ngx_devel_kit.tar.gz https://github.com/simpl/ngx_devel_kit/archive/v0.2.19.tar.gz
RUN wget -O lua-nginx-module.tar.gz https://github.com/openresty/lua-nginx-module/archive/v0.9.12.tar.gz
RUN wget http://nginx.org/download/nginx-${NGINX_VER}.tar.gz

RUN tar xvfz ngx_devel_kit.tar.gz
RUN tar xvfz lua-nginx-module.tar.gz
RUN tar xvfz nginx-${NGINX_VER}.tar.gz

WORKDIR /root/build/nginx-${NGINX_VER}
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
    --add-module=/root/build/ngx_devel_kit-0.2.19 \
    --add-module=/root/build/lua-nginx-module-0.9.12

RUN make
RUN make install

WORKDIR /
RUN rm -rf /root/build

RUN sed -ri 's/^error_log  \/var\/log\/nginx\/error.log warn;/error_log  \/var\/log\/nginx\/error.log debug;/g' /etc/nginx/nginx.conf

RUN groupadd nginx
RUN useradd -g nginx nginx
RUN usermod -s /bin/false nginx
RUN mkdir /var/cache/nginx
RUN chown nginx:nginx /var/cache/nginx

RUN mkdir /etc/nginx/certs
RUN openssl genrsa -out /etc/nginx/certs/ssl.key 2048
RUN openssl req -new -newkey rsa:4096 -days 36500 -nodes -subj "/C=/ST=/L=/O=/CN=nabezokodaikon" -keyout /etc/nginx/certs/ssl.key -out /etc/nginx/certs/ssl.csr
RUN openssl x509 -req -days 36500 -in /etc/nginx/certs/ssl.csr -signkey /etc/nginx/certs/ssl.key -out /etc/nginx/certs/ssl.crt
RUN chmod -R 644 /etc/nginx

VOLUME ["/var/log/nginx"] 

# default
ADD ./nginx.conf /etc/nginx/nginx.conf
EXPOSE 80

# gitbucket
ADD ./conf.d/gitbucket.conf /etc/nginx/conf.d/gitbucket.conf
EXPOSE 8080

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]

