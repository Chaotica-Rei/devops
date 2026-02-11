#!/bin/bash

echo "Main script PID: $BASHPID"

TMPFILE=$(mktemp)

(
    echo "Creating parent PID (from main)..."
    echo "Parent PID: $BASHPID"

    # Родитель запускает child-процесс, который сразу завершается, но не ждёт его (создаёт зомби)
    bash -c '
        echo
        echo "Creating child PID (from parent)..."
        echo "Child PID: $BASHPID"
        echo "Child initial PPID: $PPID"
        echo

        # Child-процесс делает что-то короткое и завершается
        sleep 2
        echo "Child is exiting now..."
        exit 0
    ' &

    CHILD_PID=$!
    echo $CHILD_PID > "$TMPFILE"

    echo "Parent will NOT wait for child. Parent will exit immediately."
    echo

    # Важный момент: родитель НЕ вызывает wait(), поэтому child становится зомби
    sleep 1
    echo "Parent exiting without waiting for child..."
    exit 0  # Родитель завершается, не забирая статус ребёнка

) &

PARENT_PID=$!

echo
sleep 3  # Даём время на создание и завершение child

CHILD_PID=$(cat "$TMPFILE")
rm "$TMPFILE"

sleep 2  # Ждём, чтобы родитель точно успел завершиться

echo
echo "=== Process status via ps ==="

echo "Parent:"
ps -o pid,ppid,stat,cmd -p $PARENT_PID || echo "Parent not found (expected, as it exited)"

echo
echo "Child (should be zombie):"
ps -o pid,ppid,stat,cmd -p $CHILD_PID 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Child not found — it might have been cleaned up already."
else
    # Дополнительно проверяем статус: ищем 'Z' в поле stat
    STATUS=$(ps -o stat= -p $CHILD_PID)
    if [[ "$STATUS" == *"Z"* ]]; then
        echo "Child is a zombie (status: $STATUS)"
    else
        echo "Child is NOT a zombie (status: $STATUS)"
    fi
fi

echo
echo "Full ps output for zombie check (looking for Z+):"
ps aux | grep -E "(PID|$CHILD_PID)" | grep -v grep
