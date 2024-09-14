#!/bin/bash

export RED=`tput setaf 1`
export GREEN=`tput setaf 2`
export YELLOW=`tput setaf 3`
export BLUE=`tput setaf 4`
export RESET=`tput sgr0`

export _OK_="${GREEN}[OK]  ${RESET}"
export _ERR_="${RED}[ERR] ${RESET}"

export CLUSTER_NAME="EXAMPLE"

export CLUSTER_PATH=$(realpath ../../)
export ROOT_PATH=$(realpath ../../../../)

export CONFIG_TEMPLATE_FILE="$CLUSTER_PATH/.default/config.json"
export CONFIG_FILE="$CLUSTER_PATH/config.json"

export PARAMS_TEMPLATE_FILE="$CLUSTER_PATH/.default/params.json"
export PARAMS_FILE="$CLUSTER_PATH/params.json"
