#!/bin/bash

# Универсальный скрипт установки

set -e  # прекращать выполнение при любой ошибке

echo "Запуск автоматизированного скрипта установки..."

# Функции

# Определение ОС и пакетного менеджера
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="${ID}"
        VERSION_ID="${VERSION_ID}"
    else
        echo "Не удалось определить дистрибутив"
        exit 1
    fi

    case "${DISTRO}" in
        ubuntu|debian)
            PKG_MANAGER="apt"
            UPDATE_CMD="sudo apt update"
            INSTALL_CMD="sudo apt install -y"
            ;;
        centos|rocky|almalinux|rhel)
            PKG_MANAGER="yum"
            UPDATE_CMD="sudo yum check-update"
            INSTALL_CMD="sudo yum install -y"
            ;;
        fedora)
            PKG_MANAGER="dnf"
            UPDATE_CMD="sudo dnf check-update"
            INSTALL_CMD="sudo dnf install -y"
            ;;
        *)
            echo "Дистрибутив ${DISTRO} не поддерживается!"
            exit 1
            ;;
    esac

    echo "Определён дистрибутив: ${DISTRO} (${VERSION_ID})"
    echo "Пакетный менеджер: ${PKG_MANAGER}"
}

# Установка пакетов
install_packages() {
    echo "Устанавливаем необходимые пакеты..."

    # Список пакетов для установки
    PACKAGES=(
        nginx
        mysql-server
        ufw
        curl
        wget
        git
    )

    ${UPDATE_CMD}
    ${INSTALL_CMD} "${PACKAGES[@]}"

    echo "Пакеты установлены."
}

# Настройка сервисов
configure_services() {
    echo "Настраиваем сервисы..."

    # Nginx
    if systemctl is-active --quiet nginx; then
        echo "Nginx уже запущен."
    else
        sudo systemctl enable nginx
        sudo systemctl start nginx
        echo "Nginx запущен."
    fi

    # MySQL
    if systemctl is-active --quiet mysql; then
        echo "СУБД уже запущена."
    else
        sudo systemctl enable mysql
        sudo systemctl start mysql
        echo "СУБД запущена."
    fi

    echo "Сервисы настроены."
}

# Создание тестовой БД
create_test_db() {
    echo "Создаём тестовую базу данных..."

    # Временный пароль для root
    TEMP_PASSWORD="root_temp_password"

    # Устанавливаем временный пароль для root
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${TEMP_PASSWORD}'; FLUSH PRIVILEGES;"

    # Создаём БД и пользователя
    sudo mysql -u root -p"${TEMP_PASSWORD}" -e "
        CREATE DATABASE IF NOT EXISTS test_db;
        CREATE USER IF NOT EXISTS 'test_user'@'localhost' IDENTIFIED BY 'test_pass_123';
        GRANT ALL PRIVILEGES ON test_db.* TO 'test_user'@'localhost';
        FLUSH PRIVILEGES;
    "

    echo "Тестовая БД 'test_db' создана. Пользователь: test_user, пароль: test_pass_123"
}

# Настройка фаервола
configure_firewall() {
    echo "Настраиваем фаервол (ufw)..."

    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    # Разрешаем HTTP/HTTPS и SSH
    sudo ufw allow 80/tcp    # HTTP
    sudo ufw allow 443/tcp   # HTTPS
    sudo ufw allow 22/tcp    # SSH

    # Включаем ufw
    if sudo ufw status | grep -q "Status: active"; then
        echo "ufw уже активен."
    else
        sudo ufw --force enable
        echo "ufw включён."
    fi

    echo "Фаервол настроен."
}

# Основной блок скрипта
main() {
    detect_distro
    install_packages
    configure_services
    create_test_db
    configure_firewall

    echo "Установка завершена успешно!"
}

# Запускаем основной блок
main
