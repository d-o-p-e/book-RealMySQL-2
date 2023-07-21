# 11.5.1 - INSERT IGNORE
-- INSERT 문장의 IGNORE 옵션은 저장하는 레코드의 프라이머리 키나 유니크 인덱스 컬럼의 값이
-- 이미 테이블에 존재하는 레코드와 중복되는 경우 그리고 저장하는 레코드의 컬럼이 테이블의 컬럼과 호환되지 않는 경우
-- 모두 무시하고 다음 레코드를 처리할 수 있게 해준다.
-- 주로 INGORE 옵션은 여러 레코드를 하나의 INSERT 문장으로 처리하는 경우 유용하다.
-- 다음과 같이 사용하면 된다.
INSERT IGNORE INTO salaries (emp_no, salary, from_date, to_date) VALUES
  (10001, 60117, '1986-06-26', '1987-06-26'),
  (10001, 62102, '1987-06-26', '1988-06-25'),
  (10001, 66074, '1986-06-25', '1989-06-25'),
  (10001, 66596, '1989-06-25', '1987-06-25'),
  (10001, 66961, '1990-06-25', '1987-06-25');
-- salaries 테이블의 PK 는 (emp_no, from_date)로 이루어져 있다.
-- 위에서 INSERT 되는 값이 이미 테이블에 존재하면 무시하고 다음행을 실행한다. (원래는 에러 발생 후 쿼리 종료)
DESC salaries;
SHOW INDEX FROM salaries;

-- IGNORE 키워드가 없으면 INSERT는 실패
INSERT IGNORE INTO salaries
  SELECT emp_no, (salary + 100), '2020-01-01', '2022-01-01'
  FROM salaries WHERE to_date >= '2020-01-01';
-- IGNORE 키워드가 있으면, NOT NULL 컬럼인 emp_no와 fro_date에 각 타입별 기본 값을 저장 (NULL 이니까 0을 저장)
INSERT INTO salaries VALUES (NULL, NULL, NULL, NULL);
INSERT IGNORE INTO salaries VALUES (NULL, NULL, NULL, NULL);
SELECT * FROM salaries WHERE emp_no=0;

-- IGNORE 테스트 VARCHAR 와 같은 문자열 컬럼이면 기본 값이 뭐일지 궁금해서 해봤는데 빈 문자열이 된다.
CREATE TABLE insert_ignore_test_db (
    word_1      VARCHAR(5) NOT NULL,
    word_2      CHAR(5) NOT NULL,
    num_1       INT NOT NULL
);
INSERT IGNORE INTO insert_ignore_test_db VALUES (NULL, NULL, NULL);
SELECT * FROM insert_ignore_test_db WHERE word_1='';

### 11.5.1.2 - INSERT ... ON DUPLICATE KEY UPDATE
-- REPLACE 함수는 내부적으로 DELETE 와 INSERT 로 이루어져 있다. 성능상 안 좋다.
-- 따라서, INSERT ... ON DUPLICATE KEY UPDATE 를 사용하자.
CREATE TABLE daily_statistic (
    target_date DATE NOT NULL,
    stat_name VARCHAR(10) NOT NULL,
    stat_value BIGINT NOT NULL DEFAULT 0,
    PRIMARY KEY (target_date, stat_name)
);
-- daily_statistic 테이블의 PK 는 (target_date, stat_name) 으로 구성되어 있어서 일별로 stat_name은 하나씩만 존재할 수 있다.
-- 특정 날짜의 stat_name이 최초로 저장되는 경우엔 INSERT 문장만 실행 (ON DUPLICATE 절은 무시)
-- 이미 레코드가 존재한다면 INSERT 대신 ON DUPLICATE 절 이하의 내용이 실행
INSERT INTO daily_statistic (target_date, stat_name, stat_value)
  VALUES (DATE(NOW()), 'VISIT', 1)
  ON DUPLICATE KEY UPDATE stat_value = stat_value + 1;

-- 배치 형태로 GROUP BY된 결과를 daily_statistic 테이블에 한 번에 INSERT 하는 예제
-- 아래 쿼리는 GROUP BY 의 결과인 COUNT(*)를 참조할 수 없다. 그래서 에러가 발생한다.(Invalid use of group function)
INSERT INTO daily_statistic
SELECT DATE(visited_at), 'VISIT', COUNT(*)
FROM access_log
GROUP BY DATE(visited_at)
ON DUPLICATE KEY UPDATE stat_value = daily_statistic.stat_value + COUNT(*);

-- 이러한 경우 VALUES() 함수를 사용하면 안 된다.(8.0.20 부터는 deprecated 된다고 경고 메시지가 나온다.)
-- 쿼리가 실행되긴 함
-- [HY000][1287] 'VALUES function' is deprecated and will be removed in a future release ...
INSERT INTO daily_statistic
    SELECT DATE(visited_at), 'VISIT', COUNT(*)
    FROM access_log
    GROUP BY DATE(visited_at)
    ON DUPLICATE KEY UPDATE stat_value = stat_value + VALUES(stat_value);

-- 8.0.20 이후 버전에서는 다음과 같이 문법을 대체해서 사용할 것을 권장한다.
-- 단, sql_mode 에서 ONLY_FULL_GROUP_BY 모드가 없어야 된다.
# SELECT @@sql_mode;
# SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
INSERT INTO daily_statistic
    SELECT target_date, stat_name, stat_value
    FROM (
        SELECT DATE(visited_at) target_date, 'VISIT', stat_name, COUNT(*) stat_value
        FROM access_log
        GROUP BY DATE(visited_at)
    ) stat
    ON DUPLICATE KEY UPDATE
        daily_statistic.stat_value = daily_statistic.stat_value + stat.stat_value;
SELECT * FROM daily_statistic;

-- INSERT ... SELECT ... 형태의 문법이 아닌 경우에는 다음과 같이
-- INSERT 되는 레코드에 대해 별칭을 부여해서 참조하는 문법을 사용하면 VALUES() 함수의 사용을 피할 수 있다.
INSERT INTO daily_statistic (target_Date, stat_name, stat_value)
    VALUES ('2020-09-01', 'VISIT', 1),
           ('2020-09-02', 'VISIT', 1)
        AS new /* "new"라는 이름으로 별칭을 부여했다. */
    ON DUPLICATE KEY UPDATE daily_statistic.stat_value = daily_statistic.stat_value + new.stat_value;
INSERT INTO daily_statistic
        /* "new"라는 이름으로 별칭을 부여 */
        SET target_date='2020-09-01', stat_name='VISIT', stat_value=1 AS new
    ON DUPLICATE KEY UPDATE
        daily_statistic.stat_value = daily_statistic.stat_value + new.stat_value;
INSERT INTO daily_statistic -- datagrip 에선 에러 나고, 터미널에선 정상 동작
        /* "new"라는 이름으로 별칭을 부여 */
        SET target_date = '2020-09-01', stat_name = 'VISIT', stat_value = 1 AS new(fd1, fd2, fd3)
    ON DUPLICATE KEY
        UPDATE daily_statistic.stat_value = daily_statistic.stat_value + new.fd3;

## 11.5.2 - LOAD DATE 명령 주의 사항
-- 일반적인 RDBMS 에서 데이터를 빠르게 적재할 수 있는 방법으로 LOAD DATE 명령이 자주 소개된다.
-- MySQL 서버도 LOAD DATE 명령은 MySQL 엔진과 스토리지 엔진의 호출 횟수를 최소화하고 스토리지 엔진이 직접 데이터를 적재하기 때문에
-- 일반적인 INSERT 명령과 비교했을 때 매우 빠르다. 하지만, 두 가지 단점이 있다.
# 단점 1. : 단일 스레드로 실행
# 단점 2. : 단일 트랜잭션으로 실행





