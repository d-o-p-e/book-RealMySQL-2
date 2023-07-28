# 13.2 - 주의 사항
-- MySQL 에서 파티션은 5.1 버전부터 도입되어 8.0 까지 많은 발전이 있었지만, 아직도 많은 제약을 지니고 있다.
-- 여기서 살펴볼 제약 사항들은 파티션의 태생적인 한계이기 때문에 MySQL 이 아무리 좋아진다고 해도 여전히 가질 제약사항 일 수도 있다.

## 13.2.1 - 파티션의 제약 사항
-- PARTITION BY RANGE 절은 이 테이블이 레인지 파티션을 사용한다는 것을 의미한다.
-- 그리고 파티컨 컬럼은 reg_date 이며, 파티션 표현식으로는 YEAR(reg_date) 가 사용됐다.
-- 즉, tb_article 테이블은 reg_date 컬럼에서 YEAR() 라는 MySQL 내장 함수를 이용해 연도만 추출하고, 연도별로 파티션하고 있다.
CREATE TABLE tb_article_1 (
    article_id      INT AUTO_INCREMENT NOT NULL,
    reg_date        DATETIME NOT NULL,
    reg_userid      VARCHAR(10),
    PRIMARY KEY (article_id)
) PARTITION BY RANGE ( YEAR(reg_date) ) (
    PARTITION p2009 VALUES LESS THAN (2010),
    PARTITION p2010 VALUES LESS THAN (2011),
    PARTITION p2011 VALUES LESS THAN (2012),
    PARTITION p9999 VALUES LESS THAN MAXVALUE
);

/*
    MySQL 서버의 파티션이 가지는 제약 사항

    - 스토어드 루틴이나 UDF(사용자 정의 함수?), 사용자 변수 등을 파티션 표현식에 사용할 수 없다.
    - 파티션 표현식은 일반적으로 컬럼 그 자체 또는 MySQL 내장 함수를 사용할 수 있는데,
        여기서 일부 함수들은 파티션 생성은 가능하지만 파티션 프루닝은 제공하지 않을 수도 있다.
    - 테이블의 모든 유니크 인덱스(PK 포함)는 파티션 키 컬럼을 포함해야 한다.
    - 파티션된 테이블의 인덱스는 모두 로컬 인덱스이며, 동일 테이블에 소속된 모든 파티션은 같은 구조의 인덱스만 가질 수 있다.
    - 동일 테이블에 속한 모든 파팃현은 동일 스토리지 엔진만 가질 수 있다.
    - 최대(서브 파티션까지 포함) 8192개의 파티션을 가질 수 있다.
    - 파티션 생성 이후 sql_mode 시스템 변수 변경은 데이터 파티션의 일관성을 깨트릴 수 있다.
    - 파티션 테이블에서 외래키를 사용할 수 없다.
    - 파티션 테이블은 전문 검색(full text) 인덱스 생성이나 전문 검색 쿼리를 사용할 수 없다.
    - 공간 데이터를 저장하는 컬럼타입(POINT, GEOMETRY, ...)은 파티션 테이블에서 사용할 수 없다.
    - 임시 테이블(Temporary table)은 파티션 기능을 사용할 수 없다. (CTE 에서도 안되는거 같다)
*/
-- 위에서 만든 tb_article 테이블을 보자. article_id 컬럼은 AUTO_INCREMENT 로 설정해서 유니크 인덱스로 적용 가능하다.
-- 근데, PK 를 지정할 때 reg_date 도 같이 pk로 지정했다. 그 이유는 reg_date 컬럼으로 파티션을 적용하기 위해서 그렇다.
-- reg_date 컬럼으로 파티션을 적용하려면 PK 를 저렇게 복합키로(article_id, reg_date) 잡아야 한다. 없으면 다음과 같이 에러난다.
-- A PRIMARY KEY must include all columns in the table's partitioning function (prefixed columns are not considered).

-- MONTH 함수 파티션 프루닝 지원 되는지 테스트
# surmmary - 파티션 프루닝 지원 안 된다.
DROP TABLE IF EXISTS partition_pruning_test;
CREATE TABLE partition_pruning_test (
    id      INT AUTO_INCREMENT,
    name    VARCHAR(10),
    age     INT,
    create_at   DATETIME,
    PRIMARY KEY (id, create_at)
) PARTITION BY RANGE ( MONTH(create_at) ) (
    PARTITION p1 VALUES LESS THAN (5),
    PARTITION p2 VALUES LESS THAN (7),
    PARTITION p3 VALUES LESS THAN (10),
    PARTITION p4 VALUES LESS THAN MAXVALUE
);
INSERT INTO partition_pruning_test VALUES (NULL, 'test', 1, '2010-01-01'), (NULL, 'test', 2, '2010-02-01'),
                                          (NULL, 'test', 3, '2010-03-01'), (NULL, 'test', 4, '2010-04-01'),
                                          (NULL, 'test', 5, '2010-05-01'), (NULL, 'test', 6, '2010-06-01'),
                                          (NULL, 'test', 7, '2010-07-01'), (NULL, 'test', 8, '2010-08-01'),
                                          (NULL, 'test', 9, '2010-09-01'), (NULL, 'test', 10, '2010-10-01'),
                                          (NULL, 'test', 11, '2010-11-01'), (NULL, 'test', 12, '2010-12-01');
-- partitions 컬럼에서 p1, p2, p3, p4 모두 나온다. -> p1만 조회하면 되는데, 전체 파티션을 조회한다.
EXPLAIN SELECT * FROM partition_pruning_test WHERE create_at > '2009-12-31' and create_at < '2010-05-01' ;
-- p1 파티션만 조회
SELECT * FROM partition_pruning_test PARTITION (p1);
# -- 파티션 테이블 조회 p1, p2, p3, p4 다 나온다.
# SELECT * FROM information_schema.partitions WHERE table_name = 'partition_pruning_test';

## 13.2.2 - 파티션 사용 시 주의사항
/*
    파티션 테이블의 경우 PK를 포함한 유니크 키에 대해 복잡한 제약 사항이 있다.
    파티션의 목적이 작업의 범위를 좁히는 것인데, 유니크 인덱스는 중복 레코드에 대한 체크 작업 때문에 범위가 좁혀지지 않는다는 점이다.
    또한, 파티션은 일반 테이블과 같이 별도의 파일로 관리된다. (information_schema 에서 확인할 수 있는거 보면 파일로 관리되는거 같다.)
        이와 관련하여 MySQL 서버가 조작할 수 있는 파일의 개수와 연관된 제약도 있다.
*/

### 13.2.2.1 - 파티션과 유니크 키 (프라이머리 키 포함)
-- 종류와 관계없이 테이블에 유니크 인덱스(PK 포함)가 있으면 파티션 키는 모든 유니크 인덱스의 일부 또는 컬럼을 포함해야 한다.
-- 아래 3개의 CREATE TABLE 구문 모두 잘못된 파티션 테이블 생성 방법이다.
CREATE TABLE tb_partition ( -- 유니크 키와 파티션 키가 전혀 연관이 없다.
    fd1     INT NOT NULL,
    fd2     INT NOT NULL,
    fd3     INT NOT NULL,
    UNIQUE KEY (fd1, fd2)
) PARTITION BY HASH ( fd3 )
    PARTITIONS 4;

CREATE TABLE tb_partition ( -- 첫 번째 유니크 키 컬럼인 fd1 만으로 파티션 결정이 되지 않는다.
    fd1     INT NOT NULL,
    fd2     INT NOT NULL,
    fd3     INT NOT NULL,
    UNIQUE KEY (fd1),
    UNIQUE KEY (fd2)
) PARTITION BY HASH ( fd1 + fd2 )
    PARTITIONS 4;

CREATE TABLE tb_partition ( -- PK 컬럼인 fd1 값만으로 파티션 판단이 되지 않는다.
    fd1     INT NOT NULL,
    fd2     INT NOT NULL,
    fd3     INT NOT NULL,
    PRIMARY KEY (fd1),
    UNIQUE KEY (fd2, fd3)
) PARTITION BY HASH ( fd1 + fd2 )
    PARTITIONS 4;

-- 파티션 테이블을 구성할 때 유니크 키에 파티션 키가 제대로 설정됐는지 체크하면 된다.
-- 각 유니크 키에 대해 값이 주어졌을 때 해당 레코드가 어느 파티션에 저장돼 있는지 계산할 수 있어야 한다는 점을 기억하면 된다.
-- 다음 CREATE TABLE 구문은 파티션 키로 사용할 수 있는 테이블들이다.
DROP TABLE IF EXISTS tb_partition;
CREATE TABLE tb_partition (
    fd1     INT NOT NULL,
    fd2     INT NOT NULL,
    fd3     INT NOT NULL,
    UNIQUE KEY (fd1, fd2, fd3)
) PARTITION BY HASH ( fd1 )
    PARTITIONS 4;

DROP TABLE IF EXISTS tb_partition;
CREATE TABLE tb_partition (
    fd1     INT NOT NULL,
    fd2     INT NOT NULL,
    fd3     INT NOT NULL,
    UNIQUE KEY (fd1, fd2)
) PARTITION BY HASH ( fd1 + fd2 )
    PARTITIONS 4;

DROP TABLE IF EXISTS tb_partition;
CREATE TABLE tb_partition (
    fd1     INT NOT NULL,
    fd2     INT NOT NULL,
    fd3     INT NOT NULL,
    UNIQUE KEY (fd1, fd2, fd3),
    UNIQUE KEY (fd3)
) PARTITION BY HASH ( fd3 )
    PARTITIONS 4;

#### 13.2.2.2 - 파티션과 open_files_limit 시스템 변수 설정
-- MySQL 에서는 일반적으로 테이블을 파일 단위로 관리하기 때문에 MySQL 서버에서 동시에 오픈된 파일의 개수가 상당히 많아질 수 있다.
-- 이를 제한하기 위해 open_files_limit 시스템 변수에 동시에 오픈할 수 있는 적절한 파일의 개수를 설정할 수 있다.
-- 파티션되지 않은 테이블은 테이블 1개당 오픈된 파일의 개수가 2~3개 수준이지만 파티션 테이블에서는
  -- (파티션의 개수 * 2~3) 개가 된다.
-- 예를 들어 파티션이 1024개 포함된 테이블이라 가정하고, 파티션 프루닝으로 최적화 되어 1024개의 파티션 가운데 2개의 파티션만 접근하다고 해도
  -- 동시에 모든 파티션의 데이터 파일을 오픈해야 된다. 그래서 파티션을 많이 사용하는 경우 open_files_limit 변수를 높은 값으로 설정해야 한다.
SELECT @@open_files_limit; -- 기본값은 5000
