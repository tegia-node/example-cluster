#!/bin/bash

source ./const.sh
source ./params.sh 2>/dev/null


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
# INSTALL CONFIGURATIONS
#
# ////////////////////////////////////////////////////////////////////////////////////////

#
# $1 - configuration name
# $2 - github url
# $3 - branch name
#

tegia_conf_install()
{
	echo " "
	echo "${YELLOW}CONFIGURATION ${1}${RESET}"
	echo " "

	CONF_NAME=$1
	CONF_GIT_URL=$2
	CONF_BRANCH_NAME=$3
	CONF_CATALOG="$1@$3"

	#
	# CHECK INSTALL
	#
	
	if [ -d  ${root_folder}/configurations/$CONF_CATALOG/ ] 
	then
		echo "${_OK_}configuration for '$CONF_CATALOG' is already installed"
		return 0
	fi

	#
	# SOURSE CODE
	#

	cd ${root_folder}/configurations/
	git clone $CONF_GIT_URL $CONF_CATALOG

	cd ${root_folder}/configurations/$CONF_CATALOG/
	git checkout $CONF_BRANCH_NAME

	echo "${_OK_}source code '$CONF_NAME' clone & checkout"

	#
	# DATABASE
	#

	for file in ${root_folder}/configurations/${CONF_CATALOG}/sql/install/*.sql
	do
		if [ -f "$file" ]
		then
			echo "      [apply] $file"
			cp "$file" "$file"_tmp
			sed -i -e "s|{DB_PREFIX}|$MYSQL_DB_PREFIX|g" "$file"_tmp
			mysql --defaults-extra-file=${tep_folder}/configurations/mysql.cnf < "$file"_tmp
			rm "$file"_tmp
		fi
	done

	echo "${_OK_}init database for '$CONF_NAME'"

	#
	# CONFIG
	#

	cp "${tep_folder}/.default/configurations/${CONF_NAME}.json" "${tep_folder}/configurations/$CONF_NAME.json"
	
	sed -i -e "s|{PATH_TO_CONFIG}|${root_folder}/configurations/$CONF_CATALOG|g" "${tep_folder}/configurations/$CONF_NAME.json"
	
	sed -i -e "s|{MYSQL_DB_PREFIX}|$MYSQL_DB_PREFIX|g" "${tep_folder}/configurations/$CONF_NAME.json"
	sed -i -e "s|{MYSQL_HOST}|$MYSQL_HOST|g" "${tep_folder}/configurations/$CONF_NAME.json"
	sed -i -e "s|{MYSQL_PORT}|$MYSQL_PORT|g" "${tep_folder}/configurations/$CONF_NAME.json"
	sed -i -e "s|{MYSQL_USER}|$MYSQL_USER|g" "${tep_folder}/configurations/$CONF_NAME.json"
	sed -i -e "s|{MYSQL_PASSWORD}|$MYSQL_PASSWORD|g" "${tep_folder}/configurations/$CONF_NAME.json" 

	sed -i -e "s|{TEGIA_PORT}|$TEGIA_FCGI_PORT|g" "${tep_folder}/configurations/$CONF_NAME.json" 
	sed -i -e "s|{TEGIA_HOST}|$TEGIA_HOST|g" "${tep_folder}/configurations/$CONF_NAME.json" 
	sed -i -e "s|{TEGIA_APP}|$TEGIA_APP|g" "${tep_folder}/configurations/$CONF_NAME.json" 

	echo -e "${_OK_}create './configurations/$CONF_NAME.json'"

	#
	# INSTAAL
	#

	cd ${root_folder}/configurations/$CONF_CATALOG/bin
	bash ./install.sh

	echo "${_OK_}configuration '$CONF_NAME' installed successfull"
}
