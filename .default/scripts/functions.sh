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

	#
	# CHECK INSTALL
	#
	
	if [ -d  ${root_folder}/configurations/$1/ ] 
	then
		echo "${_OK_}configuration for '$1' is already installed"
		return 0
	fi

	#
	# SOURSE CODE
	#

	cd ${root_folder}/configurations/
	git clone $2

	cd ${root_folder}/configurations/$1/
	git checkout $3

	echo "${_OK_}source code '$1' clone & checkout"

	#
	# DATABASE
	#

	for file in ${root_folder}/configurations/${1}/sql/install/*.sql
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

	echo "${_OK_}init database for '$1'"

	#
	# CONFIG
	#

	cp "${tep_folder}/.default/configurations/${1}.json" "${tep_folder}/configurations/$1.json"
	
	sed -i -e "s|{PATH_TO_CONFIG}|${root_folder}/configurations/$1-conf|g" "${tep_folder}/configurations/$1.json"
	sed -i -e "s|{MYSQL_DB_PREFIX}|$MYSQL_DB_PREFIX|g" "${tep_folder}/configurations/$1.json"
	sed -i -e "s|{MYSQL_HOST}|$MYSQL_HOST|g" "${tep_folder}/configurations/$1.json"
	sed -i -e "s|{MYSQL_PORT}|$MYSQL_PORT|g" "${tep_folder}/configurations/$1.json"
	sed -i -e "s|{MYSQL_USER}|$MYSQL_USER|g" "${tep_folder}/configurations/$1.json"
	sed -i -e "s|{MYSQL_PASSWORD}|$MYSQL_PASSWORD|g" "${tep_folder}/configurations/$1.json" 
	sed -i -e "s|{TEGIA_PORT}|$TEGIA_FCGI_PORT|g" "${tep_folder}/configurations/$1.json" 

	sed -i -e "s|{TEGIA_HOST}|$TEGIA_HOST|g" "${tep_folder}/configurations/$1.json" 
	sed -i -e "s|{TEGIA_APP}|$TEGIA_APP|g" "${tep_folder}/configurations/$1.json" 

	echo -e "${_OK_}create './configurations/$1.json'"

	#
	# INSTAAL
	#

	cd ${root_folder}/configurations/$1/bin
	bash ./install.sh

	echo "${_OK_}configuration '$1' installed successfull"
}
