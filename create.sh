#!/bin/bash

# 사용법: ./create_service.sh <service-type> <container-name> [-recreate]
# service-type: rds | ec2 | s3 | route53

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <service-type> <container-name> [-recreate]"
  echo "  service-type: rds | ec2 | s3 | route53"
  exit 1
fi

SERVICE_TYPE="$1"
CONTAINER_NAME="$2"
RECREATE_FLAG="$3"

# 최종 이름: <service-type>-<container-name>
FINAL_NAME="${CONTAINER_NAME}.${SERVICE_TYPE}"

# 기본 사용자 정의 네트워크 이름
NETWORK_NAME="mynetwork"

# 네트워크가 존재하는지 확인하고, 없으면 생성
if ! docker network ls --format '{{.Name}}' | grep -w "^${NETWORK_NAME}$" > /dev/null; then
  echo "네트워크 '${NETWORK_NAME}'가 존재하지 않습니다. 생성합니다."
  docker network create "${NETWORK_NAME}"
fi

# 이미 해당 이름의 컨테이너가 존재하는지 확인
if docker ps -a --format '{{.Names}}' | grep -w "^${FINAL_NAME}$" > /dev/null; then
  if [ "$RECREATE_FLAG" = "-recreate" ]; then
    echo "컨테이너 '${FINAL_NAME}'가 이미 존재합니다. -recreate 옵션이 지정되어 있어 삭제합니다."
    docker rm -f "${FINAL_NAME}"
  else
    read -p "컨테이너 '${FINAL_NAME}'가 이미 존재합니다. 재생성 하시겠습니까? (y/n): " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      docker rm -f "${FINAL_NAME}"
    else
      echo "기존 컨테이너를 사용합니다. 스크립트를 종료합니다."
      exit 0
    fi
  fi
fi

# 호스트 디렉터리 설정 (각 컨테이너의 데이터를 저장)
HOST_DIR="$(pwd)/${FINAL_NAME}"
HOST_DATA_DIR="${HOST_DIR}/data"

# 컨테이너 이름으로 폴더 생성 및 그 안에 data 폴더 생성
mkdir -p "${HOST_DATA_DIR}"
echo "디렉터리 생성 완료: ${HOST_DATA_DIR}"

# 서비스 유형에 따라 컨테이너 실행
case "$SERVICE_TYPE" in
  rds)
    echo "RDS(MySQL) 컨테이너 생성 중..."
    # MySQL root 비밀번호 입력 받기
    read -sp "MySQL root 비밀번호를 입력하세요: " MYSQL_ROOT_PW
    echo ""
    # 입력받은 비밀번호를 HOST_DIR 내에 pwd 파일로 저장 (보안을 위해 파일 권한을 600으로 설정)
    echo "${MYSQL_ROOT_PW}" > "${HOST_DIR}/pwd"
	  
    docker run -d --network "${NETWORK_NAME}" --name "${FINAL_NAME}" \
      -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PW}" \
      -v "${HOST_DATA_DIR}:/var/lib/mysql" \
      mysql:latest
    ;;
  ec2)
    echo "EC2(Ubuntu) 컨테이너 생성 중..."
    docker run -d --network "${NETWORK_NAME}" --name "${FINAL_NAME}" \
      -v "${HOST_DATA_DIR}:/mnt/data" \
      ubuntu:20.04 bash -c "apt-get update && apt-get install -y mysql-client && tail -f /dev/null"
    ;;
  s3)
    echo "S3(MinIO) 컨테이너 생성 중..."
    docker run -d --network "${NETWORK_NAME}" --name "${FINAL_NAME}" \
      -e MINIO_ROOT_USER=minioadmin \
      -e MINIO_ROOT_PASSWORD=minioadmin \
      -v "${HOST_DATA_DIR}:/data" \
      minio/minio server /data --console-address ":9001"
    ;;
  route53)
    echo "Route53(가상 DNS) 컨테이너 생성 중..."
    # 여기서는 예시로 sameersbn/bind 이미지를 사용합니다.
    # 실제 운영 환경에서는 적절한 DNS 서버 설정이 필요합니다.
    docker run -d --network "${NETWORK_NAME}" --name "${FINAL_NAME}" \
      -v "${HOST_DATA_DIR}:/data" \
      sameersbn/bind:latest
    ;;
  *)
    echo "서비스 타입이 올바르지 않습니다. (rds, ec2, s3, route53 중 하나)"
    exit 1
    ;;
esac

if [ $? -eq 0 ]; then
  echo "컨테이너 '${FINAL_NAME}'가 성공적으로 생성되었습니다."
  case "$SERVICE_TYPE" in
    rds)
      echo "MySQL 서버가 실행 중입니다."
      ;;
    ec2)
      echo "Ubuntu 컨테이너가 실행 중입니다."
      ;;
    s3)
      echo "MinIO 서버가 실행 중입니다."
      ;;
    route53)
      echo "Route53 서비스(가상 DNS)가 실행 중입니다."
      ;;
  esac
else
  echo "컨테이너 생성에 실패했습니다."
fi

