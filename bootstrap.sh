#!/bin/sh

function _log() {
	echo "$1"
}

function log_error() {
	_log "[ERROR] $1"
}

function log_info() {
	_log "[INFO] $1"
}

function log_debug() {
	if [[ ! -z "$DEBUG" ]]; then
		_log "[DEBUG] $1"
	fi
}

# Fail on error
set -e

if uname -a | grep 'Darwin' &> /dev/null; then
	OS='Darwin'
elif [ -f /proc/version ] && cat /proc/version | grep Ubuntu &> /dev/null; then
	OS='Ubuntu'
else
	OS='Unknown'
fi

log_info "Set OS: $OS"

log_info "Testing sudo: $(sudo echo 'Works' || echo 'Failed')" 

if [ ! -z $(which python3) ]; then
	PYTHON=$(which python3)
        log_debug "found python: $PYTHON"
	if [ 'Ubuntu' == $OS ]; then
		# venv and apt modules are not installed by default in Ubuntu
		sudo apt-get install -y python3-venv python3-apt
	fi
	VENV="$(which python3) -m venv"
elif [ ! -z $(which python2) ]; then
	PYTHON=$(which python2)
        log_debug "found python: $PYTHON"
	if [ 'Ubuntu' == $OS ]; then
		# venv and apt modules are not installed by default in Ubuntu
		sudo apt-get install -y python-pip python-virtualenv
	elif [ 'Darwin' == $OS ]; then
		sudo pip install virtualenv
	fi
	VENV="$(which virtualenv) -p $PYTHON"
# elif [ ! -z PYTHON=$(which python) ]; then
# 	PYTHON=$(which python)
else
	log_error "no python3 found in PATH: $PATH"
	exit 1
fi


log_info "found python at $PYTHON"

if [ -z $HOME ]; then
	HOME=~
fi


log_info "Creating ansible venv at $HOME/.venv/tools"
mkdir -p $HOME/.venv
if [ ! -f $HOME/.venv/tools/bin/activate ]; then
	$VENV $HOME/.venv/tools
fi
source $HOME/.venv/tools/bin/activate

if [ ! -f $HOME/.venv/tools/bin/pipenv ]; then
	log_info "Install pre-requisites"
	pip install --upgrade pip wheel setuptools pbr pipenv
fi

log_info "Install ansible"
pipenv install ansible virtualenvwrapper

log_info "Run ansible-playbook to install packages"
ANSIBLE_CMD="ansible-playbook --connection local install-packages.yaml -v"
if [ 'Ubuntu'=$OS ]; then
	$ANSIBLE_CMD -e "ansible_python_interpreter=$PYTHON"
	RET_VAL=$?
else
	$ANSIBLE_CMD
	RET_VAL=$?
fi

exit $RET_VAL

