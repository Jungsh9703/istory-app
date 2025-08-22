#!/bin/bash
set -euo pipefail

# 이전 프로세스 종료
CURRENT_PID=$(pgrep -f "java -jar .*\.jar" || true)

if [ -z "$CURRENT_PID" ]; then
    echo "No spring boot application is running."
else
    echo "Kill process: $CURRENT_PID"
    kill -15 $CURRENT_PID || true
    sleep 5
    if ps -p $CURRENT_PID >/dev/null 2>&1; then
        echo "Force kill $CURRENT_PID"
        kill -9 $CURRENT_PID || true
    fi
fi