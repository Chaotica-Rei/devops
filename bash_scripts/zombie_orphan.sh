#!/bin/bash

echo "Main script PID: $$"

# Запускаем "родительский" процесс в фоне
(
    echo "Parent PID: $$"

    # Запускаем дочерний процесс
    (
        echo "Child PID: $$"
        echo "Child initial PPID: $PPID"

        # Даем время родителю умереть
        sleep 5

        echo "Child after parent death. New PPID: $PPID"

        # Держим процесс живым, чтобы его можно было увидеть в ps
        sleep 30
    ) &

    CHILD_PID=$!
    echo "Child real PID (from parent): $CHILD_PID"

    # Небольшая пауза, чтобы дочерний точно стартовал
    sleep 1

    echo "Parent will be killed now (SIGKILL)"
    kill -9 $$

) &

PARENT_PID=$!

echo "Spawned parent PID (from main): $PARENT_PID"

# Подождем, пока родитель умрет, а ребенок станет сиротой
sleep 7

echo
echo "=== Process status via ps ==="
ps -o pid,ppid,stat,cmd -p $PARENT_PID --no-headers 2>/dev/null || echo "Parent process is not found (terminated)"
ps -o pid,ppid,stat,cmd --ppid 1 | grep sleep || true
