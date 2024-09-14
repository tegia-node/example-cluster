#!/bin/bash

source ./const.sh
source ./params.sh

# ////////////////////////////////////////////////////////////////////////////////////////
#
#  READ PARAMS
#
# ////////////////////////////////////////////////////////////////////////////////////////


read_val()
{
	read -rp "${1} [${GREEN}${2}${RESET}]: " _value
	if [[ -z "$_value" ]]; then
		_value=${2}
	fi
	echo ${_value}
}


# ////////////////////////////////////////////////////////////////////////////////////////
#
#  GET LOCAL MYSQL ROOT PASSWORD
#
# ////////////////////////////////////////////////////////////////////////////////////////


mysql_debian_password()
{
    # Получаем пароль от MySQL
    string=$(sudo cat /etc/mysql/debian.cnf)
    regsubstring="password"
    passwd="${string#*password}"
    passwd="${passwd%%socket*}"
    len="$((${#passwd}-4))"
    passwd="${passwd:3:$len}"
    echo $passwd
}

# ////////////////////////////////////////////////////////////////////////////////////////
#
# INSTALL DATA
#
# ////////////////////////////////////////////////////////////////////////////////////////

#
# $2 - data nema
# $1 - repository json info
#

tegia_data_install()
{
	local NAME=${1}
	local REPOSITORY=${2}

	#
	# CHECK INSTALL
	#
	
	if [ -d  ${ROOT_PATH}/data/${NAME}/ ] 
	then
		echo "${_OK_}data '${YELLOW}${NAME}${RESET}' is already installed"
		return 0
	fi

	#echo "${REPOSITORY}"

	URL=$(echo "${REPOSITORY}" | jq -r '.repository.url')
	BRAHCH=$(echo "${REPOSITORY}" | jq -r '.repository.branch')

	cd ${ROOT_PATH}/data/
	git clone ${URL} ${NAME} -b ${BRAHCH}

	echo "${_OK_}data '${YELLOW}${NAME}${RESET}' clone & checkout"
	return 0
}


# ////////////////////////////////////////////////////////////////////////////////////////
#
# INSTALL CONFIGURATIONS
#
# ////////////////////////////////////////////////////////////////////////////////////////

#
# $1 - configuration name
# $2 - github url
# $3 - branch name
# $4 - params json
#

tegia_conf_install()
{
	local CONF_NAME=$1
	local CONF_GIT_URL=$2
	local CONF_BRANCH_NAME=$3
	local CONF_CATALOG="$1@$3"
	local PARAMS=$4

	#
	# CHECK INSTALL
	#
	
	if [ -d  ${ROOT_PATH}/configurations/$CONF_CATALOG/ ] 
	then
		echo "${_OK_}configuration '${YELLOW}${CONF_CATALOG}${RESET}' is already installed"
		return 0
	fi

	echo " "
	echo "------------------------------------------------------------"
	echo "INIT CONFIGURATION: ${GREEN}${CONF_CATALOG}${RESET}"
	echo "------------------------------------------------------------"
	echo " "

	#
	# SOURSE CODE
	#

	cd ${ROOT_PATH}/configurations/
	git clone ${CONF_GIT_URL} ${CONF_CATALOG} -b ${CONF_BRANCH_NAME}

	#cd ${ROOT_PATH}/configurations/$CONF_CATALOG/
	#git checkout $CONF_BRANCH_NAME

	echo "${_OK_}configuration '${YELLOW}${CONF_NAME}${RESET}' clone & checkout"

	#
	# DATABASE
	#

	for file in ${ROOT_PATH}/configurations/${CONF_CATALOG}/sql/install/*.sql
	do
		if [ -f "$file" ]
		then
			echo "      [apply] $file"
			cp "$file" "$file"_tmp
			sed -i -e "s|{DB_PREFIX}|$MYSQL_DB_PREFIX|g" "$file"_tmp
			mysql --defaults-extra-file=${CLUSTER_PATH}/configurations/mysql.cnf < "$file"_tmp
			rm "$file"_tmp
		fi
	done

	echo "${_OK_}init database for '$CONF_NAME'"

	#
	# CONFIG
	#

	local CONFIG=$(init_config_file "${CLUSTER_PATH}/.default/configurations/${CONF_NAME}.json" "${PARAMS}")

	# echo "${CONFIG}"
	echo "${CONFIG}" > "${CLUSTER_PATH}/configurations/${CONF_NAME}.json"

	#
	# INSTAAL
	#

	cd ${ROOT_PATH}/configurations/${CONF_CATALOG}/bin
	bash ./install.sh

	echo " "
	echo "${_OK_}configuration '${YELLOW}${CONF_CATALOG}${RESET}' installed successfull"

	return 0
}
