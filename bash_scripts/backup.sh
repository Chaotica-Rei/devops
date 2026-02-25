#!/bin/bash

# Скрипт для автоматизированного процесса резервного копирования файлов и проверки целостности

# Настройка для cron (ежедневное копирование в 2 часа ночи), заменить user на своего пользователя:
# 0 2 * * * /home/user/backup.sh

# Настройки
SOURCE="$HOME/data"                # директория с данными для резервного копирования
BACKUP_DIR="$HOME/backups"         # директория для хранения резервных копий
LOG_FILE="$HOME/backup.log"        # лог-файл
DATE=$(date +"%Y-%m-%d_%H-%M-%S")  # метка времени для именования бэкапа
CURRENT_BACKUP="$BACKUP_DIR/$DATE" # директория для текущего бэкапа 
LAST_BACKUP="$BACKUP_DIR/latest"   # ссылка на последний бэкап

# Лог-функции
log_info() {
    echo "[$DATE] INFO: $1" >> "$LOG_FILE"
}

log_error() {
    echo "[$DATE] ERROR: $1" | tee -a "$LOG_FILE" >&2
}

# Проверка существования директории
mkdir -p "$BACKUP_DIR"

# Инкрементальное копирование
log_info "Начало резервного копирования..."

if [ -d "$LAST_BACKUP" ]; then
    rsync -a --delete --link-dest="$LAST_BACKUP" "$SOURCE/" "$CURRENT_BACKUP"
else
    rsync -a "$SOURCE/" "$CURRENT_BACKUP"
fi

# Проверка успешности rsync
if [ $? -ne 0 ]; then
    log_error "Резервное копирование не удалось!"
    exit 1
fi

# Архивация 
cd "$BACKUP_DIR"
tar -cf "$DATE.tar" "$DATE"
if [ $? -ne 0 ]; then
    log_error "Не удалось создать архив!"
    exit 1
fi

# Генерация контрольной суммы / Проверка целостности
md5sum "$DATE.tar" > "$DATE.tar.md5"
md5sum -c "$DATE.tar.md5"
if [ $? -ne 0 ]; then
    log_error "Проверка целостности не удалась!"
    exit 1
fi

# Обновляем ссылку на последний бэкап
rm -f "$LAST_BACKUP"
ln -s "$CURRENT_BACKUP" "$LAST_BACKUP"

# Логирование
log_info "Бэкап успешно завершен"
exit 0