#!/bin/bash

if [ -d "${PWD}/log" ]; then
    echo "log directory exists."
else
    echo "log directory create."
    mkdir ${PWD}/log
fi

docker stop nginx
docker rm nginx
docker run --name nginx --link gitbucket:gitbucket -v ${PWD}/log:/var/log/nginx -d -p 80:80 -p 8080:8080 -t nabezokodaikon/ubuntu:nginx
