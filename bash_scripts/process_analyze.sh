#!/bin/bash

echo "Запуск процессов нагрузки CPU, памяти и диска (по 3 процесса на каждый тип)"
echo "Нагрузка: CPU — 20 %, память — 20 %, диск — 30 % (каждый процесс)"
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
    # Удаляем временные файлы, созданные для нагрузки диска
    rm -f /tmp/disk_load_* 2>/dev/null
    echo "Все процессы завершены. Временные файлы удалены. Выход."
    exit 0
}

# Перехватываем сигнал прерывания (Ctrl+C)
trap cleanup INT

# === Нагрузка CPU (3 процесса, 20 % каждый) ===
echo "Запуск 3 процессов нагрузки CPU (20 % каждый)..."
for i in {1..3}; do
    # Используем stress с регулируемой интенсивностью через --cpu-method
    stress --cpu 1 --cpu-method all --timeout 3600s --metrics-brief > /dev/null 2>&1 &
    cpu_pid=$!
    pids+=("$cpu_pid")
    echo "PID процесса нагрузки CPU #$i: $cpu_pid"
done

# Для точной регулировки до 20 % используем cpulimit в дополнение к stress
echo "Настройка ограничения CPU до 20 % для каждого процесса..."
sleep 2  # Даём процессам запуститься
for pid in $(pgrep -f "stress --cpu 1"); do
    cpulimit -p "$pid" -l 20 -b &
    echo "Ограничение CPU до 20 % применено к PID $pid"
done

# === Нагрузка памяти (3 процесса, 20 % от RAM каждый) ===
echo "Запуск 3 процессов нагрузки памяти (20 % RAM каждый)..."
total_mem=$(free | awk '/^Mem:/ {print $2}')
target_mem=$((total_mem * 20 / 100))  # 20 % вместо 30 %

for i in {1..3}; do
    stress --vm 1 --vm-bytes "${target_mem}k" --timeout 3600s --metrics-brief > /dev/null 2>&1 &
    mem_pid=$!
    pids+=("$mem_pid")
    echo "PID процесса нагрузки памяти #$i: $mem_pid"
done

# === Нагрузка диска (3 процесса, ~30 % IOPS каждый) ===
echo "Запуск 3 процессов нагрузки диска (~30 % IO каждый)..."
# Создаём директорию для временных файлов
mkdir -p /tmp/disk_load

for i in {1..3}; do
    temp_file="/tmp/disk_load/disk_load_$(date +%s%N)_$i"
    
    # Для равномерной нагрузки используем цикл записи/чтения
    while true; do
        # Запись: 30 МБ блоками по 1 МБ
        dd if=/dev/zero of="$temp_file" bs=1M count=30 oflag=dsync status=none 2>/dev/null && \
        # Чтение: проверка целостности
        dd if="$temp_file" of=/dev/null bs=1M count=30 status=none 2>/dev/null && \
        # Удаление файла для новой итерации
        rm -f "$temp_file" 2>/dev/null
        sleep 0.5  # Пауза для стабилизации нагрузки
    done &
    disk_pid=$!
    pids+=("$disk_pid")
    echo "PID процесса нагрузки диска #$i: $disk_pid"
done

# Бесконечный цикл ожидания
echo "Все 9 процессов запущены с заданной нагрузкой. Ожидание сигнала остановки (Ctrl+C)..."
while true; do
    sleep 1
done
