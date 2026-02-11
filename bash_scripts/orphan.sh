#!/bin/bash

# Скрипт для анализа статусов процессов "родитель" - "дочерний/сирота"

echo "Main script PID: $BASHPID"


TMPFILE=$(mktemp)

(   
    echo "Creating parent PID (from main)..."
    echo "Parent PID: $BASHPID"

    # Родитель явно запускает новый bash как child
    bash -c '
        echo
        echo "Creating child PID (from parent)..."
        echo "Child PID: $BASHPID"
        echo "Child initial PPID: $PPID"
        echo
        sleep 5
        echo
        sleep 1
        NEW_PPID=$(ps -o ppid= -p $$)
        echo "Child after parent death. New PPID: $NEW_PPID"
        sleep 30
    ' &

    CHILD_PID=$!
    echo $CHILD_PID > "$TMPFILE"

    sleep 1
    echo "Parent will be killed now (SIGKILL)"
    echo
    echo "=== SHELL MESSAGE ==="
    kill -9 $BASHPID
    echo "=== SHELL MESSAGE END ==="

) &

PARENT_PID=$!

echo
sleep 2

CHILD_PID=$(cat "$TMPFILE")
rm "$TMPFILE"

sleep 6

echo
echo "=== Process status via ps ==="

echo "Parent:"
ps -o pid,ppid,stat,cmd -p $PARENT_PID || echo "Parent not found"

echo
echo "Child:"
ps -o pid,ppid,stat,cmd -p $CHILD_PID || echo "Child not found"
