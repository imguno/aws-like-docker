#!/bin/bash
# route.sh: Docker 네트워크(mynetwork)에 연결된 컨테이너들의
# Service, Container, IP, PublishedPorts 정보를 보기 좋게 출력합니다.
#
# 컨테이너 이름은 "base.service" 형식입니다.
# 예: real-estate.rds, data-center.ec2
# 인자로 서비스 유형(rds, ec2, s3 등)을 전달하면 해당 서비스의 컨테이너들만 출력합니다.

NETWORK_NAME="mynetwork"

# ANSI 컬러 코드 정의 (반드시 $'' 구문 사용)
NC=$'\033[0m'
GREEN=$'\033[1;32m'    # rds
BLUE=$'\033[1;34m'     # ec2
YELLOW=$'\033[1;33m'   # s3
RED=$'\033[1;31m'      # route53
CYAN=$'\033[1;36m'     # 기타

# 인자가 있으면 ALLOWED_SERVICES 배열로 사용, 없으면 전체 출력
ALLOWED_SERVICES=()
if [ "$#" -gt 0 ]; then
    ALLOWED_SERVICES=("$@")
fi

if [ ${#ALLOWED_SERVICES[@]} -gt 0 ]; then
    echo "Filtered Services: ${ALLOWED_SERVICES[*]}"
else
    echo "Filtered Services: All"
fi

# 탭(\t)으로 구분된 테이블 형태의 출력을 생성하여 column -t로 정렬
{
    printf "SERVICE\t\tContainer\t\tIP\t\tPublishedPorts\n"

    containers=$(docker ps --filter "network=${NETWORK_NAME}" --format "{{.Names}}")
    for container in $containers; do
        # 컨테이너 이름의 마지막 필드(마지막 '.' 이후)를 서비스 이름으로 사용
        service="${container##*.}"
        
        # 인자가 있을 경우 ALLOWED_SERVICES 배열에 해당 서비스가 포함되어 있는지 확인
        if [ ${#ALLOWED_SERVICES[@]} -gt 0 ]; then
            match=0
            for s in "${ALLOWED_SERVICES[@]}"; do
                if [ "$service" == "$s" ]; then
                    match=1
                    break
                fi
            done
            if [ $match -eq 0 ]; then
                continue
            fi
        fi

        # 서비스명을 대문자로 변환
        service_upper=$(echo "$service" | tr '[:lower:]' '[:upper:]')
        # 서비스에 따른 색상 결정
        case "$service" in
            rds) color="${GREEN}" ;;
            ec2) color="${BLUE}" ;;
            s3) color="${YELLOW}" ;;
            route53) color="${RED}" ;;
            *) color="${CYAN}" ;;
        esac
        colored_service="${color}${service_upper}${NC}"
        
        # 지정 네트워크에서의 IP 주소 추출
        ip=$(docker inspect -f '{{index .NetworkSettings.Networks "'${NETWORK_NAME}'" "IPAddress"}}' "$container")
        
        # 공개 포트를 docker port 명령으로 가져오고, 여러 포트가 있으면 세미콜론(;)으로 연결
        ports=$(docker port "$container" | awk '{print $3}' | paste -sd ";" -)
        
        printf "%s\t\t%s\t\t%s\t\t%s\n" "$colored_service" "$container" "$ip" "$ports"
    done
} | column -t -s $'\t\t'

echo ""

