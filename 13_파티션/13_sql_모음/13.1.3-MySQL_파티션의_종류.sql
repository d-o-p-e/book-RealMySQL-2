## 13.3 - MySQL 파티션의 종류
-- 다른 DBMS와 마찬가지로 MySQL 에서도 4가지 기본 파티션 기법이 제공하고 있고
-- 해시와 키 파티션에 대해서는 리니어(Linear) 파티션과 같은 추가적인 기법도 제공한다.
/*
    기본 파티셔닝 종류
    - 레인지 파티션
    - 리스트 파티션
    - 해시 파티션
    - 키 파티션
    - 해시와 키 파티션에 대해서 리니어(Linear) 파티션과 같은 추가적인 기법
*/

### 13.3.1 - 레인지 파티션
-- 파티션 키의 연속된 범위로 파티션을 정의하는 방법
-- 가장 일반적으로 사용된느 파티션 방법 중 하나다.
-- 다른 파티션 방법과는 달리 MAXVALUE라는 키워드를 이용해 명시되지 않은 범위의 키 값이 담긴 레코드를 저장하는 파티션을 정의할 수 있다.

#### 13.3.1.1 - 레인지 파티션의 용도
-- 다음과 같은 성격을 지닌 테이블에서 레인지 파티션을 사용하는 것이 좋다.
/*
    - 날짜를 기반으로 데이터가 누적되고 연도나 월, 또는 일 단위로 분석하고 삭제해야 할 때
    - 범위 기반으로 데이터를 여러 파티션에 균등하게 나눌 수 있을 때
    - 파티션 키 위주로 검색이 자주 실행될 때 (이 항목은 모든 파티션에 적용되는 내용이지만 레인지나 리스트에 더 필요한 요건이다.)
*/

#### 13.3.1.2 - 레인지 파티션 테이블 생성
DROP TABLE IF EXISTS partition_employees;
CREATE TABLE partition_employees (
    `emp_no` int NOT NULL,
  `birth_date` date NOT NULL,
  `first_name` varchar(14) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `last_name` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `gender` enum('M','F') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `hire_date` date NOT NULL,
  KEY `ix_hiredate` (`hire_date`),
  KEY `ix_gender_birthdate` (`gender`,`birth_date`),
  KEY `ix_firstname` (`first_name`,`last_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci STATS_PERSISTENT=0;
insert into partition_employees (SELECT * FROM employees);
SELECT count(*) FROM partition_employees;
ALTER TABLE partition_employees
    PARTITION BY RANGE ( YEAR(hire_date)) (
    PARTITION p0 VALUES LESS THAN (1991),
    PARTITION p1 VALUES LESS THAN (1996),
    PARTITION p2 VALUES LESS THAN (2001),
    PARTITION p3 VALUES LESS THAN MAXVALUE
);
SELECT count(*) FROM partition_employees PARTITION (p0);
SELECT count(*) FROM partition_employees PARTITION (p1);
SELECT count(*) FROM partition_employees PARTITION (p2);
SELECT count(*) FROM partition_employees PARTITION (p3);
-- select * FROM partition_employees WHERE hire_date > '2001-01-01';

#### 13.3.1.3 - 레인지 파티션의 분리와 병합
##### 13.3.1.3.1 - 단순 파티션의 추가
-- partition_employees 테이블에 2001년부터 2010년 이하인 레코드를 저장하기 위해 새로운 파티션 p4를 추가해보자.
-- 근데 아래 쿼리는 다음과 같은 에러가 발생한다.
-- [HY000][1481] MAXVALUE can only be used in last partition definition 에러 발생
-- 이유는 MAXVALUE 파티션이 2001 년 이후의 모든 레코드를 가지고 있는 상황에서 2011년 파티션이 추가되면
    -- 2011년 레코드는 두 개의 파티션에 나뉘어 저장되는 결과를 만들게 된다. 이는 하나의 레코드는 하나의 파티션에만 저장돼야 한다는 기본 조건을 벗어난다.
ALTER TABLE partition_employees -- LESS THAN MAXVALUE 때문에 에러가 발생한다.
    ADD PARTITION (PARTITION p4 VALUES LESS THAN (2011));

-- 따라서 다음과 같이 진행해야 한다.
-- 이 작업은 p3 파티션의 레코드 모두 새로운 두 개의 파티션으로 복사하는 작업을 필요로 한다.
-- p3 파티션의 레코드가 많다면 이 작업의 시간은 오래 걸리게 된다.
ALTER TABLE partition_employees ALGORITHM = INPLACE, LOCK = SHARED,
    REORGANIZE PARTITION p3 INTO (
        PARTITION p3 VALUES LESS THAN (2011),
        PARTITION p4 VALUES LESS THAN MAXVALUE
);
SELECT count(*) FROM partition_employees PARTITION (p4);

-- 레인지 파티션에서는 일반적으로 LESS THAN MAXVALUE 절을 사용하는 파티션은 추가하지 않고,
    -- 미래의 사용될 파티션을 미리 2~3개 더 만들어 두는 형태로 테이블을 생성하기도 한다.

##### 13.3.1.3.2 - 파티션 삭제
-- 파티션을 삭제하려면 DROP PARTITION 키워드에 삭제하려는 파티션의 이름을 지정하면 된다.
-- 레이진, 리스트 파티션을 사용하는 테이블에서 특정 파티션을 삭제하는 작업은 아주 빠르게 처리된다.
-- 날짜 단위로 파티션된 테이블에서 오래된 데이터를 삭제하는 용도로 자주 사용된다.
-- 책(280p)에서는 파티션 중간을 삭제할 수 없다고 하는데, 삭제가 된다.
-- 파티션을 추가할 때는 책 가장 마지막 파티션만 추가할 수 있다고 하는데 hoing 님 블로그 글을 보면 책이랑 다르다. 스터디때 얘기해봐야겠다.
-- hoing 님 블로그 예제 파티션 제일 앞에 새로운 파티션을 추가하는 예제
CREATE TABLE `tb_part_test` ( -- partition key 가 datetime 이라 가능한건가...?
  `seq` int(11) NOT NULL AUTO_INCREMENT,
  `col1` decimal(3,1) DEFAULT NULL,
  `col2` decimal(5,1) DEFAULT NULL,
  `col3` decimal(5,1) DEFAULT NULL,
  `col4` varchar(20) DEFAULT NULL,
  `datetime` varchar(13) NOT NULL COMMENT '날짜(yyyy-mm-dd;hh)',
  PRIMARY KEY (`seq`,`datetime`),
  KEY `datetime_01` (`datetime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
PARTITION BY RANGE  COLUMNS(`datetime`)
(PARTITION p202101 VALUES LESS THAN ('2021-02-01:00') ENGINE = InnoDB,
 PARTITION p202102 VALUES LESS THAN ('2021-03-01:00') ENGINE = InnoDB,
 PARTITION p202103 VALUES LESS THAN ('2021-04-01:00') ENGINE = InnoDB,
 PARTITION p202104 VALUES LESS THAN ('2021-05-01:00') ENGINE = InnoDB,
 PARTITION p202105 VALUES LESS THAN ('2021-06-01:00') ENGINE = InnoDB,
 PARTITION p202106 VALUES LESS THAN ('2021-07-01:00') ENGINE = InnoDB,
 PARTITION p202107 VALUES LESS THAN ('2021-08-01:00') ENGINE = InnoDB,
 PARTITION p202108 VALUES LESS THAN ('2021-09-01:00') ENGINE = InnoDB,
 PARTITION p202109 VALUES LESS THAN ('2021-10-01:00') ENGINE = InnoDB,
 PARTITION p202110 VALUES LESS THAN ('2021-11-01:00') ENGINE = InnoDB,
 PARTITION p202111 VALUES LESS THAN ('2021-12-01:00') ENGINE = InnoDB,
 PARTITION p202112 VALUES LESS THAN ('2022-01-01:00') ENGINE = InnoDB,
 PARTITION p999999 VALUES LESS THAN (MAXVALUE) ENGINE = InnoDB);
alter table tb_part_test ALGORITHM=INPLACE,
REORGANIZE PARTITION p202101 into (
    partition p202012 values less than ('2021-01-01:00') engine=innodb,
    partition p202101 values less than ('2021-02-01:00') engine=innodb
);
ALTER TABLE partition_employees ALGORITHM = INPLACE, LOCK = SHARED, -- 제일 앞에 파티션 추가하기 가능
    REORGANIZE PARTITION p0 INTO (
        PARTITION p1989 VALUES LESS THAN (1989),
        PARTITION p0 VALUES LESS THAN (1991)
);
ALTER TABLE partition_employees DROP PARTITION p2; -- 중간의 파티션이 삭제가 된다.
SELECT table_schema, table_name, partition_name, table_rows
from information_schema.PARTITIONS
where TABLE_NAME='partition_employees';
SELECT SUM(table_rows) from information_schema.partitions WHERE table_name='partition_employees';

##### 13.3.1.3.3 - 기본 파티션의 분리
-- 하나의 파티션을 두 개 이상의 파티션으로 분리하고자 할 때는 REORGANIZE PARTITION 명령을 사용하면 된다.
-- 위에서 REORGANIZE PARTITION 했던 부분으로 파티션을 분리하는 작업 생각해보면 된다.
-- 8.0 부터 partition 분리 하는 부분이 Online DDL 로 사용할 수 있다. 알고리즘과 락을 적용하자.

##### 13.3.1.3.4. - 기존 파티션 병합
-- 여러 파티션을 하나의 파티션으로 병합하는 작업도 REORGANIZE PARTITION 명령으로 사용하면 된다.
-- p2 와 p3 을 p23 으로 병합
ALTER TABLE partition_employees ALGORITHM = INPLACE, LOCK = SHARED,
    REORGANIZE PARTITION p2, p3 INTO (
        PARTITION  p23 VALUES LESS THAN (2011)
);

### 13.3.2 - 리스트 파티션
-- 리스트 파티션은 레인지 파티션과 많은 부분에서 흡사하게 동작한다.
-- 둘의 가장 큰 차이는 레인지 파티션은 파티션 키 값의 범위로 파티션을 구성할 수 있지만 리스트 파티션은 키 값 하나하나를 리스트로 나열해야 한다는 점이다.

#### 13.3.2.1 - 리스트 파티션의 용도
-- 테이블이 다음과 같은 특성을 지닐 때는 리스트 파티션을 사용하는 것이 좋다.
/*
    파티션 키 값이 코드 값이나 카테고리와 같이 고정적일 때
    키 값이 연속되지 않고 정렬 순서와 관계없이 파티션을 해야 할 때
    파티션 키 값을 기준으로 레코드의 건수가 균일하고 검색 조건에 파티션 키가 자주 사용될 때 (모든 파티션 공통인데, 레인지 또는 리스트에서 더 효과적이다)
*/

#### 13.3.2.2 - 리스트 파티션 테이블 생성
CREATE TABLE product_partition_key_int (
    id      INT NOT NULL,
    name    VARCHAR(30),
    category_id INT NOT NULL
    -- ...
) PARTITION BY LIST (category_id) (
    PARTITION p_appliance VALUES IN (3),
    PARTITION p_computer VALUES IN (1, 9),
    PARTITION p_sports VALUES IN (2, 6, 7),
    PARTITION p_etc VALUES IN (4, 5, 8, NULL)
);

-- 위 예제와 같이 정수 타입의 파티션 키 뿐만 아니라 다음과 같이 문자열 타입도 가능하다.
CREATE TABLE product_partition_key_str (
    id      INT NOT NULL,
    name    VARCHAR(30),
    category_id VARCHAR(20) NOT NULL
    -- ...
) PARTITION BY LIST (category_id) (
    PARTITION p_appliance VALUES IN ('TV'),
    PARTITION p_computer VALUES IN ('Notebook', 'Desktop'),
    PARTITION p_sports VALUES IN ('Tennis', 'Soccer'),
    PARTITION p_etc VALUES IN ('Magazine', 'Socks', NULL)
);

#### 13.3.2.3 - 리스트 파티션의 분리와 병합
-- 파티션을 정의하는 부분에서 VALUES LESS THAN 이 아닌 VALUES IN을 사용한다.
-- 파티션을 분리하거나 병합하려면 레인지와 똑같이 REORGANIZE PARTITION 명령을 사용하면 된다.

#### 13.3.2.4 - 리스트 파티션 주의사항
/*
    - 명시되지 않은 나머지 값을 저장하는 MAXVALUE 파티션을 정의할 수 없다.
    - 레인지 파티션과는 달리 NULL 을 저장하는 파티션을 별도로 생성할 수 있다.
*/

### 13.3.3 - 해시 파티션
-- 해시 파티션은 MySQL 에서 정의한 해시 함수에 의해 레코드가 저장될 파티션을 결정하는 방법이다.
-- 해시 함수는 복잡한 알고리즘이 아니라 파티션 표현식의 결괏값을 파티션의 개수로 나눈 나머지로 저장될 파티션을 결정하는 방식이다.
-- 해시 파티션의 파티션 키는 항상 정수 타입의 컬럼이거나 정수를 반환하는 표현식만 사용될 수 있다.
-- 해시 파티션에서 파티션의 개수는 레코드를 각 파티션에 할당하는 아록리즘과 연관되기 때문에
    -- 파티션을 추가하거나 삭제하는 작어벵는 테이블 전체적으로 레코드를 재분하는 작업이 따른다.
    -- 즉, 파티션을 추가, 삭제할 때 비용이 많이 든다.

#### 13.3.3.1 - 해시 파티션의 용도
-- 해시 파티션은 다음과 같은 특성을 지닌 테이블에 적합하다.
/*
    - 레인지 파티션이나 리스트 파티션으로 데이터를 균등하게 나누는 것이 어려울 때
    - 테이블의 모든 레코드가 비슷한 사용 빈도를 보이지만 테이블이 너무 커서 파티션을 적용해야 할 때

    해시 파티션이나 키 파티션의 대표적인 용도로는 회원 테이블을 들 수 있다.
    회원 정보는 가입 일자가 오래돼서 사용되지 않거나 최신이어서 더 빈번하게 사용되거나 하지 않는다.
    또한, 회원의 지역이나 취미 같은 정보 또한 사용 빈도에 미치는 영향이 거의 없다.
    테이블의 데이터가 특정 컬럼의 값에 영향을 받지 않고, 전체적으로 비슷한 사용 빈도를 보일 때 적합한 파티션 방법이다.
*/

#### 13.3.3.2 - 해시 파티션 테이블 생성
-- employees 테이블을 기준으로 해시 파티션 테이블을 생성하자.
DROP TABLE IF EXISTS hash_partition_employees;
CREATE TABLE hash_partition_employees (
    `emp_no` int NOT NULL,
  `birth_date` date NOT NULL,
  `first_name` varchar(14) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `last_name` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `gender` enum('M','F') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `hire_date` date NOT NULL,
  KEY `ix_hiredate` (`hire_date`),
  KEY `ix_gender_birthdate` (`gender`,`birth_date`),
  KEY `ix_firstname` (`first_name`,`last_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci STATS_PERSISTENT=0
PARTITION BY HASH ( emp_no )
    PARTITIONS 4; -- PARTITION 별로 이름을 지정하고 싶으면 여기 위치에서 'PARTITION 지정할_이름 ENGINE=INNODB' 이런식으로 지정하면 된다.
insert into hash_partition_employees (SELECT * FROM employees);
SELECT count(*) FROM hash_partition_employees;
SELECT table_name, table_rows, partition_name
FROM information_schema.partitions
WHERE table_name = 'hash_partition_employees';

#### 13.3.3.3 - 해시 파티션의 분리와 병합
-- 해시 파티션의 분리와 병합은 리스트나 레인지 파티션과는 달리 대상 테이블의 모든 파티션에 저장된 레코드를 재분배하는 작업이 필요하다.
-- 파티션의 분리나 병합으로 인해 파티션의 개수가 변경된다는 것은 해시 함수 알고리즘을 변경하는 것이므로 전체 파티션의 영향을 받는 것을 피할 수 없다.

##### 13.3.3.3.1 - 해시 파티션 추가
-- 해시 파티션은 특정 파티션 키 값을 테이블의 파티션 개수로 MOD 연산한 결괏값에 의해 각 레코드가 저장될 파티션을 결정한다.
-- 즉, 해시 파티션은 테이블에 존재하는 파티션의 개수에 의해 파티션 알고리즘이 변하는 것이다.
-- 따라서 새로운 파티션이 추가된다면 기존의 각 파티션에 저장된 모든 레코드가 재배치돼야 한다.
-- 해시 파티션을 추가할 때는 별도의 영역이나 범위는 명시하지 않고 몇 개의 파티션을 더 추가할 것인지만 지정하면 된다.

-- 파티션 1개만 추가하면서 파티션 이름을 부여하는 경우
ALTER TABLE hash_partition_employees ALGORITHM = INPLACE, LOCK = SHARED,
    ADD PARTITION (PARTITION p5 ENGINE = INNODB);

-- 동시에 파티션 6개를 별도의 이름 없이 추가하는 경우
ALTER TABLE hash_partition_employees ALGORITHM = INPLACE, LOCK = SHARED,
    ADD PARTITION PARTITIONS 6;
SELECT table_schema, table_name, partition_name, table_rows
FROM information_schema.partitions
WHERE table_name = 'hash_partition_employees';

##### 13.3.3.3.2 - 해시 파ㅣㅌ션 삭제
-- 해시나 키 파티션은 파티션 단위로 레코드를 삭제하는 방법이 없다. 특정 파티션을 삭제하려고 하면 에러가 발생한다.
-- DROP PARTITION can only be used on RANGE/LIST partitions 에러 발생
-- 지정한 파티션 키 값을 가공해서 데이터를 각 파티션으로 분산한 것이므로 각 파티션에 저장된 레코드가 어떤 부류의 데이터인지 사용자가 예측할 수 없다.
-- 결국 해시, 키 파티션을 사용한 테이블에서 파티션 단위로 데이터를 삭제하는 작업은 의미도 없으며 해서도 안 될 작업이다.
# ALTER TABLE hash_partition_employees DROP PARTITION p0; -- 에러 발생

##### 13.3.3.3.3 - 해시 파티션 분할
-- 해시, 키 파티션에서 특정 파티션을 두 개 이상의 파티션으로 분할하는 기능은 없으며, 테이블 전체적으로 파티션의 개수를 늘리는 것만 가능하다.

##### 13.3.3.3.4 - 해시 파티션 병합
-- 2개 이상의 파티션을 하나의 파티션으로 통합하는 기능을 제공하지 않는다.
-- 단지 파티션의 개수를 줄이는 것만 가능. 파티션의 개수를 주일 때는 COALESCE PARTITION 명령을 사용하면 된다.
-- COALESCE PARTITION 뒤에 명시한 숫자 값은 줄이고자 하는 파티션의 개수를 의미한다.

-- 원래 10개로 구성된 테이블에서 다음 명령을 실행하면 9개의 파티션을 가진 테이블로 다시 재구성한다.
ALTER TABLE hash_partition_employees ALGORITHM = INPLACE, LOCK = SHARED,
    COALESCE PARTITION 1;
SELECT table_schema, table_name, partition_name, table_rows
FROM information_schema.partitions
WHERE table_name = 'hash_partition_employees';

SELECT * FROM hash_partition_employees PARTITION (p0);
SELECT * FROM hash_partition_employees PARTITION (p1);
SELECT * FROM hash_partition_employees PARTITION (p2);
SELECT * FROM hash_partition_employees PARTITION (p3);
SELECT * FROM hash_partition_employees PARTITION (p4);
SELECT * FROM hash_partition_employees PARTITION (p5);
SELECT * FROM hash_partition_employees PARTITION (p6);
SELECT * FROM hash_partition_employees ORDER BY emp_no LIKE 10;

##### 13.3.3.3.5 - 해시 파티션 주의사항
-- 특정 파티션만 삭제(DROP PARTITION)하는 것은 불가능하다.
-- 새로운 파티션을 추가한느 작업은 단순히 파티션만 추가하는 것이 아니라 기존 모든 데이터의 재배치 작업이 필요
-- 해시 파티션은 레인지나 리스트 파티션과는 다른 방식으로 관리하기 때문에 해시 파티션이 용도에 적합한 해결책인지 확인이 필요
-- 일반적으로 사용자들에게 익숙한 파티션의 조작이나 특성은 대부분 리스트, 레인지 파티션에만 해당하는 것들이 많다.
    -- 해시, 키 파티션을 사용하거나 조작할 때는 주의가 필요

### 13.3.4 - 키 파티션
-- 대부분의 사용법과 특성이 해시 파티션과 유사하다.
-- 차이점으론 키 파티션에서 정수 ㅏ입이나 정숫값을 반환하는 표현식 뿐만 아니라 대부분의 데이터 타입에 대해 파티션 키를 적용할 수 있다.
    -- MySQL 서버는 파티션 키의 값을 MD5() 함수를 이용해 해시 값을 계산하고, 그 값을 MOD 연산을 통해 데이터를 각 파티션에 분배한다.
-- 위 같은 차이점 말곤 해시 파티션과 차이점이 없다.

#### 13.3.4.1 - 키 파티션의 생성
-- PK 가 있는 경우 자동으로 PK 가 파티션 키로 사용된다.
CREATE TABLE k1 (
    id      INT NOT NULL,
    name    VARCHAR(20),
    PRIMARY KEY (id)
) PARTITION BY KEY () -- PK 가 파티션 키로 사용된다.
    PARTITIONS 2;

-- PK 가 없는 경우 유니크 키(존재한다면)가 파티션 키로 사용된다.
CREATE TABLE k1 (
    id      INT NOT NULL,
    name    VARCHAR(20),
    UNIQUE KEY (id)
    -- 아래 괄호의 내용을 비워 두면 자동으로 PK 의 모든 컬럼이 파티션 키가 된다.
    -- 그렇지 않고 PK 의 일부만 명시할 수도 있다.
) PARTITION BY KEY ()
    PARTITIONS 2;

-- PK 나 유니크 키의 컬럼 일부를 파티션 키로 명시적으로 설정
CREATE TABLE k1 (
    id      INT NOT NULL,
    dept_no INT NOT NULL,
    name    VARCHAR(20),
    PRIMARY KEY (id)
    -- 아래 괄호의 내용을 비워 두면 자동으로 PK 의 모든 컬럼이 파티션 키가 된다.
    -- 그렇지 않고 PK 의 일부만 명시할 수도 있다.
) PARTITION BY KEY (dept_no)
    PARTITIONS 2;

-- PK 나 유니크 키 모두 없는 테이블일 경우엔 어떻게 될까? 에러가 발생한다. Field in list of fields for partition function not found in table
CREATE TABLE k1 (
    id      INT NOT NULL,
    name    VARCHAR(20)
) PARTITION BY KEY ()
    PARTITIONS 2;

#### 13.3.4.2 - 키 파티션의 주의사항 및 특이사항
-- 키 파티션은 MySQL 서버가 내부적으로 MD5() 함수를 이용해 파티션하기 때문에 파티션 키가 바드시 정수 타입이 아니어도 된다.
    -- 따라서, 해시 파티션으로 파티션이 어렵다면 키 파티션을 적용해보자.
-- 프라이머리 키나 유니크 키를 구성하는 컬럼 중 일부로도 파티션 할 수 있다.
-- 유니크 키를 파티션 키로 사용할 때 해당 유니크 키는 반드시 NOT NULL 이어야 한다.
-- 해시 파티션에 비해 파티션 간의 레코드를 더 균등하게 분할할 수 있기 때문에 키 파티션이 더 효율적이다.

### 13.3.5 - 리니어 해시 파티션 / 리니어 키 파티션
/*
    해시, 키 파티션은 새로운 파티션을 추가하거나 통합할 때 전체 파티션에 저장된 레코드의 재분배 작업이 발생한다.
    이러한 단점을 최소화하기 위해 리니어(Linear) 해시 파티션/ 리니어 키 파티션 알고리즘이 고안됐다.

    리니어 해시, 키 파티션은 각 레코드 분배를 위해 Power-of-two(2의 승수) 알고리즘을 이용하며,
    이 알고리즘은 파티션의 추가나 통합 시 다른 파티션에 미치는 영향을 최소화해준다.
*/
CREATE TABLE linear_hash_employees (
    id INT NOT NULL,
    fname VARCHAR(30),
    lname VARCHAR(30),
    hired DATE NOT NULL DEFAULT '1970-01-01',
    separated DATE NOT NULL DEFAULT '9999-12-31',
    job_code INT,
    store_id INT
) PARTITION BY LINEAR HASH( YEAR(hired) )
    PARTITIONS 4;

#### 13.3.5.1~2 - 리니어 해시/키 파티션 추가 및 통합
-- 리니어 해시/키 파티션의 경우 Power-Of-Two 분배 방식을 사용하기 때문에 특정 파티션의 데이터에 대해서만 이동 작업을 하면 된다.
ALTER TABLE linear_hash_employees ALGORITHM = INPLACE, LOCK = SHARED, -- Linear 해시 파티션에서 파티션 추가하기
    ADD PARTITION (PARTITION p5 ENGINE = INNODB);
ALTER TABLE linear_hash_employees ALGORITHM = INPLACE, LOCK = SHARED, -- Linear 해시 파티션에서 파티션 통합하기
    COALESCE PARTITION 1;
SELECT * FROM information_schema.partitions WHERE table_name='linear_hash_employees';

##### 13.3.5.1.3 - 리니어 해시/키 파티션과 관련된 주의사항
-- 리니어 파티션은 각 파티션이 가지는 레코드의 건수는 일반 해시/키 파티션보다 덜 균등해질 수 있다.
-- 일반 해시/키 파티션을 사용하는 테이블에 대해 새로운 파티션을 추가 또는 삭제 해야 할 요건이 많다면 리니어 해시/키 파티션을 적용하는 것이 좋다.

### 13.3.6 - 파티션 테이블의 쿼리 성능
-- 파티션 테이블에서 쿼리의 성능은 얼마나 많은 파티션을 프루닝할 수 있는지가 관건이다.
-- 옵티마이저가 수립하는 실행 계획에서 어떤 파티션이 제외되고 어떤 파티션만을 접근하는지는 쿼리의 실행 계획으로 확인할 수 있다.
/*
    만약, 1024개의 파티션으로 구성된 회원 테이블이 있다고 가정해보자, 해당 테이블에서 user_name 이 'toto' 인 사람을 찾는다고 해보자.
    그럼 user_name 컬럼의 값이 'toto' 인 레코드를 찾는 작업을 1024번 해야 한다.
    물론 파티션된 개별 인덱스의 크기가 작다면 크게 부담되지 않을 수 있지만,
    테이블이 작아서 부담되지 않는다면 파티션 없이 하나의 테이블로 구성하는게 더 좋을 수도 있다.
*/
/*
    테이블을 10개로 파티션해서 10개의 파티션 중 주로 1 ~ 3 개 정도의 파티션만 읽고 쓴다면 파티션 기능이 성능 향상에 도움이 된다.
    그런데 10개로 파티션하고 파티션된 10개를 아주 균등하게 사용한다면 이는 성능 향상보다 오버헤드만 심해지는 결과를 가져올 수 있다.
    대용량 테이블을 10개로 쪼개서 서로 다른 MySQL 서버에 저장(샤딩)한다면 매우 효율적일 것이다.
    하지만, MySQL 서버의 파티션은 샤딩이 아니라는 것에 주의하자.

    파티션을 사용할 때는 반드시 파티션 프루닝이 얼마나 도움이 될지를 먼저 예측해보고 응용 프로그램에 적용하자.
    레인지 파티션 이외의 파티션을 적용할 때는 파티션 프루닝을 더 많이 고민해보고 적용할 것을 권장한다.
*/

