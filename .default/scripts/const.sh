#!/bin/bash

export RED=`tput setaf 1`
export GREEN=`tput setaf 2`
export YELLOW=`tput setaf 3`
export BLUE=`tput setaf 4`
export RESET=`tput sgr0`

export _OK_="${GREEN}[OK]  ${RESET}"
export _ERR_="${RED}[ERR] ${RESET}"

#
# DEFAULT VALUES
#

CLUSTER_NAME="EXAMPLE"

if [ -z ${TEGIA_HOST} ]
then
	TEGIA_HOST=example.tegia.local
fi

if [ -z ${TEGIA_APP} ]
then
	TEGIA_APP=example_local
fi

if [ -z ${TEGIA_FCGI_PORT} ]
then
	TEGIA_FCGI_PORT=9090
fi

if [ -z ${TEGIA_AUTH} ]
then
	TEGIA_AUTH=id.tegia.ru
fi

if [ -z ${MYSQL_HOST} ]
then
	MYSQL_HOST=localhost
fi

if [ -z ${MYSQL_PORT} ]
then
	MYSQL_PORT=3306
fi

if [ -z ${MYSQL_DB_PREFIX} ]
then
	MYSQL_DB_PREFIX=example
fi

if [ -z ${MYSQL_USER} ]
then
	MYSQL_USER=tegia_example
fi
