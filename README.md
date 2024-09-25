# example-cluster

- Вводное видео про платформу Tegia Node: https://drive.google.com/file/d/11ZC2h6eGcEJ1CmVDRS0TqowaN0KP4zTn/view?usp=drive_link
- Examole 01: https://drive.google.com/file/d/1n-KOsTi-bD5PXCgS3toOQFXw-UM_BLgz/view?usp=drive_link
- Example 02: https://drive.google.com/file/d/1SHsuQie9Ci0114SzNN4qpqI6zt6y_mlY/view?usp=drive_link
- Example 02: https://drive.google.com/file/d/1XQeP4kHx6IcTqnGlugGhH8sq6XhTAl9e/view?usp=drive_link

# Инструкция по установке

1. Создать в любом удобном месте каталог tegia и перейти в него:
```
mkdir tegia
cd tegia
```
2. Создать каталог clusters и перейти в него
```
mkdir clusters
cd clusters
```
3. Выгрузить ветку нужного примера из репозитория:
```
git clone git@github.com:tegia-node/example-cluster.git -b example_01
```
4. Перейти в каталог и запустить скрипт установки
```
cd example-cluster
bash install.sh
```
5. Следовать указаниям скрипта до завершения установки
6. Запустить кластер example-cluster
```
./tegia-node --local
```
