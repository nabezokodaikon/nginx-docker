FROM ubuntu:14.04
MAINTAINER nabezokodaikon

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get install -y curl
RUN touch /etc/apt/sources.list.d/nginx.list
RUN echo "deb http://nginx.org/packages/ubuntu/ precise nginx" >> /etc/apt/sources.list.d/nginx.list
RUN echo "deb-src http://nginx.org/packages/ubuntu/ precise nginx" >> /etc/apt/sources.list.d/nginx.list
RUN curl http://nginx.org/keys/nginx_signing.key | apt-key add -
RUN apt-get update
RUN apt-get install -y nginx

RUN sed -ri 's/^error_log  \/var\/log\/nginx\/error.log warn;/error_log  \/var\/log\/nginx\/error.log debug;/g' /etc/nginx/nginx.conf

VOLUME ["/var/log/nginx"] 

# default
EXPOSE 80

# gitbucket
ADD ./conf.d/gitbucket.conf /etc/nginx/conf.d/gitbucket.conf
EXPOSE 8080

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]

