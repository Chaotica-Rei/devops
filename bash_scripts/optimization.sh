#!/bin/bash

# Функция для обработки сигнала Ctrl+C
cleanup() {
    echo "Получен сигнал Ctrl+C. Завершаем работу..."
    kill $pid 2>/dev/null
    exit 0
}

# Устанавливаем обработчик сигнала SIGINT (Ctrl+C)
trap cleanup SIGINT

echo "Запуск процесса с загрузкой CPU ~30%. Нажмите Ctrl+C для остановки."

# Бесконечный цикл с чередованием работы и сна для достижения ~30% загрузки
while true; do
    # Блок интенсивной нагрузки (занимает процессорное время)
    # Используем арифметическое вычисление в цикле
    start_time=$(date +%s.%N)
    end_time=$(echo "$start_time + 0.3" | bc -l)

    while true; do
        # Простое вычисление для нагрузки CPU
        temp=$(( (RANDOM % 1000) * (RANDOM % 1000) ))
        current_time=$(date +%s.%N)

        # Выходим из цикла нагрузки, когда прошло 0.3 секунды
        if (( $(echo "$current_time >= $end_time" | bc -l) )); then
            break
        fi
    done

    # Период отдыха — 0.7 секунды (чтобы общее время цикла было 1 секунда, а нагрузка — 30 %)
    sleep 0.7
done
