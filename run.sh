#!/bin/bash

if [ -d "${PWD}/log" ]; then
    echo "log directory exists."
else
    echo "log directory create."
    mkdir ${PWD}/log
fi

docker stop nginx
docker rm nginx
docker run --name nginx --link gitbucket:gitbucket -v ${PWD}/log:/var/log/nginx -d -p 50080:80 -p 58080:8080 -t nabezokodaikon/ubuntu:nginx
