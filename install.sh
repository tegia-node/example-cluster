#!/bin/bash

cd ./.default/scripts/
source ./functions.sh
cd ../..

tep_folder=$(realpath ./)
root_folder=$(realpath ../../)

conf_path="";


echo " "
echo "------------------------------------------------------------"
echo "${CLUSTER_NAME}: ${GREEN} CLUSTER DEPLOYMENT ${RESET}"
echo "------------------------------------------------------------"
echo " "

mkdir -p ${tep_folder}/configurations


# ////////////////////////////////////////////////////////////////////////////////////////
#
# INSTALL QUESTIONS
#
# ////////////////////////////////////////////////////////////////////////////////////////

#
# NGINX HOST
#

# echo "${YELLOW}HOST${RESET}"
# echo " "

# echo "${YELLOW}leaks application${RESET}"
# LEAKS_HOST=$(read_val "Укажите виртуальный хост" ${LEAKS_HOST})
# LEAKS_APP=$(read_val "Укажите используемое для аутентификации имя приложения" ${LEAKS_APP})
# echo " "

# TEGIA_FCGI_PORT=$(read_val "Укажите порт для FCGI" ${TEGIA_FCGI_PORT})
# TEGIA_AUTH=$(read_val "Укажите используемый сервер аутентификации" ${TEGIA_AUTH})

#
# MYSQL CONNECTION
#

echo " "
echo "${YELLOW}MYSQL DB CONNECTION${RESET}"
echo " "

MYSQL_HOST=$(read_val "Укажите mysql host" ${MYSQL_HOST})
MYSQL_PORT=$(read_val "Укажите mysql port" ${MYSQL_PORT})
MYSQL_DB_PREFIX=$(read_val "Укажите db prefix" ${MYSQL_DB_PREFIX})
MYSQL_USER=$(read_val "Укажите mysql user" ${MYSQL_USER})

while [[ -z "$mysql_password" ]]; do
    read -srp "Укажите пароль для подключения к MySQL: " mysql_password
    if [[ -z "$mysql_password" ]]; then
        echo -e "\n${_ERR_}Пароль не может быть пустым"
    else
        break
    fi
done

MYSQL_PASSWORD=${mysql_password}

echo " "

#
# SAVE params.sh FILE
#

tee ./.default/scripts/params.sh << EOF > /dev/null
#!/bin/bash

export TEGIA_HOST=$TEGIA_HOST
export TEGIA_APP=$TEGIA_APP
export TEGIA_FCGI_PORT=$TEGIA_FCGI_PORT
export TEGIA_AUTH=$TEGIA_AUTH

export MYSQL_HOST=$MYSQL_HOST
export MYSQL_PORT=$MYSQL_PORT
export MYSQL_DB_PREFIX=$MYSQL_DB_PREFIX
export MYSQL_USER=$MYSQL_USER
export MYSQL_PASSWORD=$MYSQL_PASSWORD
EOF

echo " "

#
# SAVE mysql.cnf FILE
#

tee ./configurations/mysql.cnf << EOF > /dev/null
[mysql]
host=$MYSQL_HOST
port=$MYSQL_PORT
user=$MYSQL_USER
password=$MYSQL_PASSWORD
EOF


# ////////////////////////////////////////////////////////////////////////////////////////
#
# Tegia Node INSTALL
#
# ////////////////////////////////////////////////////////////////////////////////////////


if ! [ -d  ${root_folder}/tegia-node/ ]
then
	cd ${root_folder};
	git clone git@github.com:tegia-node/tegia-node.git
	cd ${root_folder}/tegia-node/
	git checkout develop

	cd ${root_folder}/tegia-node/
	bash ./install.sh
else
	echo "${_OK_}tegia node is already installed"
fi

sudo ln -fs "${root_folder}/tegia-node/build/tegia-node" "${tep_folder}/tegia-node"


# ////////////////////////////////////////////////////////////////////////////////////////
#
# INIT MYSQL USER
#
# ////////////////////////////////////////////////////////////////////////////////////////


export MYSQL_PWD=$(mysql_debian_password)

iffinduser="$(mysql -u debian-sys-maint --execute="SELECT host,user FROM mysql.user WHERE host = '$MYSQL_HOST' AND user = '$MYSQL_USER';")"
if [[ "${#iffinduser}" != 0 ]]
then
	mysql -u debian-sys-maint --port=$MYSQL_PORT --execute="DROP USER '$MYSQL_USER'@'$MYSQL_HOST';"
fi

cp "${tep_folder}/.default/sql/user.sql" "${tep_folder}/user.sql_tmp"
sed -i -e "s|{MYSQL_HOST}|$MYSQL_HOST|g" "${tep_folder}/user.sql_tmp"
sed -i -e "s|{MYSQL_USER}|$MYSQL_USER|g" "${tep_folder}/user.sql_tmp"
sed -i -e "s|{MYSQL_PASSWORD}|$MYSQL_PASSWORD|g" "${tep_folder}/user.sql_tmp" 
sed -i -e "s|{MYSQL_DB_PREFIX}|$MYSQL_DB_PREFIX|g" "${tep_folder}/user.sql_tmp"

mysql -u debian-sys-maint --port=$MYSQL_PORT < ${tep_folder}/user.sql_tmp
rm ${tep_folder}/user.sql_tmp

echo " "
echo -e "${_OK_}tegia user '${MYSQL_USER}' is created on MySQL"


# /////////////////////////////////////////////////////////////////////////////////////////////////////
#
# MAIN CONFIG FILES
#
# /////////////////////////////////////////////////////////////////////////////////////////////////////


cp "${tep_folder}/.default/config.json" "${tep_folder}/config.json"


# validate

if jq -e . ${tep_folder}/config.json >/dev/null; then
    echo -e "${_OK_}create 'config.json'"
else
    echo "${_ERR_} in 'config.json'"
    exit 1
fi


# ////////////////////////////////////////////////////////////////////////////////////////
#
# INSTALL CONFIGURATIONS
#
# ////////////////////////////////////////////////////////////////////////////////////////

jq -c '.configurations[]' ${tep_folder}/config.json | while read -r item; do
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

	tegia_conf_install $name $repository $branch

done


#
# $1 - configuration name
# $2 - github organization name
# $3 - branch name
#

# tegia_conf_install http tegia-node main
# tegia_conf_install example tegia-node example-01



# /////////////////////////////////////////////////////////////////////////////////////////////////////
#
# NGINX VIRTUAL HOST
#
# /////////////////////////////////////////////////////////////////////////////////////////////////////

sudo cp "${tep_folder}/.default/nginx/nginx.conf" "/etc/nginx/sites-available/${TEGIA_HOST}.conf"
sudo sed -i -e "s|{TEGIA_HOST}|$TEGIA_HOST|g" "/etc/nginx/sites-available/${TEGIA_HOST}.conf"
sudo sed -i -e "s|{TEGIA_PORT}|$TEGIA_FCGI_PORT|g" "/etc/nginx/sites-available/${TEGIA_HOST}.conf"

sudo ln -fs "/etc/nginx/sites-available/${TEGIA_HOST}.conf" "/etc/nginx/sites-enabled/${TEGIA_HOST}.conf"
sudo sh -c -e "echo '127.0.0.1 $TEGIA_HOST' >> /etc/hosts";

#
# JWT
#

echo " "
echo "${YELLOW}JWT KEYS${RESET}"
echo " "

cd ${tep_folder}
bash jwt-key.sh ${TEGIA_HOST}

echo " "
echo "${GREEN}Установка выполнена успешно${RESET}"
echo " "

exit 0




