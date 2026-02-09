#!/bin/bash

# Скрипт автоматизации управления пользователями системы
# Для создания пользователей использовать CSV-файл в формате username, fullname, role, group, password
# Для удаления пользователей использовать CSV-файл в формате username, remove_home (атрибут remove_home принимает значение "yes" - для удаления домашней директории, "no" - без удаления домашней директории)

# Настройки
LOG_FILE="$HOME/log/user_manager.log"
CSV_CREATE="users_create.csv"
CSV_DELETE="users_delete.csv"
SSH_DIR="/home"

# Создаем директорию для лога
mkdir -p "$HOME/log"

# Функции

log_message() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $msg" | tee -a "$LOG_FILE"
}

create_user() {
    local username="$1"
    local fullname="$2"
    local role="$3"
    local group="$4"
    local password="$5"

    # Проверяем, существует ли пользователь
    if id "$username" &>/dev/null; then
        log_message "WARNING: Пользователь $username уже существует."
        return 1
    fi

    # Создаём пользователя
    useradd -m -c "$fullname" -g "$group" -s /bin/bash "$username" 2>> "$LOG_FILE"
    if [ $? -ne 0 ]; then
        log_message "ERROR: Не удалось создать пользователя $username."
        return 1
    fi

    # Устанавливаем пароль
    echo "$username:$password" | chpasswd 2>> "$LOG_FILE"
    if [ $? -ne 0 ]; then
        log_message "ERROR: Не удалось установить пароль для $username."
        return 1
    fi

    # Генерируем SSH-ключ
    sudo -u "$username" ssh-keygen -t ed25519 -f "/home/$username/.ssh/id_ed25519" -N "" 2>> "$LOG_FILE"
    if [ $? -ne 0 ]; then
        log_message "ERROR: Не удалось сгенерировать SSH-ключ для $username."
        return 1
    fi

    # Настраиваем права на .ssh
    chmod 700 "/home/$username/.ssh"
    chmod 600 "/home/$username/.ssh/id_ed25519"
    chmod 644 "/home/$username/.ssh/id_ed25519.pub"

    log_message "SUCCESS: Пользователь $username создан. SSH-ключ (ED25519) сгенерирован."
}

add_to_group() {
    local username="$1"
    local group="$2"

    usermod -aG "$group" "$username" 2>> "$LOG_FILE"
    if [ $? -eq 0 ]; then
        log_message "INFO: Пользователь $username добавлен в группу $group."
    else
        log_message "ERROR: Не удалось добавить $username в группу $group."
    fi
}

update_permissions() {
    local group="$1"
    local dir="/shared/$group"

    mkdir -p "$dir" 2>> "$LOG_FILE"
    chown :"$group" "$dir"
    chmod 2775 "$dir"
    log_message "INFO: Права для директории $dir обновлены."
}

delete_user() {
    local username="$1"
    local remove_home="$2"

    # Проверяем, существует ли пользователь
    if ! id "$username" &>/dev/null; then
        log_message "WARNING: Пользователь $username не найден."
        return 1
    fi

    local home_dir="/home/$username"

    # Удаление пользователя
    if [ "$remove_home" = "yes" ]; then
        deluser --remove-home "$username" 2>> "$LOG_FILE"
        log_message "INFO: Домашняя директория $home_dir удалена."
    else
        deluser "$username" 2>> "$LOG_FILE"
        log_message "INFO: Домашняя директория $home_dir сохранена."
    fi

    # Проверяем результат выполнения deluser
    if [ $? -ne 0 ]; then
        log_message "ERROR: Не удалось удалить пользователя $username."
        return 1
    fi

    log_message "SUCCESS: Пользователь $username удалён."
}


# Основной блок
echo "Выберите опцию:"
echo "[1] Создать пользователей"
echo "[2] Удалить пользователей"
read -p "Введите номер (1 или 2): " choice

case "$choice" in
    1)
        if [ ! -f "$CSV_CREATE" ]; then
            log_message "ERROR: Файл $CSV_CREATE не найден."
            exit 1
        fi

        log_message "Начало создания пользователей из $CSV_CREATE."

        while IFS=, read -r username fullname role group password; do
            # Пропускаем пустую строку или заголовок
            [[ -z "$username" ]] && continue
            [[ "$username" == "username" ]] && continue

            create_user "$username" "$fullname" "$role" "$group" "$password"

            # Добавляем в группу 
            add_to_group "$username" "$group"

            # Обновляем права для группы
            update_permissions "$group"
        done < "$CSV_CREATE"

        log_message "Создание пользователей завершено."
        ;;

    2)
        if [ ! -f "$CSV_DELETE" ]; then
            log_message "ERROR: Файл $CSV_DELETE не найден."
            exit 1
        fi

        log_message "Начало удаления пользователей из $CSV_DELETE."

        while IFS=, read -r username remove_home; do
            [[ -z "$username" ]] && continue
            [[ "$username" == "username" ]] && continue

            delete_user "$username" "$remove_home"
        done < "$CSV_DELETE"

        log_message "Удаление пользователей завершено."
        ;;

    *)
        echo "Неизвестная опция. Завершение."
        exit 1
        ;;
esac

echo "Готово. Подробности в логе: $LOG_FILE"
