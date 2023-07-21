# 11.5.2 - LOAD DATA 명령 주의 사항
-- MySQL 서버의 LOAD DATA 명령은 내부적으로 MySQL 엔진과 스토리지 엔진의 호출 횟수를 최소화한다.
-- 그리고, 스토리지 엔진이 직접 데이터를 적재하기 때문에 일반적인 INSERT 문보다 더 빠르다.
-- 하지만 2가지 단점이 있다.
    # 1. 단일 스레드로 실행
    # 2. 단일 트랜잭션으로 실행
-- 따라서, 가능하다면 LOAD DATA 문장으로 적재할 데이터 파일을 하나보다는 여러 개의 파일로 준비해서 여러 트랜잭션으로 나뉘어 실행되게 하는 것이 좋다.
LOAD DATA
    [LOW_PRIORITY | CONCURRENT] [LOCAL]
    INFILE 'file_name'
    [REPLACE | IGNORE]
    INTO TABLE tbl_name
    [PARTITION (partition_name [, partition_name] ...)]
    [CHARACTER SET charset_name]
    [{FIELDS | COLUMNS}
        [TERMINATED BY 'string']
        [[OPTIONALLY] ENCLOSED BY 'char']
        [ESCAPED BY 'char']
    ]
    [LINES
        [STARTING BY 'string']
        [TERMINATED BY 'string']
    ]
    [IGNORE number {LINES | ROWS}]
    [(col_name_or_user_var
        [, col_name_or_user_var] ...)]
    [SET col_name={expr | DEFAULT}
        [, col_name={expr | DEFAULT}] ...]

