#!/bin/bash

docker container stop $(docker ps | awk '/ansible-docker/{ print $1 }') 
docker container rm $(docker ps -a | awk '/ansible-docker/{ print $1 }')

docker image rm ansible-docker/master
docker image rm ansible-docker/worker

docker container prune -f && docker image prune -f

rm -rf ./ansible/inventory
rm -rf ./ansible/ansible.cfg