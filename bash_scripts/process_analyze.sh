#!/bin/bash

# Массивы для хранения PID процессов
cpu_pids=()
memory_pids=()
disk_pids=()

# Функция для создания нагрузки на CPU
start_cpu_load() {
    # Бесконечный цикл с вычислениями
    while true; do
        # Выполняем интенсивные вычисления
        for ((i=0; i<1000000; i++)); do
            j=$((i * i + i))
        done
    done
}

# Функция для создания нагрузки на память
start_memory_load() {
    local data=""
    # Постоянно увеличиваем строку, потребляя память
    while true; do
        data="${data}$(printf '%010000s' ' ')"
        # Периодически очищаем часть данных, чтобы не исчерпать всю память мгновенно
        if [ ${#data} -gt 1000000 ]; then
            data="${data:50000}"
        fi
        sleep 0.1
    done
}

# Функция для создания нагрузки на диск
start_disk_load() {
    local temp_file="/tmp/disk_load_$$_$(date +%s%N)"
    # Создаём и перезаписываем временный файл
    while true; do
        # Записываем случайные данные в файл
        head -c 10M /dev/urandom > "$temp_file"
        # Удаляем файл и создаём новый
        rm -f "$temp_file"
        temp_file="/tmp/disk_load_$$_$(date +%s%N)"
        sleep 0.5
    done
}

# Обработчик прерывания (Ctrl+C)
cleanup() {
    echo -e "\n\nПолучен сигнал прерывания. Завершаем процессы..."
    
    # Завершаем все процессы CPU
    for pid in "${cpu_pids[@]}"; do
        kill -9 "$pid" 2>/dev/null && echo "Процесс CPU (PID: $pid) завершён"
    done
    
    # Завершаем все процессы памяти
    for pid in "${memory_pids[@]}"; do
        kill -9 "$pid" 2>/dev/null && echo "Процесс памяти (PID: $pid) завершён"
    done
    
    # Завершаем все процессы диска
    for pid in "${disk_pids[@]}"; do
        kill -9 "$pid" 2>/dev/null && echo "Процесс диска (PID: $pid) завершён"
    done
    
    echo "Все процессы завершены. Выход."
    exit 0
}

# Устанавливаем обработчик прерывания
trap cleanup INT TERM

echo "Запуск процессов с нагрузкой..."

# Запускаем 3 процесса для нагрузки CPU
echo "Запускаем процессы для нагрузки CPU:"
for i in {1..3}; do
    start_cpu_load &
    cpu_pids+=($!)
    echo "PID процесса CPU $i: $!"
done

# Запускаем 3 процесса для нагрузки памяти
echo -e "\nЗапускаем процессы для нагрузки памяти:"
for i in {1..3}; do
    start_memory_load &
    memory_pids+=($!)
    echo "PID процесса памяти $i: $!"
done

# Запускаем 3 процесса для нагрузки диска
echo -e "\nЗапускаем процессы для нагрузки диска:"
for i in {1..3}; do
    start_disk_load &
    disk_pids+=($!)
    echo "PID процесса диска $i: $!"
done

echo -e "\nВсе процессы запущены. Ожидание прерывания (Ctrl+C)..."

# Бесконечный цикл ожидания
while true; do
    sleep 1
done
