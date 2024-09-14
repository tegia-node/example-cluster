#!/bin/bash

cd ./.default/scripts/
source ./const.sh
cd ../..

echo " "
echo "------------------------------------------------------------"
echo "${CLUSTER_NAME}: ${GREEN} CLUSTER DEPLOYMENT ${RESET}"
echo "------------------------------------------------------------"
echo " "

cd ./.default/scripts/
source ./functions.sh
source ./params.sh
cd ../..

# /////////////////////////////////////////////////////////////////////////////////////////////////////
#
# PARAMS INIT
#
# /////////////////////////////////////////////////////////////////////////////////////////////////////

#
# READ PARAMS
#

PARAMS=$(get_params_data)
ask_user

#
# INIT MAIN CONFIG
#

CONFIG=$(init_config_file "${CLUSTER_PATH}/.default/config.json" "${PARAMS}")

#
# Проверяем наличие ключа "domains"
#

if echo "$PARAMS" | jq -e '.domains' > /dev/null; then

	INIT=$(echo "$PARAMS" | jq '{
	"init": [
		.domains[] | {
		"actor": "http/listener",
		"action": "/domain/add",
		"data": .
		}
	]
	}')

	CONFIG=$(json_add_field "$CONFIG" "$INIT")

fi

echo "$CONFIG" > "${CLUSTER_PATH}/config.json"

#
# SAVE mysql.cnf FILE
#

mkdir -p "${CLUSTER_PATH}/configurations"

MYSQL_HOST=$(echo "$PARAMS" | jq -r '.mysql.host')
MYSQL_PORT=$(echo "$PARAMS" | jq -r '.mysql.port')
MYSQL_DB_PREFIX=$(echo "$PARAMS" | jq -r '.mysql.prefix')
MYSQL_USER=$(echo "$PARAMS" | jq -r '.mysql.user')
MYSQL_PASSWORD=$(echo "$PARAMS" | jq -r '.mysql.password')

tee "${CLUSTER_PATH}/configurations/mysql.cnf" << EOF > /dev/null
[mysql]
host=$MYSQL_HOST
port=$MYSQL_PORT
user=$MYSQL_USER
password=$MYSQL_PASSWORD
EOF


# /////////////////////////////////////////////////////////////////////////////////////////////////////
#
# TEGIA NODE INSTALL
#
# /////////////////////////////////////////////////////////////////////////////////////////////////////


REPOS_URL=$(jq -r '.["tegia-node"].repository.url' ${CLUSTER_PATH}/config.json)
REPOS_BRANCH=$(jq -r '.["tegia-node"].repository.branch' ${CLUSTER_PATH}/config.json)

#echo "REPOS_URL: $REPOS_URL"
#echo "REPOS_BRANCH: $REPOS_BRANCH"

if ! [ -d  ${ROOT_PATH}/tegia-node@${REPOS_BRANCH}/ ]
then
	cd ${ROOT_PATH};
	git clone $REPOS_URL "tegia-node@${REPOS_BRANCH}" 
	cd ${ROOT_PATH}/tegia-node@${REPOS_BRANCH}/
	git checkout ${REPOS_BRANCH}

	bash ./install.sh
else
	echo "${_OK_}${YELLOW}tegia node${RESET} is already installed"
fi

sudo ln -fs "${ROOT_PATH}/tegia-node@${REPOS_BRANCH}/build/tegia-node" "${CLUSTER_PATH}/tegia-node"


# /////////////////////////////////////////////////////////////////////////////////////////////////////
#
# INIT MYSQL USER
#
# /////////////////////////////////////////////////////////////////////////////////////////////////////


export MYSQL_PWD=$(mysql_debian_password)

iffinduser="$(mysql -u debian-sys-maint --execute="SELECT host,user FROM mysql.user WHERE host = '$MYSQL_HOST' AND user = '$MYSQL_USER';")"
if [[ "${#iffinduser}" != 0 ]]
then
	mysql -u debian-sys-maint --port=$MYSQL_PORT --execute="DROP USER '$MYSQL_USER'@'$MYSQL_HOST';"
fi

cp "${CLUSTER_PATH}/.default/sql/user.sql" "${CLUSTER_PATH}/user.sql_tmp"
sed -i -e "s|{MYSQL_HOST}|$MYSQL_HOST|g" "${CLUSTER_PATH}/user.sql_tmp"
sed -i -e "s|{MYSQL_USER}|$MYSQL_USER|g" "${CLUSTER_PATH}/user.sql_tmp"
sed -i -e "s|{MYSQL_PASSWORD}|$MYSQL_PASSWORD|g" "${CLUSTER_PATH}/user.sql_tmp" 
sed -i -e "s|{MYSQL_DB_PREFIX}|$MYSQL_DB_PREFIX|g" "${CLUSTER_PATH}/user.sql_tmp"

mysql -u debian-sys-maint --port=$MYSQL_PORT < ${CLUSTER_PATH}/user.sql_tmp
rm ${CLUSTER_PATH}/user.sql_tmp

echo -e "${_OK_}user '${YELLOW}${MYSQL_USER}${RESET}' is created on MySQL"


# /////////////////////////////////////////////////////////////////////////////////////////////////////
#
# INSTALL CONFIGURATIONS
#
# /////////////////////////////////////////////////////////////////////////////////////////////////////


cd ${ROOT_PATH}/configurations

jq -c '.configurations[]' ${CLUSTER_PATH}/config.json | while read -r item; do
    file=$(echo "$item" | jq -r '.file')
    isload=$(echo "$item" | jq -r '.isload')
    name=$(echo "$item" | jq -r '.name')
	repository=$(echo "$item" | jq -r '.repository.url')
	branch=$(echo "$item" | jq -r '.repository.branch')

    # Вывод значений
    # echo "config:     $file"
    # echo "is load:    $isload"
    # echo "name:       $name"
	# echo "repository: $repository"
	# echo "branch:     $branch"
    # echo "------------------"

	PARAMS=$(json_update_element "${PARAMS}" ".paths.configuration" "$name")
	PARAMS=$(json_update_element "${PARAMS}" ".paths.branch" "$branch")

	# echo "${PARAMS}"

	tegia_conf_install $name $repository $branch "${PARAMS}"

	# echo "${_OK_}configuration '$name@$branch' installed successfull"

done

# /////////////////////////////////////////////////////////////////////////////////////////////////////
#
# INSTALL DATA
#
# /////////////////////////////////////////////////////////////////////////////////////////////////////

mkdir -p "${ROOT_PATH}/data"
cd ${ROOT_PATH}/data

if echo "${CONFIG}" | jq -e '.data' > /dev/null; then

	_params=$(echo "${CONFIG}" | jq -r '.data | keys[]')  # Получаем список параметров

	# Цикл по каждому параметру
	for param in $_params; do
		# Сохраняем имя параметра
		param_name="$param"
		
		# Сохраняем объект параметра
		param_object=$(echo "${CONFIG}" | jq -r ".data[\"$param\"]")
		
		# Вывод для проверки
		#echo "Имя параметра: $param_name"
		#echo "$param_object"

		tegia_data_install "${param_name}" "${param_object}"
	done

#	tegia_clode_data()
#	CONFIG=$(json_add_field "$CONFIG" "$INIT")

fi


# /////////////////////////////////////////////////////////////////////////////////////////////////////
#
# NGINX VIRTUAL HOST
#
# /////////////////////////////////////////////////////////////////////////////////////////////////////


TEGIA_FCGI_HOST=$(echo "$PARAMS" | jq -r '.http.host')

#
# Проверяем наличие ключа "domains"
#

if echo "$PARAMS" | jq -e '.domains' > /dev/null; then

	jq -c '.domains[]' ${CLUSTER_PATH}/params.json | while read -r item; do
		#echo "$item"
		HOST=$(echo "$item" | jq -r '.domain')

		#
		# HOST
		#

		sudo cp "${CLUSTER_PATH}/.default/nginx/nginx.conf" "/etc/nginx/sites-available/${HOST}.conf"
		sudo sed -i -e "s|{TEGIA_HOST}|$HOST|g" "/etc/nginx/sites-available/${HOST}.conf"
		sudo sed -i -e "s|{TEGIA_PORT}|$TEGIA_FCGI_HOST|g" "/etc/nginx/sites-available/${HOST}.conf"

		sudo ln -fs "/etc/nginx/sites-available/${HOST}.conf" "/etc/nginx/sites-enabled/${HOST}.conf"
		sudo sh -c -e "echo '127.0.0.1 $HOST' >> /etc/hosts";

		#
		# JWT
		#

		echo " "
		echo "${YELLOW}JWT KEYS${RESET}"
		echo " "

		cd ${CLUSTER_PATH}
		bash ./.default/scripts/jwt.sh ${HOST}

	done

fi



echo " "
echo "${GREEN}Установка выполнена успешно${RESET}"
echo " "

exit 0