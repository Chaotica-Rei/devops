#!/bin/bash

# Функция для обработки сигнала SIGINT (Ctrl+C)
cleanup() {
    echo -e "\nПолучен сигнал SIGINT (Ctrl+C). Завершаем процессы..."
    kill -TERM "${pids[@]}" 2>/dev/null
    for pid in "${pids[@]}"; do
        wait "$pid" 2>/dev/null
    done
    echo "Все процессы завершены. Выход из скрипта."
    exit 0
}

# Устанавливаем обработчик сигнала SIGINT
trap cleanup SIGINT

# Определяем количество ядер CPU
cpu_cores=$(nproc)
echo "Обнаружено ядер CPU: $cpu_cores"

# Целевая загрузка в процентах
target_load=30

# Рассчитываем количество процессов для равномерной нагрузки
# Формула: (общее количество ядер) * (целевая загрузка / 100)
num_processes=$(echo "$cpu_cores * $target_load / 100" | bc -l)
num_processes=${num_processes%.*}  # Округляем вниз
if [ "$num_processes" -lt 1 ]; then
    num_processes=1
fi

echo "Запуск $num_processes процессов для ~$target_load% загрузки CPU..."

# Массив для хранения PID процессов
pids=()

# Запускаем нужное количество процессов
for ((proc=0; proc<num_processes; proc++)); do
    (
        while true; do
            # Активная фаза: короткий цикл
            for ((i=0; i<100000; i++)); do
                : # Пустая операция
            done
            # Пассивная фаза: длительная пауза
            sleep 0.1
        done
    ) &
    pids+=($!)
done

echo "PID процессов: ${pids[*]}"
echo "Для остановки нажмите Ctrl+C"

# Ждём завершения всех процессов
for pid in "${pids[@]}"; do
    wait "$pid"
done
