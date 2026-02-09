#!/bin/bash

# Скрипт для анализа процессов, диагностики системы

LOG_DIR="$HOME/log"
mkdir -p "$LOG_DIR"

echo "Запуск диагностики системы... $(date)" > "$LOG_DIR/report.txt"

# Создаем нагрузку на CPU, память и диск

echo "\n[1] Создаём нагрузку на CPU, память и диск..." >> "$LOG_DIR/report.txt"

# Нагрузка на CPU
echo "CPU load (sha1sum /dev/zero)..."
dd if=/dev/zero bs=1M count=1000 | sha1sum &
CPU_PID=$!

# Нагрузка на память
echo "Memory load (malloc in bash loop)..."
for i in {1..100}; do
    head -c 100M /dev/urandom > /tmp/mem_load_$i
done &
MEM_PID=$!

# Нагрузка на диск 
echo "Disk load (writing to /tmp)..."
for i in {1..50}; do
    dd if=/dev/urandom of=/tmp/disk_load_$i bs=1M count=100
done &
DISK_PID=$!

sleep 10  # Даём нагрузке поработать

# Собираем данные через top/htop/proc
echo "\nСостояние системы через top (10 сек):" >> "$LOG_DIR/report.txt"
top -b -n 2 -d 5 > "$LOG_DIR/top_output.txt"
cat "$LOG_DIR/top_output.txt" >> "$LOG_DIR/report.txt"

echo "\nДанные из /proc/meminfo:" >> "$LOG_DIR/report.txt"
cat /proc/meminfo | head -10 >> "$LOG_DIR/report.txt"

echo "\nЗагрузка CPU из /proc/stat:" >> "$LOG_DIR/report.txt"
grep 'cpu ' /proc/stat >> "$LOG_DIR/report.txt"

# --- 2. Статусы процессов: зомби и сироты ---

echo "\n[2] Создаём процессы-зомби и сироты..." >> "$LOG_DIR/report.txt"

# Зомби: дочерний процесс завершается, родитель не вызывает wait()
( sleep 3; exit 42 ) &
ZOMBIE_PID=$!
echo "Зомби-процесс запущен с PID: $ZOMBIE_PID" >> "$LOG_DIR/report.txt"
sleep 5  # Зомби появится после завершения дочернего

# Сирота: родитель завершается, дочерний остаётся
( sleep 10 & ) &
ORPHAN_PID=$!
echo "Сирота-процесс запущен с PID: $ORPHAN_PID" >> "$LOG_DIR/report.txt"
kill $$  # Завершаем текущий скрипт, но дочерний продолжит работать

# После завершения скрипта проверим процессы
sleep 5
echo "\nСписок процессов (ps aux) после создания зомби/сирот:" >> "$LOG_DIR/report.txt"
ps aux --forest | grep -E "Z|$ZOMBIE_PID|$ORPHAN_PID" >> "$LOG_DIR/report.txt"

# --- 3. Использование strace ---

echo "\n[3] Анализ системных вызовов команды 'ls' через strace..." >> "$LOG_DIR/report.txt"
strace -o "$LOG_DIR/strace_ls.log" ls /tmp
echo "Список системных вызовов записан в $LOG_DIR/strace_ls.log" >> "$LOG_DIR/report.txt"

# Выводим топ-10 системных вызовов
echo "\nТоп-10 системных вызовов:" >> "$LOG_DIR/report.txt"
grep -o '^[a-z][a-z_]*' "$LOG_DIR/strace_ls.log" | sort | uniq -c | sort -nr | head -10 >> "$LOG_DIR/report.txt"

# --- 4. Оптимизация: изменение приоритета ---

echo "\n[4] Изменение приоритета процесса (nice)..." >> "$LOG_DIR/report.txt"

# Запускаем процесс с низким приоритетом
nice -n 15 sha1sum /dev/zero &
NICE_PID=$!
echo "Процесс с пониженным приоритетом запущен (PID: $NICE_PID)" >> "$LOG_DIR/report.txt"

# Сравниваем загрузку CPU через top
sleep 10
echo "\nСравнение загрузки CPU (top) для процесса с nice=15:" >> "$LOG_DIR/report.txt"
top -b -n 1 -p $NICE_PID >> "$LOG_DIR/report.txt"

# Завершаем все фоновые процессы
kill $CPU_PID $MEM_PID $DISK_PID $NICE_PID 2>/dev/null

echo "\nДиагностика завершена. Отчёт: $LOG_DIR/report.txt" >> "$LOG_DIR/report.txt"
echo "Лог strace: $LOG_DIR/strace_ls.log" >> "$LOG_DIR/report.txt"
