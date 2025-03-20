# Docker AWS-like Services Scripts

이 프로젝트는 Docker 컨테이너를 이용하여 AWS의 RDS, EC2, S3, Route53과 유사한 서비스를 구축하고 관리할 수 있도록 세 가지 Bash 스크립트를 제공합니다.

- **create.sh**: 지정한 서비스 유형에 따라 컨테이너를 생성 및 초기화합니다.
- **access.sh**: 생성된 컨테이너에 접속합니다. RDS 컨테이너의 경우 저장된 MySQL root 비밀번호를 이용하여 자동으로 MySQL 클라이언트에 접속합니다.
- **address.sh**: 사용자 정의 네트워크(`mynetwork`)에 연결된 컨테이너들의 정보를 보기 좋은 테이블 형식으로 출력하며, 인자로 전달된 서비스 유형에 따라 필터링할 수 있습니다.

---

## Prerequisites

- **Docker**가 설치되어 있고 실행 중이어야 합니다.
- 스크립트는 기본적으로 Docker 사용자 정의 네트워크 `mynetwork`를 사용합니다.  
  이 네트워크가 없으면 `create.sh` 스크립트가 자동으로 생성합니다.
- 터미널은 ANSI 컬러 코드(색상 출력)를 지원해야 합니다.

---

## Scripts

### 1. create.sh

**용도**:  
서비스 유형(예: rds, ec2, s3, route53)과 컨테이너 이름을 인자로 받아 Docker 컨테이너를 생성합니다.  
컨테이너 이름은 `base.service` 형식이어야 하며, 서비스에 따라 이름 끝에 `.rds`, `.ec2`, `.s3` 또는 `.route53`이 포함되어야 합니다.

**사용법**:
```bash
./create.sh <service-type> <container-name> [-recreate]
```
매개변수:

<service-type>: 서비스 유형
예: rds, ec2, s3, route53
<container-name>: 컨테이너 이름 (형식 예: real-estate.rds, data-center.ec2, my-s3.s3)
-recreate (선택사항): 동일 이름의 컨테이너가 존재하면 무조건 삭제 후 재생성합니다.
별도 입력하지 않으면 재생성 여부를 사용자에게 물어봅니다.
특징:

RDS 컨테이너 생성 시:
MySQL 컨테이너를 생성합니다.
스크립트 실행 시 MySQL root 비밀번호를 프롬프트에서 입력받고, 해당 비밀번호를 컨테이너 데이터 디렉터리(./<container-name>/pwd)에 저장합니다.
EC2 컨테이너 생성 시:
Ubuntu 컨테이너를 생성하며, mysql-client 패키지를 미리 설치하여 MySQL 클라이언트를 사용할 수 있도록 합니다.
SSH 접속을 위해 컨테이너 내부의 포트 22를 호스트의 2222 포트에 매핑합니다.
S3와 Route53도 각각 적절한 공식 이미지를 사용하여 컨테이너를 생성합니다.
모든 컨테이너는 사용자 정의 네트워크(mynetwork)에 연결됩니다.
예시:

bash
복사
# RDS(MySQL) 컨테이너 생성
```bash
./create.sh rds real-estate
```
# EC2(Ubuntu) 컨테이너 생성 (기존 컨테이너가 있다면 강제로 재생성)

```bash
./create.sh ec2 data-center -recreate
```

2. access.sh
용도:
생성된 컨테이너에 접속합니다.

컨테이너 이름이 .rds로 끝나면, 저장된 MySQL root 비밀번호를 읽어 MySQL 클라이언트로 자동 접속합니다.
기타 서비스(예: ec2, s3, route53)는 단순히 bash(또는 sh) 셸을 실행하여 접속합니다.
사용법:

```bash
./access.sh <container-name>
```
매개변수:

<container-name>: 접속할 컨테이너의 이름 (예: real-estate.rds, data-center.ec2)
예시:

bash
복사
# RDS 컨테이너에 접속 (MySQL 클라이언트 자동 실행)
```bash
./access.sh real-estate.rds
```

# EC2 컨테이너에 접속 (bash 셸 실행)
```bash
./access.sh data-center.ec2
```
3. address.sh
용도:
Docker 사용자 정의 네트워크(mynetwork)에 연결된 컨테이너들의 정보를 보기 좋게 테이블 형식으로 출력합니다.

출력 항목: Service, Container, IP, PublishedPorts
컨테이너 이름은 base.service 형식으로 되어 있으며, 여기서 마지막 필드(예: rds, ec2, s3, route53)를 서비스 유형으로 사용합니다.
출력 시 서비스명은 대문자로 표시되며, 서비스 유형에 따라 서로 다른 색상으로 강조됩니다.
사용법:

```bash
./address.sh [service1] [service2] ...
```
매개변수:

인자가 없으면, 네트워크에 연결된 모든 컨테이너를 출력합니다.
인자로 서비스 유형을 전달하면, 해당 서비스에 해당하는 컨테이너들만 출력합니다.
예: ./address.sh rds ec2는 rds와 ec2에 해당하는 컨테이너만 출력합니다.
예시:

bash
복사
# 모든 컨테이너 정보 출력
```bash
./address.sh
```

# RDS와 EC2 컨테이너 정보만 출력
```bash
./address.sh rds ec2
```
출력 예시:

```bash
Filtered Services: All

SERVICE      Container                 IP              PublishedPorts
-------      ---------                 --------------- --------------------------------------------------
[1;32mRDS[0m         real-estate.rds           172.18.0.2      3306/tcp -> 0.0.0.0:3306;33060/tcp -> 0.0.0.0:33060
[1;34mEC2[0m         data-center.ec2           172.18.0.3      2222/tcp -> 0.0.0.0:2222
```

주의: 출력되는 ANSI 색상 코드는 터미널이 색상을 지원하는 경우에만 올바르게 표시됩니다.

요약
create.sh: 서비스 유형과 컨테이너 이름을 인자로 받아 해당 서비스에 맞는 Docker 컨테이너를 생성합니다.
access.sh: 지정한 컨테이너에 접속합니다. RDS 컨테이너인 경우 자동으로 MySQL 클라이언트에 접속합니다.
address.sh: 사용자 정의 네트워크에 연결된 컨테이너들의 상세 정보를 정렬된 테이블 형식으로 출력하며, 인자에 따라 특정 서비스만 필터링할 수 있습니다.
각 스크립트를 실행하기 전에 반드시 실행 권한을 부여하시기 바랍니다:
```bash
chmod +x create.sh access.sh address.sh
```
이제 이 스크립트들을 활용하여 Docker 컨테이너 기반의 AWS 유사 서비스를 손쉽게 관리하고 모니터링할 수 있습니다.
