# 11.7.4 - 테이블 변경
-- 사용자의 데이터를 가지는 주체 MySQL 서버의 많은 옵션 인덱스 등의 기능이 테이블에 종속된다.

## 11.7.4.1 - 테이블 생성
CREATE [TEMPORARY] TABLE [IF NOT EXISTS] tb_test (
    member_id   BIGINT [UNSIGNED] [AUTO_INCREMENT],
    nickname    CHAR(20) [CHARACTER SET 'utf8'] [COLLATE utf8mb4_general_ci] [NOT NULL],
    home_url    VARCHAR(200) [COLLATE 'latin1_general_cs'],
    birth_year  SMALLINT (4) [UNSIGNED] [ZEROFILL],
    member_point INT [NOT NULL] [DEFAULT 0],
    registered_dttm DATETIME [NOT NULL] ,
    modified_ts TIMESTAMP [NOT NULL] [DEFAULT CURRENT_TIMESTAMP],
    gender ENUM('Female', 'Male') [NOT NULL],
    hobby   SET('Reading', 'Game', 'Sports'),
    profile TEXT [NOT NULL],
    session_data BLOB,
    PRIMARY KEY (member_id),
    UNIQUE INDEX ux_nickname (nickname),
    INDEX ix_registereddttm (registered_dttm)
) ENGINE = INNODB;
/*
    TEMPORARY 키워드를 사용하면 해당 데이터베이스 커넥션(세션)에서만 사용 가능한 임시 테이블을 생성한다.
    같은 이름의 테이블이 있으면 에러가 발생, (IF NOT EXISTS 옵션이 있으면 무시)

    각 컬럼은 "컬럼명 + 컬럼타입 + [타입별 옵션] + [NULL 여부] + [기본값]"의 순서로 명시하고, 타입별로 옵션을 추가할 수 있다.
    모든 컬럼은 공통적으로 컬럼의 초깃값을 설정하는 DEFAULT 절과 컬럼의 NULL 을 가질 수 있는지 여부를 체크할 수 있다.
    문자열 타입은 타입 뒤에 반드시 커럼의 최대한 저장할 수 있는 문자 수를 명시해야 한다.
    숫자 타입 ~
    날짜 타입 ~
    각 컬럼별로 사용할 수 있는 속성이나 특성은 15장에서 살펴보자.
 */

## 11.7.4.2 - 테이블 구조 조회
-- SHOW CREATE TABLE 과 DESC 두 가지가 있다.

-- CREATE TABLE 문장을 보여준다.
-- 최초 테이블의 문장이 아니라 MySQL 서버가 테이블의 메타 정보를 읽어서 CREATE 문장으로 재작성해 보여준다.
    -- CREATE 문을 수정 없이 바로 사용할 수 있어 유용하게 사용할 수 있다.
-- 컬럼의 목록, 인덱스, 외래키 정보를 동시에 보여주기 때문에 SQL 튜닝할 때나 테이블 구조를 확인할 때 주로 사용된다.
SHOW CREATE TABLE employees\G; -- \G 는 터미널에서 사용해야 됨.

-- 표로 보여준다.
-- 인덱스 컬럼의 순서, 외래키, 테이블 자체의 속성을 보여주지는 않으므로 전체적인 구조를 한 번에 확인하기는 어렵다.
DESC employees;

## 11.7.4.3 - 테이블 구조 변경
-- 테이블의 구조를 변경하려면 ALTER TABLE 명령을 사용한다.
-- 테이블 자체의 속성을 변경할 수 있고, 인덱스의 추가 / 삭제, 컬럼의 추가 / 삭제도 가능하다.
-- 거의 스키마를 변경하는 작업에 사용된다.
ALTER TABLE employees
  CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  ALGORITHM = INPLACE, LOCK = NONE;

-- 이 아래 쿼리는 기존 테이블의 엔진과 동일해도 테이블의 데이터를 복사하는 작업은 실행되기 때문에 주의해야 한다.
-- 실제 테이블의 스토리지 엔진을 변경하는 목적으로도 사용되지만, 테이블 데이터를 리빌드 하는 작업으로도 사용된다.
/*
    테이블 리빌드 작업은 주로 레코드의 삭제가 자주 발생하는 테이블에서
    데이터가 저장되지 않는 빈 공간(Fragmentation)을 제거해 디스크 사용 공간을 줄이는 역할을 한다.
 */
ALTER TABLE employees ENGINE = InnoDB
  ALGORITHM = INPLACE, LOCK = NONE;

## 11.7.4.4 테이블 명 변경
-- 테이블명을 변경하려면 RENAME TABLE 명령을 이용하면 된다.
-- RENAME TABLE 멸령은 테이블 이름 변경 뿐만 아니라 다른 데이터베이스로 테이블을 이동할 때도 사용한다.

-- 테이블 명 변경, 메타 정보만 수정하기 때문에 빠르게 동작한다.
RENAME TABLE 변경하고싶은_테이블_명 TO 변경할_테이블_이름;

-- 다른 DB로 이동
-- 메타 정보 뿐만 아니라 테이블이 저장된 파일까지 다른 디렉터리로 이동해야 한다.
-- db1과 db2가 서로 다른 파티션에 만들어졌따고 가정하면 데이터 파일을 다른 파티션에 복사하고,
    -- 복사가 완료된 후 원본 파티션의 파일을 삭제하는 형태로 동작한다. 파일 크기에 비례해서 시간이 소요된다.
RENAME TABLE db1.table1 TO db2.table2;

-- 한 번에 여러 테이블 이름 변경
RENAME TABLE batch TO batch_old,
			 batch_new TO batch;

## 11.7.4.5 - 테이블 상세 조회
-- MySQL의 모든 테이블은 만들어진 시간, 대략의 레코드 건수, 데이터 파일의 크기 등의 정보를 가지고 있다.
-- 이러한 정보를 조회할 수 있는 명령이 SHOW TABLE STATUS ... 다. 'LIKE 패턴' 이러한 형식으로 조합해서 사용할 수도 있다.
-- 테이블의 크기가 너무 커서 전체 레코드 건수가 궁금한 경우에도 SHOW TABLE STATUS 명령을 유용하게 사용할 수 있다.
SHOW TABLE STATUS LIKE 'employees';

-- 테이블의 상태 정보는 SHOW TABLE STATUS 명령 뿐만 아니라 SELECT 쿼리를 이용해서 조회할 수 있다
SELECT * FROM information_schema.TABLES
WHERE table_schema = 'employees' AND table_name = 'employees';

-- MySQL 서버에 존재하는 테이블들이 사용되는 디스크 공간 정보 조회하는 쿼리
SELECT table_schema,
       SUM(data_length) / 1024 / 1024 as data_size_mb,
       SUM(index_length) / 1024 / 1024 as index_size_mb
FROM information_schema.tables
GROUP BY table_schema;

## 11.7.4.6 - 테이블 구조 복사
-- 데이터는 복사하지 않고 테이블의 구조만 동일하게 복사하는 명령으로 CREATE TABLE ... LIKE 를 사용하면 된다.

-- employees 테이블의 존재하는 모든 컬럼과 인덱스가 같은 temp_employees 테이블 생성 예제
CREATE TABLE temp_employees LIKE employees;
SHOW CREATE TABLE temp_employees;

-- 데이터까지 복사하려면 위의 방식대로 테이블을 생성한 후 INSERT ... SELECT 를 실행하면 된다.
INSERT INTO temp_employees SELECT * FROM employees;

/*
    MySQL 에서 특정 테이블에 대한 트랜잭션 로그를 활성화하거나 비활성화하는 기능은 제곧되지 않는다.
    CTAS 는 리두 로그를 사용하지 않아서 더 빠르다는 이야기는 아직 MySQL 에서 해당하지 않는다.
    결국 MySQL 서버에서 CTAS(CREATE TABLE ... AS SELECT ...) 구문은
    CREATE TABLE 과 INSERT ... SELECT ... 이 두 문장으로 나눠서 실행하는 것과 성능적인 차이가 없다.
    확인하는 방법으로는 다음과 같다.
 */
 -- 아래 쿼리에서 LOG 부분의 Log sequence number 를 확인 후
SHOW ENGINE INNODB STATUS \G;
-- CTAS(CREATE TABLE ... AS SELECT ...) 구문으로 생성
CREATE TABLE salries_temp AS SELECT * FROM salaries;
-- 다시 확인해보면 Log sequence number 가 약 209MB(salaries 테이블 크기) 정도의 리두 로그가 증가했다는걸 알 수 있다.
SHOW ENGINE INNODB STATUS \G;

## 11.7.4.7 - 테이블 삭제
-- 8.0 버전에서는 특정 테이블을 삭제하는 작업이 다른 테이블의 DML이나 쿼리를 직접 방해하지 않는다.
-- 하지만 용량이 큰 테이블을 삭제하는 경우에는 심지어 해당 테이블이 디스크에서 파일의 조각들이 분산되어 저장돼 있다면
-- 많은 디스크 I/O 작업이 필요하다. 이로인해 MySQL 서버는 다른 커넥션의 쿼리 처리 성능이 떨어질 수도 있다.
    -- 테이블 삭제가 직접적인 방해를 하진 않지만 간접적으로 영향을 미칠 수 있다.
    -- 사용하는 리눅스 파일 시스템이 ext4 전이라면 테이블 삭제를 주의하고 4이상이면 괜찮다.

-- 테이블을 삭제할 때 또 다른 주의사항으로 InnoDB 스토리지 엔진의 어댑티브 해시 인덱스(이하 AHI, Adaptive Hash Index)가 있다.
-- AHI 는 InnoDB 버퍼 풀의 각 페이지가 가진 레코드에 대한 해시 인덱스 기능을 제공한다.
-- AHI 가 활성화돼 있는 경우 테이블이 삭제되면 AHI 도 모두 삭제해야 한다.
-- AHI 가 삭제될 테이블에 대한 정보를 많이 가지고 있다면 AHI 삭제 작업으로 MySQL 서버의 부하가 높아진다.
    -- 이로 인해 간접적으로 다른 쿼리 처리에 영향을 미칠 수 있다.
    -- 테이블 삭제 뿐만 아니라 테이블의 스키마 변경에도 영향을 미칠 수 있으니 주의해야 한다.
-- AHI 는 자주 사용되는 테이블에 대해서만 해시 인덱스를 빌드하기 때문에 거의 사용되지 않는 테이블이라면 크게 문제 되지 않을 수도 있다.
