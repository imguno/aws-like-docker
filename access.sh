#!/bin/bash
# 사용법: ./access.sh <컨테이너이름>
# 예: ./access.sh real-estate.rds
# 입력된 컨테이너 이름을 그대로 사용합니다.

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <컨테이너이름>"
  echo "Example: $0 real-estate.rds"
  exit 1
fi

# 입력 인자에서 끝의 슬래시 제거 (있을 경우)
CONTAINER_NAME=$(echo "$1" | sed 's:/*$::')

echo "접속할 컨테이너 이름: ${CONTAINER_NAME}"

# 컨테이너가 실행 중인지 확인
if ! docker ps --format '{{.Names}}' | grep -w "^${CONTAINER_NAME}$" > /dev/null; then
  echo "컨테이너 '${CONTAINER_NAME}'가 실행 중이지 않습니다. 먼저 컨테이너를 시작하세요."
  exit 1
fi

# .rds로 끝나면 MySQL 컨테이너로 판단하여 비밀번호를 읽어서 접속
if [[ "${CONTAINER_NAME}" =~ \.rds$ ]]; then
  HOST_DIR="$(pwd)/${CONTAINER_NAME}"
  if [ ! -f "${HOST_DIR}/pwd" ]; then
    echo "비밀번호 파일 (${HOST_DIR}/pwd)이 존재하지 않습니다."
    exit 1
  fi
  MYSQL_ROOT_PW=$(cat "${HOST_DIR}/pwd" | tr -d '\n ')
  echo "MySQL root 비밀번호를 사용하여 MySQL 클라이언트에 접속합니다..."
  docker exec -it "${CONTAINER_NAME}" mysql -uroot -p"${MYSQL_ROOT_PW}"
else
  echo "컨테이너 '${CONTAINER_NAME}'에 셸로 접속합니다..."
  docker exec -it "${CONTAINER_NAME}" bash || docker exec -it "${CONTAINER_NAME}" sh
fi

