#!/bin/bash

# Универсальный скрипт установки

set -e  # Прекращать выполнение при любой ошибке

echo "Запуск автоматизированного скрипта установки..."

# --- 1. Определение ОС и пакетного менеджера ---
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="${ID}"
        VERSION_ID="${VERSION_ID}"
    else
        echo "Не удалось определить дистрибутив!"
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

# --- 2. Установка пакетов ---
install_packages() {
    echo "Устанавливаем необходимые пакеты..."

    # Список пакетов (пример для веб‑сервера + БД)
    PACKAGES=(
        nginx
        mysql-server          # или mariadb-server
        ufw
        curl
        wget
        git
    )

    ${UPDATE_CMD}
    ${INSTALL_CMD} "${PACKAGES[@]}"

    echo "Пакеты установлены."
}

# --- 3. Настройка сервисов ---
configure_services() {
    echo "Настраиваем сервисы..."

    # Nginx
    if systemctl is-active --quiet nginx; then
        echo "   Nginx уже запущен."
    else
        sudo systemctl enable nginx
        sudo systemctl start nginx
        echo "   Nginx запущен."
    fi

    # MySQL/MariaDB
    if systemctl is-active --quiet mysql || systemctl is-active --quiet mariadb; then
        echo "   СУБД уже запущена."
    else
        sudo systemctl enable mysql || sudo systemctl enable mariadb
        sudo systemctl start mysql || sudo systemctl start mariadb
        echo "   СУБД запущена."
    fi

    echo "Сервисы настроены."
}

# --- 4. Создание тестовой БД ---
create_test_db() {
    echo "Создаём тестовую базу данных..."

    # Временный пароль для root (в реальном сценарии используйте безопасный метод)
    TEMP_PASS="temp_password_123"

    # Устанавливаем временный пароль для root
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${TEMP_PASS}'; FLUSH PRIVILEGES;"

    # Создаём БД и пользователя
    sudo mysql -u root -p"${TEMP_PASS}" -e "
        CREATE DATABASE IF NOT EXISTS test_db;
        CREATE USER IF NOT EXISTS 'test_user'@'localhost' IDENTIFIED BY 'test_pass_123';
        GRANT ALL PRIVILEGES ON test_db.* TO 'test_user'@'localhost';
        FLUSH PRIVILEGES;
    "

    echo "Тестовая БД 'test_db' создана. Пользователь: test_user, пароль: test_pass_猛烈123"
}

# --- 5. Настройка фаервола (ufw) ---
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
        echo "   ufw уже активен."
    else
        sudo ufw --force enable
        echo "   ufw включён."
    fi

    echo "Фаервол настроен."
}

# --- Основной блок выполнения ---
main() {
    detect_distro
    install_packages
    configure_services
    create_test_db
    configure_firewall

    echo "Установка завершена успешно!"
    echo "- Nginx: http://ваш_сервер/
   - БД: test_db (пользователь: test_user)
   - Фаервол: разрешены порты 80, 443, 22"
}

# Запускаем основной блок
main
