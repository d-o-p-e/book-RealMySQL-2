# 11.7.2 - 데이터베이스 변경
-- MySQL 에서 하나으 ㅣ인스턴스는 1개 이상의 데이터베이스를 가질 수 있다.
-- 다른 RDBMS 에서는 스키마(Schema)와 데이터베이스를 구분해서 관리하지만 MySQL 에서는 스키마와 데이터베이스는 동격의 개념이다.
-- 그래서 MySQL 서버에서는 굳이 스키마를 명시적으로 사용하지 않는다.
-- 디스크를 물리적인 저장소를 구분하기도 하지만 여러 데이터베이스의 테이블을 묶어서 조인 쿼리를 사용할 수도 있기 때문에 단순히 논리적인 개념이기도 하다.
-- 그래서 데이터베이스 단위로 변경하거나 설정하는 DDL 명령은 그다지 많지 않다.
-- 데이터베이스에 설정할 수 있는 옵션은 기본 문자 집합이나 콜레이션을 설정하는 정도이므로 간단한다.

## 11.7.2.1 - 데이터베이스 생성
-- 기본 문자 집합과 콜레이션으로 employees 라는 데베 생성
-- 기본 문자 집합이라 함은 MySQL 서버의 character_set_server 시스템 변수에 정의된 문자 집합을 사용한다는 의미이다.
CREATE DATABASE [IF NOT EXISTS] 생성할_데이터베이스_이름;

-- 별도의 문자 집합과 콜레이션이 지정된 데베 생성
CREATE DATABASE [IF NOT EXISTS] 생성할_데이터베이스_이름 CHARACTER SET utf8mb4;
CREATE DATABASE [IF NOT EXISTS] 생성할_데이터베이스_이름
    CHARACTER SET utf8mb4 COLLATE utf8md4_general_ci;

## 11.7.2.2 - 데이터베이스 목록
SHOW DATABASES;
SHOW DATABASES LIKE '%emp%';

## 11.7.2.3 - 데이터베이스 선택
USE 사용할_데이터베이스_이름;

## 11.7.2.4 - 데이터베이스 속성 변경
ALTER DATABASE employees CHARACTER SET=euckr COLLATE = utf8mb4_0900_ai_ci;
ALTER DATABASE employees CHARACTER SET=utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- 데이터베이스의 캐릭터 셋이나 collation 확인하는 쿼리
SELECT default_character_set_name, DEFAULT_COLLATION_NAME FROM information_schema.SCHEMATA
WHERE schema_name = '확인하고싶은_데이터베이스_이름';

## 11.7.2.5 - 데이터베이스 삭제
DROP DATABASE [IF EXISTS] 삭제할_데이터베이스_이름;



