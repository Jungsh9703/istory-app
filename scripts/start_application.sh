#!/bin/bash
set -euo pipefail

APP_DIR="/home/ec2-user/app"
LOG_DIR="$APP_DIR/logs"
SERVER_PORT="${SERVER_PORT:-8080}"
JAVA_OPTS="${JAVA_OPTS:--Xms512m -Xmx1024m}"

cd "$APP_DIR"

# 필요한 디렉토리 생성
mkdir -p "$LOG_DIR"

# 선제적으로 기존 프로세스 정리 (ApplicationStop이 실패했을 경우 대비)
CURRENT_PID=$(pgrep -f "java -jar .*\\.jar" || true)
if [ -n "${CURRENT_PID}" ]; then
    echo "Kill stale process: ${CURRENT_PID}"
    kill -15 ${CURRENT_PID} || true
    sleep 5
    if ps -p ${CURRENT_PID} >/dev/null 2>&1; then
        echo "Force kill ${CURRENT_PID}"
        kill -9 ${CURRENT_PID} || true
    fi
fi

# 실행할 JAR 선택 (가장 최근 빌드)
JAR_FILE=$(ls -1t *.jar 2>/dev/null | head -n 1 || true)
if [ -z "${JAR_FILE}" ]; then
    echo "No JAR found in ${APP_DIR}"
    exit 1
fi
echo "Launching ${JAR_FILE} on port ${SERVER_PORT}"

# 애플리케이션 시작
nohup java ${JAVA_OPTS} -jar "${JAR_FILE}" --server.port=${SERVER_PORT} --server.address=0.0.0.0 > "${LOG_DIR}/application.log" 2>&1 &
echo $! > "${APP_DIR}/pid.file"

# 헬스체크 대기 (최대 10분)
HEALTH_URL="http://127.0.0.1:${SERVER_PORT}/actuator/health"
ATTEMPTS=60
SLEEP_SECONDS=10
for i in $(seq 1 ${ATTEMPTS}); do
  if curl -fsS "${HEALTH_URL}" | grep -q 'UP'; then
    echo "Application is UP"
    exit 0
  fi
  echo "Waiting for application to be healthy... (${i}/${ATTEMPTS})"
  sleep ${SLEEP_SECONDS}
done

echo "Application failed to become healthy. Last 200 lines of log:"
tail -n 200 "${LOG_DIR}/application.log" || true
exit 1