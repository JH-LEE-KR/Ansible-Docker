#!/bin/bash

# Configuration
printf "Password for SSH and Ansible: "
read -s PASSWORD
echo
PASSWORD=${PASSWORD}                                                # Password for ssh & ansible
REPLICAS=${REPLICAS:-3}                                             # Number of worker nodes
PORT="${PORT:-30080}"                                               # Port to expose master node on local machine
ANSIBLE_USER="sadmin"                                               # Username for ssh & ansible
ANSIBLE_DIR="$(pwd)/ansible"                                        # Directory to store ansible configuration and inventory
CONTAINER_LIST=(master)
for ((i=1; i<=$REPLICAS; i++)); do CONTAINER_LIST+=(worker$i); done # List of container names to prevent conflicts with other running containers

# Check that all containers in the predefined container list are in a running state
is_running() {
    for container in ${CONTAINER_LIST[@]}
    do
        if ! [ $(docker container inspect -f '{{.State.Status}}' $container) == "running" ]; then
            return 1
        fi
    done

    return 0
}

# Build docker images
if command -v docker &> /dev/null ; then
    echo "Build docker images"

    docker build --tag ansible-docker/master \
        --file ./master/Dockerfile . \
        --build-arg PASSWORD=${PASSWORD} \
        --build-arg ANSIBLE_USER=${ANSIBLE_USER}

    docker build --tag ansible-docker/worker \
        --file ./worker/Dockerfile . \
        --build-arg PASSWORD=${PASSWORD} \
        --build-arg ANSIBLE_USER=${ANSIBLE_USER}

else
    echo "ERROR: Unable to build docker image, 'docker' command not found"
    exit 1
fi

# Run docker containers
if (docker image inspect ansible-docker/master >/dev/null 2>&1 \
        && docker image inspect ansible-docker/worker >/dev/null 2>&1); then
    echo "Run docker containers"

    docker run -d \
        -p $PORT:22 \
        --hostname master \
        --name master \
        --mount type=bind,source=$ANSIBLE_DIR,target=/ansible \
        ansible-docker/master

    for ((i=1; i<=$REPLICAS; i++))
    do
        name="worker$i"
        docker run -d \
            --hostname $name \
            --name $name \
            ansible-docker/worker
    done
else
    echo "ERROR: Unable to find docker image, 'ansible-docker/master' or 'ansible-docker/worker'"
    exit 1
fi

# Create ansible inventory, ansible.cfg and add hosts to /etc/hosts
if is_running; then
    echo "Create ansible inventory, ansible.cfg and add hosts to /etc/hosts"

    touch $ANSIBLE_DIR/ansible.cfg
    echo "[defaults]"$'\n'"inventory = ./inventory"$'\n'"forks = 10" >> $ANSIBLE_DIR/ansible.cfg
    
    touch $ANSIBLE_DIR/inventory

    echo "[all]" >> $ANSIBLE_DIR/inventory
    for container in ${CONTAINER_LIST[@]}
    do
        ip=$(docker inspect -f '{{.NetworkSettings.Networks.bridge.IPAddress}}' $container)

        echo $container$'\t'ansible_host=$ip >> $ANSIBLE_DIR/inventory

        if ! [ $container == "master" ] ; then
            docker exec master /bin/bash -c "echo $ip$'\t'$container >> /etc/hosts"
        fi
    done
    echo $'\n'$'\n'"[all:vars]"$'\n'"# SSH User"$'\n'"ansible_user=$ANSIBLE_USER"$'\n'"ansible_ssh_private_key_file='/home/$ANSIBLE_USER/.ssh/id_rsa'" >> $ANSIBLE_DIR/inventory
else
    echo "ERROR: Docker Containers are not running"
    exit 1
fi

# Setup ansible
if [ -e ./ansible/ansible.sh ] && [ -e ./ansible/proxy.sh ]; then
    echo "Setup ansible"

    docker exec --user $ANSIBLE_USER master /bin/bash -c \
        "cd /ansible && chmod 755 ansible.sh proxy.sh && \
        bash ansible.sh"
else
    echo "ERROR: Unable to find 'ansible.sh' or 'proxy.sh'"
    exit 1
fi

# Set ssh for ansible
if [ -f ./ansible/inventory ]; then
    echo "Set ssh for ansible"

    docker exec --user $ANSIBLE_USER master /bin/bash -c "/usr/bin/ssh-keygen -t rsa -b 4096 -f /home/$ANSIBLE_USER/.ssh/id_rsa -N ''"

    for container in ${CONTAINER_LIST[@]}
    do
        docker exec --user $ANSIBLE_USER master /bin/bash -c \
            "/usr/bin/ssh-keyscan -t ecdsa $container >> /home/$ANSIBLE_USER/.ssh/known_hosts && \
            /usr/bin/sshpass -p $PASSWORD ssh-copy-id $ANSIBLE_USER@$container"
    done
else
    echo "ERROR: Unable to find ansible inventory"
    exit 1
fi

echo
echo "*** Ansible-Docker Setup Complete ***"
echo "To use Ansible-Docker, run: ssh ${ANSIBLE_USER}@127.0.0.1 -p ${PORT}"
echo