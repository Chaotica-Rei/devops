#!/bin/bash

echo "Main script PID: $BASHPID"

(
    echo "Parent PID: $BASHPID"

    (
        echo "Child PID: $BASHPID"
        echo "Child initial PPID: $PPID"

        sleep 5
        echo "Child after parent death. New PPID: $PPID"
        sleep 30
    ) &

    CHILD_PID=$!
    echo "Child real PID (from parent): $CHILD_PID"

    sleep 1
    echo "Parent will be killed now (SIGKILL)"
    kill -9 $BASHPID

) &

PARENT_PID=$!

echo "Spawned parent PID (from main): $PARENT_PID"

sleep 7

echo
echo "=== Process status via ps ==="

echo "Parent:"
ps -o pid,ppid,stat,cmd -p $PARENT_PID || echo "Parent not found"

echo
echo "Child:"
ps -o pid,ppid,stat,cmd -p $CHILD_PID || echo "Child not found"
