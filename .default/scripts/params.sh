#!/bin/bash

source ./const.sh
source ./json.sh

#
#  READ PARAMS
#

get_params_data()
{
	if ! test -e "$PARAMS_FILE"
	then
		# echo "not found $PARAMS_FILE"
		# cp ${tep_folder}/.default/params.json ${tep_folder}/params.json

		local PARAMS=$(cat "$PARAMS_TEMPLATE_FILE")

		#
		# ADD PATH TO PARAMS
		#

		PARAMS=$(json_update_element "$PARAMS" ".paths.cluster" "$CLUSTER_PATH")
		PARAMS=$(json_update_element "$PARAMS" ".paths.root" "$ROOT_PATH")

		#
		# SAVE PARAMS
		#

		echo "$PARAMS" | jq '.' > "$PARAMS_FILE"
	fi

	cat "$PARAMS_FILE"
}



#
# $1 - template path
# $2 - params
#

init_config_file()
{
	local _TEMPLATE_FILE_=$1
	local _PARAMS_=$2
	local _CONFIG_=$(cat "$_TEMPLATE_FILE_")

	mapfile -t JPATHS < <(grep -oP '%%\K[^%]+(?=%%)' "${_TEMPLATE_FILE_}")

	for JPATH in "${JPATHS[@]}"; do

		VALUE=$(echo "${_PARAMS_}" | jq -r "${JPATH}")

		#echo $JPATH
		#echo $VALUE

		_CONFIG_="${_CONFIG_//%%$JPATH%%/$VALUE}"
	done

	echo "${_CONFIG_}"
}



#
# Функция для отображения меню и обработки ввода пользователя
#

function ask_user() 
{
	echo " "
    echo "${GREEN}Обнаружен файл ./params.sh с параметрами установки кластера. Использовать этот файл?${RESET}"
    echo "[1] Использовать файл. Начнется установка системы"
    echo "[2] Выполнить ручное редактирование файла. Установка будет завершена"
	echo " "

    read -p "Введите номер варианта (1 или 2): " choice

    case $choice in
        1)
            echo " "
            # Здесь можно добавить код для начала установки системы
            ;;
        2)
            echo "Откройте файл ./params.sh для редактирования."
            # Здесь можно добавить код для открытия файла в редакторе, например, nano
            # nano ./params.sh
            # echo "После редактирования файла установка будет завершена."
			exit 0
            ;;
        *)
            echo "Некорректный ввод. Пожалуйста, выберите 1 или 2."
			echo " "
            ask_user
            ;;
    esac
}