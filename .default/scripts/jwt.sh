#!/bin/bash

RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
RESET=`tput sgr0`


_OK_="${GREEN}[OK]  ${RESET}"
_ERR_="${RED}[ERR] ${RESET}"

tep_folder=$(realpath .)

# echo $1
# echo $tep_folder

if ! [ -d  ${tep_folder}/jwt_keys/ ]
then
	mkdir ${tep_folder}/jwt_keys/
fi

if ! [ -d  ${tep_folder}/jwt_keys/${1} ]
then
	mkdir ${tep_folder}/jwt_keys/${1}

	#
	# Key generate
	#

	cd ${tep_folder}/jwt_keys/${1}

	openssl genrsa -out jwtRS256.key 2048
	openssl rsa -in jwtRS256.key -outform PEM -pubout -out jwtRS256.key.pub
fi