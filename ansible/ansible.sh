#!/bin/bash 

# Determine current directory and root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Configuration
ANSIBLE_VERSION="${ANSIBLE_VERSION:-4.8.0}"     # Ansible version to install
ANSIBLE_TOO_NEW="${ANSIBLE_TOO_NEW:-5.0.0}"     # Ansible version too new
PIP="${PIP:-pip3}"                              # Pip binary to use
PYTHON_BIN="${PYTHON_BIN:-/usr/bin/python3}"    # Python3 path
VENV_DIR="${VENV_DIR:-/opt/ansible-docker/env}" # Path to python virtual environment to create

# Set distro-specific variables
PROXY_USE=`grep -v ^# ${SCRIPT_DIR}/proxy.sh 2>/dev/null | grep -v ^$ | wc -l`

# Disable interactive prompts from Apt
export DEBIAN_FRONTEND=noninteractive

# Exit if run as root
if [ $(id -u) -eq 0 ] ; then
    echo "Please run as a regular user"
    exit
fi

# Proxy wrapper
as_user(){
    if [ $PROXY_USE -gt 0 ] ; then
        cmd="bash -c '. ${SCRIPT_DIR}/proxy.sh && $@'"
    else
        cmd="bash -c '$@'"
    fi
    eval $cmd
}

# Create virtual environment and install python dependencies
if command -v virtualenv &> /dev/null ; then
    echo "Create virtual environment"
    sudo mkdir -p "${VENV_DIR}"
    sudo chown -R $(id -u):$(id -g) "${VENV_DIR}"
    deactivate nondestructive &> /dev/null
    virtualenv -q --python="${PYTHON_BIN}" "${VENV_DIR}"
    . "${VENV_DIR}/bin/activate"
    as_user "${PIP} install -q --upgrade pip"

    # Check for any installed ansible pip package
    if pip show ansible 2>&1 >/dev/null; then
        current_version=$(pip show ansible | grep Version | awk '{print $2}')
	echo "Current version of Ansible is ${current_version}"
	if "${PYTHON_BIN}" -c "from distutils.version import LooseVersion; print(LooseVersion('$current_version') >= LooseVersion('$ANSIBLE_TOO_NEW'))" | grep True 2>&1 >/dev/null; then
            echo "Ansible version ${current_version} too new for DeepOps"
	    echo "Please uninstall any ansible, ansible-base, and ansible-core packages and re-run this script"
	    exit 1
	fi
	if "${PYTHON_BIN}" -c "from distutils.version import LooseVersion; print(LooseVersion('$current_version') < LooseVersion('$ANSIBLE_VERSION'))" | grep True 2>&1 >/dev/null; then
	    echo "Ansible will be upgraded from ${current_version} to ${ANSIBLE_VERSION}"
	fi
    fi
    echo "Install ansible and required packages"
    as_user "${PIP} install -q --upgrade \
        ansible==${ANSIBLE_VERSION}"
else
    echo "ERROR: Unable to create Python virtual environment, 'virtualenv' command not found"
    exit 1
fi

# Add Ansible virtual env to PATH when using Bash
if [ -f "${VENV_DIR}/bin/activate" ] ; then
    . "${VENV_DIR}/bin/activate"
    ansible localhost -m lineinfile -a "path=$HOME/.bashrc create=yes mode=0644 backup=yes line='source ${VENV_DIR}/bin/activate'"
fi

