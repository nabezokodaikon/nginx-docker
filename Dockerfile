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

VOLUME ["/var/log/nginx"] 

ADD ./conf.d/gitbucket.conf /etc/nginx/conf.d/gitbucket.conf

EXPOSE 80

CMD ["/usr/sbin/nginx", "-g", "daemon off;"]

