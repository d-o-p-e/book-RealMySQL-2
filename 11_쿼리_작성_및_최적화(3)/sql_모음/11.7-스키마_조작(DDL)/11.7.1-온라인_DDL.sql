# 11.7.1 - 온라인 DDL
-- DBMS 서버의 모든 오브젝트를 생성하거나 변경하는 쿼리를 DDL(Data Definition Language)라고 한다.
-- DBMS 서버가 좋아지면서 많은 DDL이 온라인 모드로 처리할 수 있게 개선됐지만 여전히 스키마를 변경하는 작업은 오랜 시간이 걸린다.
-- 5.5 이전 버전까지는 테이블의 구조를 변경하는 동안에는 다른 커넥션에서 DML을 실행할 수 없었다.

## 11.7.1.1 - 온라인 DDL 알고리즘
-- 온라인 DDL 은 스키마를 변경하는 작업 중에도 다른 커넥션에서 데이터를 변경허거나 조회하는 작업이 가능하다.
-- 온라인 DDL은 ALGORITHM과 LOCK 옵션을 이용해 어떤 모드로 스키마 변경을 실행할지를 결정할 수 있따.
-- 온라인 DDL 기능은 테이블의 구조를 변경하거나 인덱스 추가와 같은 대부분의 작업에 대해 작동한다.
-- old_alter_table 시스템 변수를 이용해 ALTER TABLE 명령이 온라인 DDL로 작동할지 예전 방식으로 작동할지 결정할 수 있다.

-- ALGORITHM 으론 INSTANT, INPLACE, COPY 가 있고, LOCK 옵션으론 NONE, SHARED, EXCLUSIVE 가 있다.
/*
   ** INSTANT 알고리즘을 사용한다면 LOCK 옵션을 사용할 수 없고, 나머지 알고리즘은 3가지 LOCK 옵션 모두 사용 가능

   INSTANT 알고리즘 : 메타 데이터만 변경한다.
                    스키마 변경 중 테이블의 읽고 씨그는 대기한다. (스키마 변경 시간이 매우 짧기 때문에 영향은 없다.)
   INPLACE 알고리즘 : 임시 테이블로 테이터를 복사하지 않고 스키마 변경 (내부적으론 테이블을 리빌드 할 수도 있음) pk를 추가하는 작업에선 리빌드
                    스키마 변경 중에도 테이블의 읽고 쓰기 모두 가능.
   COPY 알고리즘 : 변경된 스키마를 적용한 임시 테이블을 생성, 레코드 모두 임시테이블로 복사 -> 임시 테이블을 RENAME 해서 스키마 변경
                이 방법은 읽기만 가능 쓰기 불가.

   LOCK 의 3 가지 옵션
   NONE : 아무런 잠금을 걸지 않음
   SHARED : 읽기 잠금을 걸고 스키마 변경을 실행하기 때문에 스키마 변경 중 읽기는 가능하지만 쓰기는 불가능
   EXCLUSIVE : 쓰기 잠금을 걸고 스키마 변경을 실행, 테이블의 쓰기 뿐만 아니라 읽기도 불가능
*/

-- 온라인 DDL 명령은 자금 수준도 함께 명시할 수 있다.
-- ALGORITHM 과 LOCK 옵션이 명시되지 않으면 MySQL 서버가 적절한 수준의 알고리즘과 잠금 수준을 선택한다.
ALTER TABLE salaries CHANGE to_date end_date DATE NOT NULL,
                     ALGORITHM = INPLACE, LOCK = NONE;

-- 온라인 스키마 변경 작업이 INPLACE 알고리즘을 사용하더라도 내부적으로 테이블의 리블드가 필요할 수도 있다.
-- 대표적으로 PK를 추가하는 작업은 데이터 파일에서 레코드의 저장 위치를 바꿔야 하기 때문에 리빌드가 필요하다.
/*
    INPLACE 알고리즘을 사용하는 경우는 다음과 같이 구분할 수 있다.

    데이터 재구성(테이블 리빌드)이 필요한 경우
        - 잠금을 필요로 하지 않기 때문에 읽고 쓰기는 가능하지만 테이블의 레코드 건수에 따라 상당히 많은 시간이 소요될 수도 있다.
    데이터 재구성이 필요하지 않은 경우
        - INPLACE 알고리즘을 사용하지만 INSTANT 알고리즘과 비슷하게 매우 빨리 작업이 완료 된다.
*/
-- 스키마 변경 작업을 실행하기 전에 먼저 메뉴얼과 테스트를 진행해보자. (버전별로 많은 차이가 있다.) (테이블 리빌드가 필요한지, 필요하지 않은지)

## 11.7.1.2 - 온라인 처리 가능한 스키마 변경
-- 모든 스키마 변경 작업이 온라인으로 가능하지 않다. 따라서, 필요한 스카마 변경 작업의 형태가 온라인으로 가능하지, 아닌지 확인 후 실행하는 것이 좋다.
ALTER TABLE employees DROP PRIMARY KEY, ALGORITHM = INSTANT;
ALTER TABLE employees DROP PRIMARY KEY, ALGORITHM = INPLACE LOCK=NONE;
-- 아무리 온라인 DDL 이라 하더라도 그만큼 MySQL 서버에 부하를 유발할 수 있으므로 주의해서 사용해야 한다.

## 11.7.1.3 INPLACE 알고리즘
-- INPLACE 알고리즘은 임시 테이블로 레코드를 복사하지는 않더라도 내부적으로 테이블의 모든 레코드를 리빌드 해야 하는 경우가 많다.
-- 이러한 경우 다음과 같은 과정을 거치게 된다.
/*
    1. INPLACE 스키마 변경이 지원되는 스토리지 엔진의 테이블인지 확인
    2. INPLACE 스키마 변경 준비(스키마 변경에 대한 정보를 준비해서 온라인 DDL 작업 동안 변경되는 데이터를 추적할 준비)
    3. 테이블 스키마 변경 및 새로운 DML 로깅
        3.1 이 작업은 실제 스키마를 변경을 수행하는 과정이다.
        3.2 이 작업이 수행되는 동안은 다른 커넥션의 DML 작업이 대기하지 않는다.
        3.3 이렇게 스키마를 온라인으로 변경함과 동시에 다른 스레드에서는 사용자에 의해서 발생한 DML들에 대해서 별도의 로그로 기록한다.
    4. 로그 적용(온라인 DDL 작업 동안 수집된 DML 로그를 테이블에 적용)
    5. INPLACE 스키마 변경 완료(COMMIT)

    위 과정을 보면 알 수 있듯이 2번과 4번 단계에서는 잠깐의 배타적 잠금(X) 락이 필요하며, 이 시점에서 다른 커넥션의 DML들이 잠깐 대기한다.
    3번에서 로깅되어 있는 공간은 온라인 변경 로그 라는 메모리 공간에 쌓아 두었다가 스키마 변경이 완료되면 실제 테이블로 일괄 적용한다.
*/

-- 온라인 변경 로그의 사이즈를 확인하는 쿼리
SHOW VARIABLES LIKE '%innodb_online_alter_log_max_size';
-- 스코프의 범위를 글로벌로 해야 변경할 수 있다.
SET GLOBAL innodb_online_alter_log_max_size = 134217728;
-- SET SESSION innodb_online_alter_log_max_size = 134217728; -- 에러

## 11.7.1.4 - 온라인 DDL의 실패 케이스
-- 온라인 DDL 명령은 다음과 같은 이유로 실패할 수도 있다.
-- 온라인 DDL이 INSTANT 알고리즘을 사용하는 경우 거의 시작과 동시에 작업이 완료되기 때문에 작업 도중 실패할 가능성은 거의 없다.
-- 하지만 INPLACE 알고리즘으로 실행되는 경우 내부적으로 테이블 리빌드 과정이 필요하고 최종 로그 적용 과정이 필요해서 중간 과정에서 실패할 가능성이 높다.
/*
    온라인 DDL 실패 케이스

    - ALTER TABLE 명령이 장시간 실행되고 동시에 다른 커넥션에서 DML이 많이 실행되는 경우이거나 온라인 변경 로그의 공간이 부족한 경우 실패
    - ALTER TABLE 명령이 실행되는 동안 변경 전 테이블에선 문제가 안 되지만 변경 후 문제가 되는 레코드를 INSERT 하거나 UPDATE 하면 실패
    - 스키마 변경을 위해 필요한 잠금 수준보다 낮은 잠금 옵션이 사용된 경우
    - 온라인 DDL 은 LOCK = NONE 으로 실행된다고 하더라도 변경 작업의 처음과 마지막 과정에서 잠금이 필요하다.
      이 잠금을 획득하지 못하고 타임아웃이 발생하면 실패.
    - 온라인으로 인덱스를 생성하는 작업의 경우 정렬을 위해 tmpdir 시스템 변수에 설정된 디스크의 임시 디렉터리를 사용한다.
      이 공간이 부족한 경우 또한 오란인 스키마 변경은 실패
*/

SHOW VARIABLES LIKE '%lock_wait_timeout';
SHOW VARIABLES LIKE '%tmpdir';

## 11.7.1.5 - 온라인 DDL 진행 상황 모니터링
-- 온라인 DDL 을 포함한 모든 ALTER TABLE 명령은 performance_schema 를 통해 진행 상황을 모니터링 할 수 있다.
-- 단, performance_schema 옵션(Instrument 와 Consumer 옵션)이 활성화돼야 한다.
-- performance_schema 시스템 변수 활성화 (MySQL 서버 재시작 필요)
SET GLOBAL performance_schema = ON;
SHOW VARIABLES LIKE 'performance_schema'; -- ON이 되어 있어야 된다.
SELECT @@performance_schema; -- 1

-- stage/innodb/alter% instrument 활성화
UPDATE performance_schema.setup_instruments
  SET enabled = 'YES', TIMED = 'YES'
WHERE name LIKE 'stage/innodb/alter%';
SELECT name, enabled FROM performance_schema.setup_instruments WHERE name LIKE 'stage/innodb%';

-- %stages% consumer 활성화
UPDATE performance_schema.setup_consumers
  SET enabled = 'YES'
WHERE name LIKE '%stages%';
SELECT name, enabled FROM performance_schema.setup_consumers WHERE name LIKE '%stages%';

-- 스키마 변경 작업의 진행 상황은 performance_schema.events_stages_current 테이블을 통해 확인할 수 있다.
-- 스키마 변경 종류에 따라 기록되는 내용이 조금씩 달라진다.
-- 온라인 DDL이 아닌 COPY 알고리즘으로 스키마 변경이 진행되는 경우는 다름과 같이 진행한다.
ALTER TABLE salaries DROP PRIMARY KEY, ALGORITHM = COPY, LOCK = SHARED;

-- performance_schema 를 통해 진행 상황을 확인하는 쿼리
SELECT event_name, work_completed, work_estimated
FROM performance_schema.events_stages_current;

-- 스키마 변경 작업이 온라인 DDL로 실행되는 경우 다음과 같이 다양한 상태를 보여준다.
-- 이는 올라인 DDL이 단계(Stage)별로 EVENT_NAME 컬럼의 값이 달리해서 보여기 때문이다.
ALTER TABLE salaries
ADD INDEX ix_todate (to_date),
ALGORITHM = INPLACE, LOCK = NONE;

-- work_estimated 와 work_completed 컬럼의 값을 비교해보면 ALTER TABLE 의 진행 상황을 예측할 수 있다.
SELECT event_name, work_completed, work_estimated
FROM performance_schema.events_stages_current;
-- 나중에 18장에서 더 자세히 알아보자. 일단 history 는 스키마 변경이 완료된 결과를 확인할 수 있다는 정도만 알고 넘어가자.
SELECT event_name, work_completed, work_estimated
FROM performance_schema.events_stages_history;

