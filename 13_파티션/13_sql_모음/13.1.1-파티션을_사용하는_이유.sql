# 13 - 파티션
-- 파티셔닝이란 논리적으로는 하나의 테이블이지만 물리적으로 여러 개의 테이블로 분리해서 관리할 수 있게 해주는 기능
-- 파티션은 주로 대용량의 테이블을 물리적으로 여러 개의 소규모 테이블로 분산하는 목적으로 사용한다.
-- 하지만 파티션은 무조건 성능이 빨라지는 만병 통치약이 아니다. 자주 사용하는 파티션 방법과 사용시 주의 사항을 살펴보자.

### 11.3.1.1 - 파티션을 사용하는 이유
/*
    테이블의 데이터가 많아진다고 해서 무조건 파티션을 적용하는 것이 효율적인 것은 아니다.
      - 하나의 테이블이 너무 커서 인덱스의 크키가 물리적인 메모리보다 훨씬 크거나,
      - 데이터 특성상 주기적인 삭제 작업이 필요한 경우 등과 같은 상황이 파티션이 필요한 예이다.
*/

#### 11.3.1.1.1 - 단일 INSERT와 단일 또는 범위 SELECT의 빠른 처리
/*
    인덱스는 일반적으로 SELECT 를 위한 것으로 보이지만 UPDATE 나 DELETE 처리를 위해 대상 레코드를 검색하려면 인덱스가 필수적이다.
    인덱스가 커지면 커질수록, R 작업은 말할 것도 없고 CUD 작업도 함께 느려지게 된다.
    특히, 한 테이블의 인덱스 크기가 물리적으로 MySQL이 사용 가능한 메모리 공간보다 크다면 그 영향은 더 심각할 것이다.
        테이블 데이터는 물리 메모리보다 큰 것이 일반적이겠지만, 인덱스의 워킹 셋(Working Set)이 물리 메모리보다 크다면 쿼리 처리가 느려진다.
    결과적으로 파티션은 데이터와 인덱스를 조각화해서 물리적 메모리를 효율적으로 사용할 수 있게 만들어 준다.
*/
/*
    워킹 셋(Working Set) 이란
    테이블의 데이터가 10GB이고 인덱스가 3GB라고 가정하면, 테이블은 13GB 전체를 사용하는 것이 아니라 그중 일정 부분만 사용한다.
    즉, 게시물이 100만 건이 저장된 테이블이라고 하더라도 최신 20 - 30 % 의 게시물만 활발하게 조회될 것이다.
    이렇게 활발하게 사용되는 데이터를 워킹 셋이라고 표현한다.
    테이블의 데이터를 활발하게 사용되는 워킹 셋과 그렇지 않은 부분으로 나눠서 파티션할 수 있다면 상당히 효과적으로 성능을 개선할 수 있다.
*/

#### 13.1.1.2 - 데이터의 물리적인 저장소를 분리
/*
    데이터 파일이나 인덱스 파일이 파일 시스템에서 차지하는 공간이 크다면 백업이나 관리 작업이 어려워진다.
    더욱이 테이블의 데이터나 인덱스를 파일 단위로 관리하는 MySQL 에서는 더 치명적인 문제가 된다.
    이러한 문제를 파티션을 통해 파일의 크기를 조절하거나 파티션별 파일들이 저장될 위치나 디스크를 구분해서 지정해 해결하는 것도 가능.

    하지만, MySQL 에서는 테이블의 파티션 단위로 인덱스를 생성하거나 파티션별로 다른 인덱스를 가지는 형태는 지원하지 않는다.
*/

#### 13.1.1.3 - 이력 데이터의 효율적인 관리
/*
    로드 데이터는 결국 시간이 지나면 별도로 아카이빙하거나 백업한 후 삭제해버리는 것이 일반적이며, 특히
    다른 데이터에 비해 라이프 사이클이 상당히 짧은 것이 특징이다.
    따라서, 로그 테이블을 파티션 테이블로 관리한다면 불필요한 데이터 삭제 작업은 파티션을 추가, 삭제하는 방식으로 간단하고 빠르게 해결할 수 있다.
*/

## 13.1.2 - MySQL 파티션의 내부 처리
-- 파티션이 적용된 테이블에서 레코드의 INSERT, UPDATE, SELECT 가 어떻게 처리되는지 테스트
-- 게시물의 등록 일자(reg_date)에서 연도 부분은 파티션 키로서 해당 레코드가 어느 파티션에 저장될지를 결정하는 역할을 한다.
CREATE TABLE tb_article (
    article_id      INT NOT NULL,
    reg_date        DATETIME NOT NULL,
    reg_userid      VARCHAR(10),
    PRIMARY KEY (article_id, reg_Date)
) PARTITION BY RANGE ( YEAR(reg_date) ) (
    PARTITION p2009 VALUES LESS THAN (2010),
    PARTITION p2010 VALUES LESS THAN (2011),
    PARTITION p2011 VALUES LESS THAN (2012),
    PARTITION p9999 VALUES LESS THAN MAXVALUE
);

ALTER TABLE tb_article add index ix_reguserid (reg_userid, reg_date);
desc tb_article;

### 13.1.2.1 - 파티션 테이블의 레코드 INSERT
-- INSERT 쿼리가 실행되면 MySQL 서버는 INSERT 되는 컬럼의 값 중에서 파티션 키인 reg_date 컬럼의 값을 이용해 파티션 표션식을 평가하고,
-- 그 결과를 이용해 레코드가 저장될 적절한 파티션을 결정한다.
-- 새로 INSERT 되는 레코드를 위한 파티션이 결정되면 나머지 과정은 파티션되지 않은 일반 테이블과 동일하게 처리된다.
INSERT INTO tb_article VALUES (1835, '2011-03-09', 'brew'), (1001, '2009-01-10', 'brew'),
                              (1002, '2009-04-12', 'matt'), (1003, '2099-05-21', 'toto'),
                              (1202, '2010-02-09', 'brew'), (1203, '2010-02-10', 'matt'),
                              (1209, '2010-08-30', 'toto'), (1821, '2011-01-09', 'brew'),
                              (1833, '2011-01-18', 'matt'), (1834, '2011-02-08', 'toto');

### 13.1.2.2 - 파티션 테이블의 UPDATE
-- UPDATE 쿼리를 실행하려면 변경 대상 레코드가 어느 파티션에 저장돼 있는지 찾아야 한다.
-- 이때 WHERE 조건에 파티션 키 컬럼이 조건으로 존재한다면 그 값을 이용해 레코드가 저장된 파티션에서 빠르게 대상 레코드를 검색할 수 있다.
-- 하지만, 파티션 키 컬럼이 조건에 명시되지 않았다면 대상 레코드를 찾기 위해 테이블의 모든 파티션을 검색해야 한다.
/*
    UPDATE 쿼리가 어떤 컬럼의 값을 변경하느냐에 따라 발생하는 차이

    파티션 키 이외의 컬러만 변경할 경우 : 일반 테이블과 마찬가지로 컬럼 값만 변경된다.
    파티션 키 컬럼이 변경할 경우 :
        기존의 레코드가 저장된 파티션에서 해당 레코드를 삭제한다.
        변경되는 파티션 키 컬럼의 표현식을 평가한다.
        그 결과를 이용해 새로운 파티션을 결정해서 레코드를 새로 저장한다.
*/

### 13.1.2.3 - 파티션 테이블의 검색
-- 파티션 테이블을 검색할 때 성능에 영향을 미치는 두 가지 조건
/*
    1. WHERE 절의 조건으로 검색해야 할 파티션을 선택할 수 있는가?
    2. WHERE 절의 조건이 인덱스를 효율적으로 사용(레인지 스캔)할 수 있는가?

    두 번째 내용은 파티션되지 않은 일반 테이블의 검색 성능에도 똑같이 영향을 미친다.
    하지만, 파티션 테이블에서는 첫 번째 선택사항의 결과에 의해 두 번째 선택사항의 작업 내용이 달라질 수 있다.

    - 파티션 선택 가능 + 인덱스 효율적 사용 가능 : 이때는 파티션의 개수와 관계없이 검색을 위해 꼭 필요한 파티션의 인덱스만 레인지 스캔한다.
    - 파티션 선택 불가 + 인덱스 효율정 사용 가능 :
        WHERE 조건에 일치하는 레코드가 저장된 파티션을 걸러낼 수 없기 때문에 우선 테이블의 모든 파티션을 대상으로 검색해야 한다.
        하지만, 각 파티션에 대해서는 인덱스 레인지 스캔을 사용할 수 있기 때문에 최종적으로 테이블에 존재하는 모든 파티션의 개수만큼
        인덱스 레인지 스캔을 수행해서 검색하게 된다. 이 작업은 파티션의 개수만큼 테이블에 대해 인덱스 레인지 스캐늘 한 다음,
        결과를 병합해서 가져오는 것과 같다.
    - 파티션 선택 가능 + 인덱스 효율적 사용 불가 : 파티션 개수와 관계없이 검색을 위한 파티션만 읽으면 되는데, 테이블 풀 스캔을 해야 된다.
        각 파티션의 레코드 건수가 많다면 느리게 처리된다.
    - 파티션 선택 불가 + 인덱스 효율적 사용 불가 : 모든 파티션 검색 + 각 파티션마다 테이블 풀 스캔이 발생한다. 성능상 제일 안 좋다.

    3, 4 번째는 최대한 피하는 것이 좋다. 두 번째 조합도 하나의 테이블에 ㅎ파티션의 개수가 많을 때는 부하가 높아지고 처리 시간도 느려진다.
*/

### 13.1.2.4 - 파티션 테이블의 인덱스 스캔과 정렬
-- MySQL 의 파티션 테이블에서 인덱스는 전부 로컬 인덱스에 해당한다. 즉, 모든 인덱스는 파티션 단위로 생성되며,
-- 파티션과 관계없이 테이블 전체 단위로 글로벌하게 하나의 통합된 인덱스는 지원하지 않는다는 것을 의미한다.
-- 개별 파티션에 속한 인덱스가 모든 파티션에 대해서 공통적으로 생성된다는 의미, 개별 파티션 단위로 다른 인덱스를 생성할 수 있다는 뜻이 아니다.
-- 파티션에서 이러한 인덱스를 글로벌 인덱스라고 하며, 개별 파티션에 속한 인덱스를 로컬 인덱스라고 한다.
-- 파티션되지 않은 테이블에서는 인덱스를 순서대로 읽으면 그 커럼으로 정렬된 결과를 바로 얻을 수 있지만, 파티션된 테이블에서는 그렇지 않다.

EXPLAIN SELECT * FROM tb_article
WHERE reg_userid BETWEEN 'brew' AND 'toto'
  AND reg_date BETWEEN '2009-01-01' AND '2010-12-31'
ORDER BY reg_userid;

### 13.1.2.5 - 파티션 프루닝
-- EXPLAIN 쿼리에서 partitions 컬럼을 통해 어떤 파티션만 읽었는지 확인할 수 있다.
-- 이때 쓸모없는 파티션을 읽지 않는 작업을 '파티션 프루닝(Partition pruning)' 이라고 부른다.
-- 아래 쿼리를 확인해 보면 p2010 이라는 파티션만 읽는다. 나머지 파티션들은 프루닝 된 것이다.
EXPLAIN SELECT * FROM tb_article WHERE reg_date > '2010-01-01' and reg_date < '2010-02-01';
