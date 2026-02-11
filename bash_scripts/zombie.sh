#!/bin/bash

echo "Main script PID: $BASHPID"

TMPFILE=$(mktemp)

(
    echo "Creating parent PID (from main)..."
    echo "Parent PID: $BASHPID"

    # Создаём дочерний процесс, который быстро завершится
    bash -c '
        echo
        echo "Creating child (zombie candidate) PID: $$"
        echo "Child initial PPID: $PPID"
        sleep 2
        echo "Child is exiting now..."
        exit 42  # произвольный код возврата
    ' &

    CHILD_PID=$!
    echo $CHILD_PID > "$TMPFILE"

    echo "Child PID to become zombie: $CHILD_PID"
    sleep 1

    # Игнорируем SIGCHLD — родитель не будет собирать статус дочернего
    trap "" SIGCHLD

    echo "Parent ignoring SIGCHLD. Child will become zombie."
    echo "Parent will sleep for 30 seconds to keep child in zombie state."

    sleep 30

) &

PARENT_PID=$!

echo
sleep 2

CHILD_PID=$(cat "$TMPFILE")
rm "$TMPFILE"

# Ждём, пока дочерний процесс точно завершится, но родитель ещё жив
sleep 3

echo
echo "=== Process status via ps ==="

echo "Parent:"
ps -o pid,ppid,stat,comm -p $PARENT_PID || echo "Parent not found"

echo
echo "Child (should be zombie):"
ps -o pid,ppid,stat,comm -p $CHILD_PID 2>/dev/null || echo "Child not found (may have been reaped)"

# Дополнительная проверка — ищем зомби в системе
echo
echo "All zombie processes in the system:"
ps aux | awk '$8=="Z" {print $0}' || echo "No zombies found"
