# 11.5.3 - 성능을 위한 테이블 구조
-- INSERT 문장의 성능은 쿼리 문장 자체보다는 테이블의 구조에 의해 많이 결정된다.
-- 대부분의 INSERT 문장은 단일 레코드를 저장하는 형태로 사용되기 때문에 INSERT 문장의 튜닝을 할 수 있는 부분이 별로 없다.

## 11.5.3.1 - 대량 INSERT 성능
/* 하나의 INSERT 문장으로 수백 건, 수천 건의 레코드를 INSERT 한다면
   INSERT 될 레코드들의 PK 값을 기준으로 미리 정렬해서 INSERT 문장을 구성하는 것이 성능에 도움이 된다.
*/

## 11.5.3.2 - 프라이머리 키 선정
-- 로그 테이블인 경우 SELECT 는 거의 실행되지 않고 INSERT 작업이 많으므로 단조 증가, 단조 감소를 PK로 잡아도 된다.
/* 상품이나 주문, 사용자 정보 같은 중요 테이블은 INSERT 보다
   SELECT 쿼리가 더 많이 발생하므로 SELECT 쿼리를 더 빠르게 만드는 방향으로 PK를 설정해야 한다.
*/
-- SELECT 가 많지 않고 INSERT 가 많을 경우 인덱스의 개수를 최소화하는 것이 좋다.

## 11.5.3.3 - Auto-Increment 컬럼
-- innodb_autoinc_lock_mode 의 설정으로 AUTO-INC 잠금을 사용하는 방식에 대해 설정할 수 있다.
/*
  0은 5.1 버전의 자동 증가 방식인데 서비스용 MySQL 서버에서는 이 방식을 사용팔 필요가 없다.
  1은 5.7 버전까지의 기본 값이였고, 부르는 이름은 Consecutive mode(연속 모드) 이다.
    - 1의 동작 방식은 레코드 한 건씩 INSERT 하는 거에 대해선 AUTO-INC 잠금을 사용하지 않고 뮤텍스를 이용한다.
    - INSERT 문장으로 여러 레코드를 INSERT 하거나 LOAD DATA 명령으로 INSERT 하는 쿼리에선 잠금을 걸고
      필요한 만큼의 자동 증가 값을 한꺼번에 가져와서 사용한다.
  8.0 버전부터 기본 값은 2로 변경됐다. -> 복제의 바이너리 로그 포맷 기본 값이 STATMENT 에서 ROW 로 변경됐기 때문
    - 부르는 용어는 Interleaved mode 이다. (인터리브는 성능을 높이기 위해 데이터가 서로 인접하지 않도록 배열하는 방법)
    - 2의 동작 방식은 LOAD DATA나 벌크 INSERT를 포함한 INSERT 계열의 문장에서 AUTO-INC 잠금을 사용하지 않는다.
    - 자동 증가 값을 미리 할당받아서 처리하는 방식으로 동작하고 이게 가장 빠른 방식이다.
    - 이 모드에서 채번된 번호는 단조 증가하는 유니크한 번호까지만 보장하며, INSERT 순서와 채번된 번호의 연속성은 보장되지 않는다.
*/

CREATE TABLE auto_increment_last_insert_id_test(
    id INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    name VARCHAR(10) NOT NULL
);
INSERT INTO auto_increment_last_insert_id_test VALUES (NULL, 'Bob');
SELECT * FROM auto_increment_last_insert_id_test;
SELECT LAST_INSERT_ID(); -- 1
INSERT INTO auto_increment_last_insert_id_test VALUES
       (NULL, 'Mary'), (NULL, 'Jane'), (NULL, 'Lisa');
SELECT * FROM auto_increment_last_insert_id_test;
SELECT LAST_INSERT_ID(); -- 2


