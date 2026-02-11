#!/bin/bash

echo "Запуск процессов нагрузки CPU, памяти и диска (по 3 процесса на каждый тип, ~30 % нагрузки каждый)..."
echo "Для остановки нажмите Ctrl+C"

# Массив для хранения всех PID
pids=()

# Функция для обработки сигнала Ctrl+C
cleanup() {
    echo -e "\nОстановка всех процессов..."
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

# === Нагрузка CPU (3 процесса, ~30 % каждый) ===
echo "Запуск 3 процессов нагрузки CPU..."
for i in {1..3}; do
    stress --cpu 1 --timeout 3600s --metrics-brief > /dev/null 2>&1 &
    cpu_pid=$!
    pids+=("$cpu_pid")
    echo "PID процесса нагрузки CPU #$i: $cpu_pid"
done

# === Нагрузка памяти (3 процесса, 30 % от RAM каждый) ===
echo "Запуск 3 процессов нагрузки памяти..."
total_mem=$(free | awk '/^Mem:/ {print $2}')
target_mem=$((total_mem * 30 / 100))

for i in {1..3}; do
    stress --vm 1 --vm-bytes "${target_mem}k" --timeout 3600s --metrics-brief > /dev/null 2>&1 &
    mem_pid=$!
    pids+=("$mem_pid")
    echo "PID процесса нагрузки памяти #$i: $mem_pid"
done

# === Нагрузка диска (3 процесса, имитация активности) ===
echo "Запуск 3 процессов нагрузки диска..."
for i in {1..3}; do
    temp_file="/tmp/disk_load_$(date +%s%N)_$i"
    # Используем dd с разными параметрами для разнообразия нагрузки
    dd if=/dev/zero of="$temp_file" bs=1M count=$((50 + i * 10)) oflag=dsync status=none &
    disk_pid=$!
    pids+=("$disk_pid")
    echo "PID процесса нагрузки диска #$i: $disk_pid"
done

# Бесконечный цикл ожидания
echo "Все 9 процессов запущены. Ожидание сигнала остановки (Ctrl+C)..."
while true; do
    sleep 1
done
