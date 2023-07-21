# 11.7.6 - 인덱스 변경
-- MySQL 8.0 버전에서는 대부분의 인덱스 변경 작업이 온라인 DDL로 처리가 가능하다.
/*
    전문 검색 인덱스와 공간 검색 인덱스를 제외하면 나머지 인덱스는 모두 B-Tree 자료 구조를 사용한다.
    가끔 실행 계획에 USING BTREE 또는 USING HASH 절을 이용해 해시 인덱스를 지원하는 것처럼 보이지만
    "USING HASH" 절은 MySQL Cluster (NDB)를 위한 옵션이지 MySQL 서버의 InnoDB나 MyISAM 스토리지 엔진을 위한 옵션은 아니다.
    그래서 이 RealMySQL 8.0 책에서는 해시 인덱스에 대한 설명은 생략한다고 한다.
 */

## 11.7.6.1 - 인덱스 추가
-- MySQL 서버에서 온라인 DDL이 사용 가능한 인덱스의 종류나 인덱싱 알조리즘 별로 사용 가능한 ALTER TABLE ADD INDEX 문장
-- B-Tree 자료 구조를 사용하는 인덱스 추가는 PRIMARY KEY 라고 해도 INPLACE 알고리즘에 LOCK 없이 온라인 DDL 로 인덱스 생성 가능
ALTER TABLE employees ADD PRIMARY KEY (emp_no),
    ALGORITHM = INPLACE, LOCK = NONE;

ALTER TABLE employees ADD UNIQUE INDEX ux_empno (emp_no),
    ALGORITHM = INPLACE, LOCK = NONE;

ALTER TABLE employees ADD INDEX ix_lastname (last_name),
    ALGORITHM = INPLACE, LOCK = NONE;

-- 전문 검색을 위한 인덱스와 공간 검색을 위한 인덱스는 LOCK 모드를 SHARED 로 해야 된다.
ALTER TABLE employees ADD FULLTEXT INDEX fx_firstname_lastname (first_name, last_name),
    ALGORITHM = INPLACE, LOCK = SHARED;

ALTER TABLE employees ADD SPATIAL INDEX fx_ioc (last_location),
    ALGORITHM = INPLACE, LOCK = SHARED;

## 11.7.6.2 - 인덱스 조회
-- 인덱스를 조회하려면 SHOW INDEXES(= INDEX) 명령을 사용하거나 SHOW CREATE TABLE 명령으로 보면 된다.

-- SHOW INDEXES 사용 시에는 인덱스 컬럼별로 한 줄씩 표시해준다.
-- 표시된 결과에서 인덱스 이름, 인덱스에서 해당 컬럼의 위치(단일 일 경우엔 1 복합일 경우엔 1부터 차례로 증가), 카디널리티 등 여러 정보를 표시해준다.
SHOW INDEX FROM employees;

-- 테이블 생성 구문을 그대로 보여주고, 인덱스 별로 안 줄로 표시하고, 그 인덱스에 어떤 컬럼이 어떤 순서로 구성돼 있는지 파악하기 쉽다.
SHOW CREATE TABLE employees; -- 터미널 사용시 ';' 대신 \G

## 11.7.6.3 - 인덱스 이름 변경
-- 5.6 버전까지도 인덱스의 이름을 변경할 수 없었지만 5.7 버전부터는 다음과 같이 인덱스의 이름을 변경할 수 있다.
-- 인덱스 이름을 변경하는 알고리즘으로 INPLACE 를 사용하지만 실제 테이블 리빌드를 하지 않는다. (빠르게 이름을 바꿀 수 있다.)
ALTER TABLE salaries RENAME INDEX ix_salary2 TO ix_salary,
    ALGORITHM = INPLACE, LOCK = NONE;

-- employees 테이블에 ix_firstname (first_name)을 대신해서 ix_firstname (first_name, last_name) 인덱스를 교체하는 작업 방식 예제
-- // 1. index_new 라는 이름으로 새로운 인덱스 생성
ALTER TABLE employees
  ADD INDEX index_new (first_name, last_name),
    ALGORITHM = INPLACE, LOCK = NONE;

-- // 2. 기존 인덱스(ix_firstname)를 삭제하고, 동시에 새로운 이넥스(index_new)의 이름을 ix_firstname으로 변경
ALTER TABLE employees
    DROP INDEX ix_firstname,
    RENAME INDEX index_new TO ix_firstname,
    ALGORITHM = INPLACE, LOCK = NONE;
SHOW INDEX FROM employees;

## 11.7.6.4 - 인덱스 가시성 변경
-- 인덱스를 삭제하는 작업은 즉시 삭제가 가능하다. 하지만, 같은 컬럼으로 인덱스를 생성하는 작업은 시간이 많이 든다.
-- 따라서, 걱정되는 마음에 인덱스 삭제를 잘 못하는 일이 생겼는데 8.0 버전부터는 인덱스의 가시성을 제어할 수 있는 기능이 도입됐다.
    -- 인덱스 가시성이란 MySQL 서버가 쿼리 싫행 시 해당 인덱스를 사용할 수 있게 할지 말지를 결정하는 것이다.
-- 인덱스의 가시성을 변경하는 부분은 메타데이터만 수정하면 돼서 온라인 DDL 까지 필요하지 않다.

-- 쿼리에서 특정 인덱스가 사용되지 못하게 하는 DDL 문장
ALTER TABLE employees ALTER INDEX ix_firstname INVISIBLE;
-- 인덱스가 INVISIBLE 상태로 되면 옵티마이저는 INVISIBLE 상태의 인덱스는 없는 것으로 간주하고 실행 계획을 수립한다.
EXPLAIN SELECT * FROM employees WHERE first_name = 'Matt';

-- INVISIBLE 상태의 인덱스를 다시 사용하려면 VISIBLE 옵션을 적으면 된다.
ALTER TABLE employees ALTER INDEX ix_firstname VISIBLE;
EXPLAIN SELECT * FROM employees WHERE first_name = 'Matt';
-- 8.0을 사용한다면 하루나 이틀정도 INVISIBLE 을 실행 후 지장이 없으면 인덱스를 삭제하면 된다.
-- 인덱스를 처음 생성할 때는 INVISIBLE 인덱스로 생성하고, 적절히 부하가 낮은 시점을 골라서 인덱스를 VISIBLE 로 변경하면 된다.

## 11.7.6.5 - 인덱스 삭제
-- ALTER TABLE ... DROP INDEX ... 명령으로 인덱스를 삭제할 수 있다.
-- 세컨더리 인덱스 삭제 작업은 INPLACE 알고리즘을 사용한다. INPLACE 를 사용하더라도 테이블 리빌드를 하지 않는다.
-- PK 의 삭제 작업은 모든 세컨더리 인덱스의 리프 노드에 저장된 PK 값을 삭제해야 하기 때문에 임시 테이블로 레코드를 복사해서 테이블을 재구축한다.

-- 종류별로 인덱스를 삭제하는 명령
ALTER TABLE employees DROP PRIMARY KEY, ALGORITHM = COPY, LOCK = SHARED; -- PK 삭제 시 COPY 알고리즘 과 SHARED 락 사용
ALTER TABLE employees DROP INDEX ux_empno, ALGORITHM = INPLACE, LOCK = NONE;
ALTER TABLE employees DROP INDEX fx_loc, ALGORITHM = INPLACE, LOCK = NONE;

## 11.7.6 - 테이블 변경 묶음 실행
-- 온라인 DDL로 빠르게 스키마 변경을 처리할 수 있다면 개별로 실행하는 것이 좋지만 그렇지 않다면 모아서 실행하는 것이 효율적이다.

-- 다음과 같이 인덱스를 생성해야 한다고 가정
ALTER TABLE employees ADD INDEX ix_lastname (last_name, first_name),
    ALGORITHM = INPLACE, LOCK = NONE;

ALTER TABLE employees ADD INDEX ix_birthdate (birth_date),
    ALGORITHM = INPLACE, LOCK = NONE;
/*
    2 개의 ALTER TABLE 명령으로 인덱스를 각각 생성하면 인덱스를 생성할 때마다 테이블의 레코드를 풀 스캔해서 인덱스를 생성한다.
    하지만 다음과 같이 하나의 ALTER TABLE 명령으로 모아서 실행하면 테이블의 레코드를 한 번만 풀 스캔해서 2개의 인덱스를 한꺼번에 생성할 수 있다.
 */
-- 만약 두 개의 인덱스를 생성할 때 하난s INSTANT 알고리즘을 사용하고, 다른 하나는 INPLACE 알고리즘을 사용한다면 굳이 모아서 실행할 필요는 없다.
-- 같은 아로길즘을 사용하는 스키마 변경 작업이라면 모아서 실행하는 것이 효율적이다.
-- INPLACE 알고리즘이라고 하더라도 테이블 리빌드가 필요한 작업과 그렇지 않는 작업끼리도 구분하고 모아서 실행하면 더 효율적이다.
ALTER TABLE employees
    ADD INDEX ix_lastname (last_name, first_name),
    ADD INDEX ix_birthdate (birth_date),
    ALGORITHM = INPLACE, LOCK = NONE;

## 11.7.7 - 프로세스 조회 및 강제 종료
-- MySQL 서버에 접속된 사용자의 목록이나 각 클라이언트 사용자가 현재 어떤 쿼리를 실행하고 있는지 SHOW PROCESSLIST 명령으로 확인할 수 있다.
-- SHOW PROCESSLIST 명령의 결과에는 현재 MySQL 서버에 접속된 클라이언트의 요청을 처리하는 스레드 수만큼의 레코드가 표시된다.
/*
    각 컬럼에 포함된 값의 의미는 다음과 같다.

    Id : MySQL 서버의 스레드 아이디이며, 쿼리나 커넥션을 강제 종료할 때는 이 컬럼 값을 식별자로 사용한다.
    User : 클라이언트가 MySQL 서버에 접속할 때 인증에 사용한 사용자 계정을 의미한다.
    Host : 클라이언트의 호스트명이나 IP 주소가 표시된다.
    db : 클라이언트가 기본으로 사용하는 데이터베이스의 이름이 표시된다.
    Command : 해당 스레드가 현재 어떤 작업을 처리하고 있는지 표시된다. - 대분류의 작업 내용을 보여준다.
    Time : Command 컬럼에 표시되는 작업이 얼마나 실행되고 있는지 표시한다.
    State : 해당 스레드가 처리하고 있는 소분류 작업 내용을 보여준다.
            자세한 내용으로는 https://dev.mysql.com/doc/refman/8.0/en/general-thread-states.html 여기를 확인해보자.
    Info : 해당 스레드가 실행 중인 쿼리 문장을 보여준다. 쿼리는 화면의 크기에 맞춰서 표시 가능한 부분까지만 표시된다.
           쿼리의 모든 내용을 확인하려면 SHOW FULL PROCESSLIST 명령을 사용하면 된다.
 */
-- 대부분 프로세스의 Command 컬럼이 Sleep 상태로 표시된다. 그런데,
-- Command 컬럼의 값이 'Query'이면서 Time 값이 상당히 큰 값을 가지고 있다면 쿼리가 장시간 실행되고 있음을 의미한다. 확인해봐야 됨
-- SHOW PROCESSLIST 의 결과에서 특별히 관심을 둬야 할 부분은 State 컬럼의 내용이다.
    -- State 칼럼의 내용중 'Copying ...', 'Sorted ...' 으로 시작하는 값들이 표시될 때 주의깊게 살펴볼 필요가 있다.
SHOW PROCESSLIST;

-- 특정 스레드에서 실행 중인 쿼리나 커넥션 자체를 강제 종료 하려면 KILL Id; 하면 된다.
KILL QUERY 5; -- Id 5번의 쿼리를 강제 종료
KILL 5; -- Id 5번의 커넥션을 강제 종료 트랜잭셕은 자동으로 롤백된다.


## 11.7.8 - 활성 트랜잭션 조회
-- 쿼리가 오랜 시간 실행되고 있는 경우도 문제지만 트랜잭션이 오랜 시간 완료되지 않고 활성 상태로 남아있는것도 MySQL 서버의 성능에 영향을 준다.
-- MySQL 서버의 트랜잭션 목록을 확인하는 법은 information_schema.innodb_trx 테이블을 통해 확인할 수 있다.

-- 5초 이상 활성 상태로 남아있는 프로세스만 조사하는 쿼리
SELECT trx_id,
       (SELECT CONCAT(user, '@', host)
        FROM information_schema.processlist
        WHERE id = trx_mysql_thread_id) AS source_info,
    trx_state,
    trx_started,
    now(),
    (unix_timestamp(now()) - unix_timestamp(trx_started)) AS lasting_sec,
    trx_requested_lock_id,
    trx_wait_started,
    trx_mysql_thread_id,
    trx_tables_in_use,
    trx_tables_locked
FROM information_schema.innodb_trx
WHERE (unix_timestamp(now()) - unix_timestamp(trx_started)) > 5;

-- 평상시보다 오랜 시간 트랜잭션이 활성 상태를 유지하고 있다면
    -- information_schema.innodb_trx 테이블에서 정보를 조회 후 해당 트랜잭션이 얼마나 많은 레코드를 변경했고,
    -- 얼마나 많은 레코드를 잠그고 있는지 확인해 보면 된다.
-- trx_rows_modified 컬럼과 trx_rows_locked 컬럼의 값을 참조해서 몇 개의 레코드를 변경했고, 몇 개의 레코드에 대한 잠금이 표시된다.
SELECT * FROM information_schema.innodb_trx WHERE trx_id = 확인해볼_id;

-- 어떤 레코드를 잠그고 있는지는 performance_schema.data_locks 테이블을 참조하면 된다.
SELECT * FROM performance_schema.data_locks;

-- 응용 프로그램에서 쿼리의 에러를 감지해서 트랜잭션을 롤백하게 돼 있다면 쿼리만 종료하고, 핸들링이 확실하지 않다면 커넥션 자체를 종료하자.
