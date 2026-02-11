#!/bin/bash
echo "Main script PID: $BASHPID"
TMPFILE=$(mktemp)

(
    echo "Parent PID: $BASHPID"
    bash -c '
        echo "Child PID: $$"
        sleep 1
        echo "Child exiting..."
        exit 42
    ' &
    CHILD_PID=$!
    echo $CHILD_PID > "$TMPFILE"

    trap "" SIGCHLD
    echo "SIGCHLD handler: $(trap -p SIGCHLD)"
    echo "Parent sleeping 30s..."
    sleep 30
) &
PARENT_PID=$!

CHILD_PID=$(cat "$TMPFILE"); rm "$TMPFILE"

echo "Checking for zombie (20 attempts)..."
for i in {1..20}; do
    sleep 0.5
    ps -o pid,ppid,stat,comm -p $CHILD_PID 2>/dev/null | grep Z && break
done

echo "Final ps check:"
ps -o pid,ppid,stat,comm -p $CHILD_PID 2>/dev/null || echo "No zombie found"
