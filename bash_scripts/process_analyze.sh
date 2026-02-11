#!/! /bin/bash

echo "Запуск процессов нагрузки CPU, памяти и диска (примерно 30 % каждый)..."
echo "Для остановки нажмите Ctrl+C"

# Массивы для хранения PID
pids=()

# Функция для обработки сигнала Ctrl+C
cleanup() {
    echo -e "\nОстановка процессов..."
    for pid in "${pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            echo "Процесс PID $pid остановлен"
        fi
    done
    echo "Все процессы завершены. Выход."
    exit 0
}

# Перехватываем сигнал прерывания (Ctrl+C)
trap cleanup INT

# Нагрузка CPU (30 %)
echo "Запуск процесса нагрузки CPU..."
stress --cpu 1 --timeout 3600s --metrics-brief > /dev/null 2>&1 &
cpu_pid=$!
pids+=("$cpu_pid")
echo "PID процесса нагрузки CPU: $cpu_pid"

# Нагрузка памяти (30 % от доступной RAM)
echo "Запуск процесса нагрузки памяти..."
total_mem=$(free | awk '/^Mem:/ {print $2}')
target_mem=$((total_mem * 30 / 100))
stress --vm 1 --vm-bytes "${target_mem}k" --timeout 3600s --metrics-brief > /dev/null 2>&1 &
mem_pid=$!
pids+=("$mem_pid")
echo "PID процесса нагрузки памяти: $mem_pid"

# Нагрузка диска (запись ~30 % IOPS, имитация активности)
echo "Запуск процесса нагрузки диска..."
# Создаём временный файл для нагрузки диска
temp_file="/tmp/disk_load_$(date +%s%N)"
dd if=/dev/zero of="$temp_file" bs=1M count=100 oflag=dsync status=none &
disk_pid=$!
pids+=("$disk_pid")
echo "PID процесса нагрузки диска: $disk_pid"

# Бесконечный цикл ожидания
echo "Процессы запущены. Ожидание сигнала остановки..."
while true; do
    sleep 1
done
