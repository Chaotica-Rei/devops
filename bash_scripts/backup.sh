#!/bin/bash

# Скрипт для автоматизированного процесса резервного копирования файлов и проверки целостности

# переменные 
SOURCE_DIR="$HOME/source" # начальная директория, из которой будем делать бэкап
BACKUP_DIR="$HOME/backup" # директория для бэкапа
LOG_FILE="$HOME/backup/backup.log" # лог-файл
DATE=$(date +"%Y%m%d_%H%M%S") # временная метка
ARCHIVE_NAME="backup_$DATE.tar.gz" # имя архива
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME" # путь архива
MD5_FILE="$ARCHIVE_PATH.md5" # контрольная сумма

# создаем директории
mkdir -p "$SOURCE_DIR" "$BACKUP_DIR"

# создаем архив через tar
echo "[$DATE] Начато резервное копирование из $SOURCE_DIR в $ARCHIVE_PATH" >> "$LOG_FILE"

tar -czf "$ARCHIVE_PATH" -C "$SOURCE_DIR" . 2>> "$LOG_FILE"

if [ $? -ne 0 ]; then
    echo "[$DATE] ОШИБКА: Создание архива завершилось с ошибкой" >&2
    exit 1
fi

# проверка целостности с md5sum
md5sum "$ARCHIVE_PATH" > "$MD5_FILE" 2>> "$LOG_FILE"

if [ $? -ne 0 ]; then
    echo "[$DATE] ОШИБКА: Не удалось сгенерировать md5sum для $ARCHIVE_PATH" >&2
    exit 1
fi

# проверка корректности md5sum
md5sum -c "$MD5_FILE" >> "$LOG_FILE" 2>&1

if [ $? -ne 0 ]; then
    echo "[$DATE] ОШИБКА: Проверка md5sum не прошла для $ARCHIVE_PATH" >&2
    exit 1
fi

# завершение
echo "[$DATE] Резервное копирование успешно завершено: $ARCHIVE_PATH" >> "$LOG_FILE"
echo "[$DATE] Файл контрольной суммы: $MD5_FILE" >> "$LOG_FILE"

exit 0