#!/bin/bash

source ./const.sh


#
# Функция для замены значения элемента в JSON
#

json_update_element() 
{
  local json=$1        # Исходный JSON
  local path=$2        # Путь к элементу в формате jq
  local new_value=$3   # Новое значение элемента

  # Используем jq для замены значения элемента и возвращаем модифицированный JSON
  echo "$json" | jq --arg value "$new_value" "$path = \$value"
}

#
# Функция для добавления нового поля в JSON-объект
#

json_add_field() {
  local json="$1"
  local new_field="$2"

  # Используем jq для добавления нового поля
  local updated_json=$(echo "$json" | jq --argjson field "$new_field" '. + $field')

  echo "$updated_json"
}



#
# Функция для добавления элемента в массив JSON
#

add_element_to_json_array() {
  local json="$1"
  local array_path="$2"
  local new_element="$3"

  # Используем jq для добавления нового элемента в массив
  updated_json=$(echo "$json" | jq --argjson element "$new_element" "$array_path += [$element]")

  echo "$updated_json"
}

#
# Функция для добавления нового поля в объект JSON
#

add_field_to_json_object() {
  local json="$1"
  local field_name="$2"
  local field_value="$3"
  local object_path="$4"

  # Используем jq для добавления нового поля в объект
  updated_json=$(echo "$json" | jq --arg name "$field_name" --argjson value "$field_value" "$object_path |= . + { ($name): $value }")

  echo "$updated_json"
}
