#!/bin/bash
set +m # отключим job control

echo "Main script PID: $BASHPID"

TMPFILE=$(mktemp)

(
    echo "Parent PID: $BASHPID"

    # Родитель явно запускает новый bash как child
    bash -c '
        echo "Child PID: $BASHPID"
        echo "Child initial PPID: $PPID"
        sleep 5
        echo "Child after parent death. New PPID: $PPID"
        sleep 30
    ' &

    CHILD_PID=$!
    echo $CHILD_PID > "$TMPFILE"

    sleep 1
    echo "Parent will be killed now (SIGKILL)"
    kill -9 $BASHPID

) &

PARENT_PID=$!

echo "Spawned parent PID (from main): $PARENT_PID"

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
