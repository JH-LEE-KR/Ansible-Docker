# Ansible-Docker

Building an environment for <a href="https://www.ansible.com/">Ansible</a> requires multiple computers, either physical or virtual, such as VM, or Cloud. <br>
However, it is very complex and expensive, but <a href="https://www.docker.com/">Docker</a> makes it easy, and fast, with no additional cost. <br>
So we use Docker to build an ansible environment using the code in this repository.


## Requirements
Docker <br>
https://docs.docker.com/engine/install/

## Usage
First, clone the repository locally:
```
git clone https://github.com/JH-LEE-KR/Ansible-Docker
cd Ansible-Docker
```
Then, just run the script:
```
bash setup.sh
```
The arguments below can be changed:
```
setup.sh
REPLICAS=${REPLICAS:-3}                         # Number of worker nodes
PORT="${PORT:-30080}"                           # Port to expose master node on local machine
ANSIBLE_USER="sadmin"                           # Username for ssh & ansible

./ansible/ansible.sh
ANSIBLE_VERSION="${ANSIBLE_VERSION:-4.8.0}"     # Ansible version to install
ANSIBLE_TOO_NEW="${ANSIBLE_TOO_NEW:-5.0.0}"     # Ansible version too new
VENV_DIR="${VENV_DIR:-/opt/ansible-docker/env}" # Path to python virtual environment to create
```
After the script is finished:
```
ssh ${ANSIBLE_USER}@127.0.0.1 -p ${PORT}"
```
All ready to use ansible. <br><br>
You can learn how to use it easily using `/ansible/playbooks/example-0*.yml`, <br>
and can experiment, practice ansible in your own way.

## Tested Architecture
- Ubuntu 20.04 / amd64 / docker engine 20.10
- WSL2 Ubuntu 20.04 / amd64 / docker engine 20.10
- OSX 13.4/ arm64 / docker engine 24.0

## Restrictions
Some features may be limited because ansible is installed on docker ubuntu.
