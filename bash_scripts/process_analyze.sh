#!/bin/bash

# Скрипт для анализа процессов/диагностики системы

echo "Запуск тестов нагрузки системы..."
echo "PID скрипта: $$"

# Количество процессов для каждого типа нагрузки
NUM_PROCESSES=3

# Функция нагрузки CPU
cpu_load() {
    echo "Запуск процесса CPU-нагрузки (PID: $$)"
    while true; do
        # Выполняем интенсивные вычисления
        for ((i=0; i<10000; i++)); do
            sqrt=$(echo "sqrt($i)" | bc -l 2>/dev/null || echo $i)
        done
    done
}

# Функция нагрузки памяти
memory_load() {
    echo "Запуск процесса Memory-нагрузки (PID: $$)"
    # Создаём большой массив в памяти
    local -a big_array
    local size=100000
    for ((i=0; i<size; i++)); do
        big_array[i]=$(printf "%0100d" $RANDOM)
    done
    # Держим память занятой
    while true; do
        sleep 1
    done
}

# Функция нагрузки диска
disk_load() {
    echo "Запуск процесса Disk-нагрузки (PID: $$)"
    local temp_file="/tmp/disk_load_$$.tmp"
    
    while true; do
        # Интенсивная запись
        dd if=/dev/urandom of=$temp_file bs=1M count=10 2>/dev/null
        # Интенсивное чтение
        md5sum $temp_file > /dev/null 2>&1
        # Удаляем файл для следующей итерации
        rm -f $temp_file
    done
}

# Запуск процессов CPU-нагрузки
echo "Запускаем $NUM_PROCESSES процессов CPU-нагрузки..."
for ((i=0; i<NUM_PROCESSES; i++)); do
    cpu_load &
    CPU_PIDS+="$! "
done

# Запуск процессов Memory-нагрузки
echo "Запускаем $NUM_PROCESSES процессов Memory-нагрузки..."
for ((i=0; i<NUM_PROCESSES; i++)); do
    memory_load &
    MEMORY_PIDS+="$! "
done

# Запуск процессов Disk-нагрузки
echo "Запускаем $NUM_PROCESSES процессов Disk-нагрузки..."
for ((i=0; i<NUM_PROCESSES; i++)); do
    disk_load &
    DISK_PIDS+="$! "
done

echo "Все процессы запущены."
echo "CPU процессы: $CPU_PIDS"
echo "Memory процессы: $MEMORY_PIDS"
echo "Disk процессы: $DISK_PIDS"

# Функция для остановки всех процессов
stop_all() {
    echo "Остановка всех нагрузочных процессов..."
    for pid in $CPU_PIDS $MEMORY_PIDS $DISK_PIDS; do
        if kill -0 $pid 2>/dev/null; then
            kill $pid
            echo "Процесс $pid остановлен"
        fi
    done
    exit 0
}

# Ловим сигнал для остановки
trap stop_all INT TERM

# Ждём завершения
echo "Скрипт работает. Нажмите Ctrl+C для остановки."
while true; do
    sleep 10
done
