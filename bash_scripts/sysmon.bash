#!/bin/bash

# Скрипт мониторинга системы и управления логами
# Запуск в режиме отладки возможен с опциями -d и --debug
# запуск каждый час в cron -> 0 * * * * /путь/к/скрипту.sh


# Переменные

LOG_DIR="/var/log/sysmon" # директория с логами
LOG_FILE="${LOG_DIR}/monitor.log" # лог мониторинга системы
LOG_ERROR="${LOG_DIR}/error.log" # лог ошибок
ROTATE_DAYS=3 # срок хранения логов в днях
DEBUG=false # флаг режима отладки, по умолчанию выключен

# создаем директорию для логов
mkdir -p "$LOG_DIR"

### Функции

# запись в лог с датой/временем
log_message() {
    local type="$1"
    local msg="$2"
    echo "[$type] $(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

# запись в лог ошибок с датой/временем
log_error() {
    local msg="$1"
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_ERROR"
}

# сбор данных о системе
collect_system_info() {
    log_message "INFO" "Сбор данных о системе..."

    # загрузка CPU
    cpu_load=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d',' -f1)
    log_message "INFO" "CPU Load: $cpu_load"

    # использование памяти
    memory_total=$(free -m | awk '/Mem:/ {print $2}')
    memory_used=$(free -m | awk '/Mem:/ {print $3}')
    memory_percent=$(((memory_used * 100)/memory_total))
    log_message "INFO" "Memory: Used - ${memory_used}M / Total - ${memory_total}M (${memory_percent}%)"

    # место на диске
    disk_use=$(df -h / | awk 'NR==2 {print $5}')
    disk_free=$(df -h / | awk 'NR==2 {print $4}')
    log_message "INFO" "Disk Usage: $disk_use (Free: $disk_free)"
}

# ротация логов
rotate_logs() {
    log_message "INFO" "Запуск ротации логов..."

    # архивируем текущие логи
    if [ -s "$LOG_FILE" ]; then
        gzip -9 "$LOG_FILE"
        mv "${LOG_FILE}.gz" "${LOG_DIR}/monitor_$(date +%Y%m%d_%H%M%S).gz"
    fi

    if [ -s "$LOG_ERROR" ]; then
        gzip -9 "$LOG_ERROR"
        mv "${LOG_ERROR}.gz" "${LOG_DIR}/error_$(date +%Y%m%d_%H%M%S).gz"
    fi

    # удаляем логи старше 3 дней
    find "$LOG_DIR" -type f -name "*.gz" -mtime +"$ROTATE_DAYS" -exec rm -f {} \;
    log_message "INFO" "Ротация завершена. Старые архивы удалены."
}

# обработчик сигналов
sig_handler() {
    local sig="$1"
    log_message "WARNING" "Получен сигнал $sig. Завершение работы..."
    exit 0
}

# обработка опции -d/--debug
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--debug)
            DEBUG=true
            shift
            ;;
        *)
            shift # неизвестные опции пропускаем
            ;;
    esac
done

# включение отладки, если запрошено
if [ "$DEBUG" = true ]; then
    set -x
    log_message "DEBUG" "Режим отладки включён."
fi

# регистрация обработчиков сигналов
trap 'sig_handler INT' SIGINT
trap 'sig_handler TERM' SIGTERM

### Основное выполнение

# пишем INFO сообщение в лог о старте мониторинга
log_message "INFO" "Запуск мониторинга..."

# собираем информацию о системе
collect_system_info

# ротация логов (раз в сутки можно запускать через cron)
if [ "$(date +%H)" -eq 0 ]; then  # В 00:00
    rotate_logs
fi

log_message "INFO" "Завершение работы скрипта."

exit 0