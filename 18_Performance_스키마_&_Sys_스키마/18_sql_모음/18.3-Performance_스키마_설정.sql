## 18.3 - Performance 스키마 설정
/**
  Performance 스키마는 5.6.6 버전부터 MySQL 구동 시 기본으로 활성화되도록 설정되어 있다.
  명시적으로 Performance 스키마 기능의 활성화 여부를 제어하고 싶은 경우엔 설정 파일에 다음과 같은 옵션을 추가하면 된다.

  ## Performance 스키마 비활성화
  [mysqld]
  performance_schema=OFF

  ## Performance 스키마 활성화
  [mysqld]
  performance_schema=ON
 */
-- SHOW GLOBAL VARIABLES 명령을 통해 Performance 스키마가 화성화돼 있는지 확인할 수 있는 쿼리
SHOW GLOBAL VARIABLES LIKE 'performance_schema'; # 기본값 ON

/**
  사용자는 Performance 스키마에 대해 두 가지 부분으로 나누어 설정할 수 있다.
    1. 메모리 사용량 설정
    2. 데이터 수집 및 저장 설정

  Performance 스키마에서는 수집한 데이터들을 모두 메모리에 저장하므로 해당 스키마가 서버에 영향을 줄 만큼 과도하게 메모리를 사용하지 않는 것이 좋다.
  또한, 사용자가 필요로 하는 이벤트들에 대해서만 수집하도록 설정하는 편이 오버헤드를 줄이고, 성능 저하를 유발하지 않는다.
 */

### 18.3.1. - 메모리 사용량 설정
/**
  MySQL 서버에서 Performance 스키마가 사용하는 메모리의 양을 제어할 수 있는 변수들을 제공한다.
  각 시스템 변수는 사전에 정의된 기본값 또는 MySQL이 조정한 값이 자동 설정되며, -1, 0, 0보다 큰 값들로 설정될 수 있다.
  -1은 정해진 제한 없이 필요에 따라 자동으로 크기가 증가할 수 있음을 의미한다.
 */
select variable_name, variable_value
from performance_schema.global_variables
where variable_name LIKE '%performance_schema%'
and variable_name NOT IN ('performance_schema',
                         'performance_schema_show_processlist');
/**
  Performance 스키마의 메모리 사용량 관련 시스템 변수들은
    - 테이블에 저장되는 데이터 수를 제한하는 변수들과,
    - 데이터를 수집할 수 있는 이벤트 클래스 개수 및 (이벤트 클래스들의 구현체인) 인스턴스들의 수를 제한하는 변수들로 나뉜다.
*/

# - 테이블에 저장되는 데이터 수를 제한하는 변수
/**
    - performance_schema_accounts_size
        accounts 테이블에 저장 가능한 최대 레코드 수를 지정

    - performance_schma_digests_size
        events_statements_summary_by_digest 테이블에 저장 가능한 최대 레코드 수를 지정

    - performance_schema_error_size
        수집 대상 에러 코드 개수를 지정
        기본적으로 MySQL 서버에 정의된 에러 코드 수 만큼 자동으로 설정

    - performance_schema_events_waits_history_size
        events_waits_history 테이블에서 스레드당 지정할 수 있는 최대 레코드 수 지정

    - performance_schema_events_waits_history_long_size
        events_waits_history_long 테이블에 저장할 수 있는 최대 레코드 수를 지정

    - performance_schema_events_stages_history_size
        events_stages_hjistory 테이블에서 스레드당 저장할 수 있는 최대 레코드 수 지정

    - performance_schema_events_stages_history_long_size
        events_stages_history_long 테이블에 저장할 수 잇는 최대 레코드 수를 지정

    - performance_schema_events_statements_history_size
        events_statements_history 테이블에서 스레드당 저장할 수 있는 최대 레코드 수를 지정

    - performance_schema_events_statements_history_long_size
        events_statements_history_long 테이블에 저장할 수 있는 최대 레코드 수를 지정

    - performance_schema_events_transactions_history_size
        events_transactions_history 테이블에서 스레드당 저장할 수 있는 최대 레코드 수를 지정

    - performance_schema_events_transactions_history_long_size
        events_transactions_history_long 테이블에 저장할 수 있는 최대 레코드 수를 지정

    - performance_schema_hosts_size
        hosts 테이블에 저장할 수 있는 최대 레코드 수를 지정

    - performance_schema_session_connect_attrs_size
        클라이언트 프로그램으로부터 전달되는 커넥션 속성들의 키-값 쌍을 저장하기 위해
        스레드당 사전 할당되는 메모리의 크기를 지정

    - performance_schema_setup_actors_size
        setup_actors 테이블에 저장할 수 있는 최대 레코드 수를 지정

    - performance_schema_setup_objects_size
        setup_objects 테이블에 저장할 수 있는 최대 레코드 수를 지정

    - performance_schema_users_size
        users 테이블에 저장할 수 있는 최대 레코드 수를 지정
 */

# Performance 스키마에서 데이터를 수집할 수 있는 이벤트 클래스들의 개수 및 인스턴스들의 수를 제한하는 변수
/***
    - prformance_schema_max_cond_classes
        수집 가능한 조건 이벤트 클래스의 최대 개수를 지정
        조건 이벤트 클래스는 setup_instruments 테이블에서 NAME 컬럼의 값이 'wait/synch/cond'로 시작하는 클래스들로,
        변수에 지정된 개수까지만 setup_instruments 테이블에 표시됨

    - prformance_schema_max_cond_instances
        조건 이벤트 클래스들의 최대 인스턴스 수를 지정한다.
        cond_instances 테이블에 저장될 수 있는 최대 레코드 수이다.

    - prformance_schema_max_file_classes
        수집 가능한 파일 이벤트 클래스의 최대 개수를 지정한다.
        파일 이벤트 클래스는 setup_instruments 테이블에서 NAME 컬럼의 값이 'wait/io/file'로 시작하는 클래스들로,
        변수에 지정된 개수까지만 setup_instruments 테이블에 표시됨

    - prformance_schema_max_file_instances
        파일 이벤트 클래스들의 최대 인스턴스 수를 지정한다.
        file_instances 테이블에 저장될 수 있는 최대 레코드 수이다.

    - prformance_schema_max_mutex_classes
        수집 가능한 뮤텍스 이벤트 클래스의 최대 개수를 지정한다.
        파일 이벤트 클래스는 setup_instruments 테이블에서 NAME 컬럼의 값이 'wait/synch/mutex'로 시작하는 클래스들로,
        변수에 지정된 개수까지만 setup_instruments 테이블에 표시됨

    - performance_schema_max_mutex_instances
        파일 이벤트 클래스들의 최대 인스턴스 수를 지정
        mutex_instances 테이블에 저장될 수 있는 최대 레코드 수라고 할 수 있다.

    - performance_schema_max_rwlock_classes
        수집 가능한 읽기-쓰기 잠금 이벤트 클래스의 최대 개수를 지정
        읽기-쓰기 잠금 이벤트 클래스는 setup_instruments 테이블에서 NAME 컬럼의 값이
        'wait/synch/rwlock', 'wait/synch/prlock', 'wait/synch/sxlock' 로 시작하는 클래스들로,
        변수에 지정된 개수까지만 setup_instruments 테이블에 표시된다.

    - performance_schema_max_rwlock_instances
        읽기-쓰기 잠금 이벤트 클래스들의 최대 인스턴스 수를 지정
        rwlock_instances 테이블에 저장될 수 있는 최대 레코드 수라고 할 수 있다.

    - performance_schema_max_socket_classes
        수집 가능한 소켓 이벤트 클래스의 최대 개수를 지정
        소켓 이벤트 클래스는 setup_instruments 테이블에서 NAME 컬럼의 값이
        'wait/io/socket'으로 시작하는 클래스들로, 변수에 지정된 개수까지만 setup_instruments 테이블에 표시된다.

    - performance_schema_max_socket_instances
        소켓 이벤트 클래스들의 최대 인스턴스 수를 지정
        socket_instances 테이블에 저장될 수 있는 최대 레코드 수라고 할 수 있다.

    - performance_schema_max_thread_classes
        수집 가능한 스레드 이벤트 클래스의 최대 개수를 지정
        setup_threads 테이블에 저장될 수 있는 최대 레코드 수라고 할 수 있다.

    - performance_schema_max_thread_instances
        스레드 이벤트 클래스들의 최대 인스턴스 수를 지정
        threads 테이블에 저장될 수 있는 최대 레코드 수라고 할 수 있다.

    - performance_schema_max_memory_classes
        수집 가능한 메모리 이벤트 클래스의 최대 개수를 지정
        메모리 이벤트 클래스는 setup_instruments 테이블에서 NAME 컬럼의 값이 'memory/'로 시작하는 클래스들로,
        변수에 지정된 개수까지만 setup_instruments 테이블에 표시된다.

    - performance_schema_max_stage_classes
        수집 가능하는 Stage 이벤트 클래스의 최대 개수를 지정
        Stage 이벤트 클래스는 setup_instruments 테이블에서 NAME 컬럼의 값이
        'stage/'로 시작하는 클래스들로, 변수에 지정된 개수까지만 setup_instruments 테이블에 표시된다.

    - performance_schema_max_statement_classes
        수집 가능한 Statement 이벤트 클래스의 최대 개수를 지정
        Statement 이벤트 클래스는 setup_instruments 테이블에서 NAME 컬럼의 값이
        'statement/'로 시작하는 클래스들로, 변수에 지정된 개수까지만 setup_instruments 테이블에 표시된다.

    - performance_schema_max_prepared_statements_instances
        수집 가능한 프리페어 스테이트먼트 인스턴스의 최대 개수를 지정
        prepared_statements_instances 테이블에 저장될 수 있는 최대 레코드 수라고 할 수 있다.

    - performance_schema_max_program_instances
        수집 가능한 스토어드 프로그램 인스턴스들의 최대 개수를 지정

    - performance_schema_max_table_instances
        수집 가능한 테이블 인스턴스들의 최대 개수를 지정

    - performance_schema_max_digest_length
        Performance 스키마에 저장되는 정규화된 쿼리문의 최대 크기를 지정
        값 단위는 바이트(Byte)이며, 다음의 컬럼들이 영향을 받는다.
            - events_statements_current 테이블의 DIGEST_TEXT 컬럼
            - events_statements_history 테입르의 DIGEST_TEXT 컬럼
            - events_statements_history_long 테이블의 DIGEST_TEXT 컬럼
            - events_statements_summary_by_digest 테이블의 DIGEST_TEXT 컬럼

    - performance_schema_max_digtest_sample_age
        events_statements_summary_by_digest 테이블에서 쿼리 다이제트스별로
        해당 다이제스트와 연관된 샘플 쿼리가 주기적으로 새로운 샘플 쿼리로 대체된다.
        대체되는 기준으로는 쿼리의 '대기 시간(소요 시간)'과 '오래된 정도(Age)'가 있다.
        기존 샘플 쿼리가 새로운 샘플 쿼리보다 처리 대기 시간이 더 짧거나 쿼리가 실행된 지 오래된 경우에 새로운 샘플 쿼리로 대체되며,
        기존 샘플 쿼리가 대체되는 '오래된 정도'는 performance_schema_max_digest_sample_age 변수에 지정된 값을 기준으로 결정된다.
        변수의 값 단위는 초(Second)이다.

    - performance_schema_max_metadata_locks
        수집 가능한 메타데이터 잠금의 최대 개수를 지정

    - performance_schema_max_sql_text_length
        Performance 스키마에 저장되는 실행된 원본 쿼리의 최대 크기를 지정
        값 단위는 바이트(Byte)이며, 다음의 컬럼들이 영향을 받는다.
            - events_statements_current 테이블의 SQL_TEXT 컬럼
            - events_statements_history 테이블의 SQL_TEXT 컬럼
            - events_statements_history_long 테이블의 SQL_TEXT 컬럼
            - events_statements_summary_by_digest 테이블의 QUERY_SAMPLE_TEXT 컬럼

    - performance_schema_max_statement_stack
        Performance 스키마가 통계 정보를 유지할 중첩된 스토어드 프로그램 호출의 최대 깊이(Depth)를 지정

    - performance_schema_max_file_handles
        열려 있는 파일 핸들러의 최대 개수를 지정
        값 지정 시 open_files_limit 시스템 변수에 저장된 값보다 큰 값으로 지정해야 한다.

    - performance_schema_max_table_handles
        열려 있는 테이블 핸들러의 최대 개수를 지정

    - performance_schema_max_table_lock_stat
        Performance 스키마에서 잠금 관련 통계 정보를 유지할 최대 테이블 수를 지정

    - performance_schema_max_index_stat
        Performance 스키마에서 인덱스 관련 통계 정보를 유지할 최대 인덱스 수를 지정

  위에 변수들에 설정된 값들로 인해 실제 Performance 스키마에서 데이터 수집 여부를 설정할 수도 없게 Performance 스키마의 상태 변수를 통해 확인할 수 있다.
  상태 변수의 값이 0이면 설정된 제한으로 인해 수집 가능 대상에서 제외된 것이 없고,
  0보다 큰 경우에는 보여지는 수만큼 수집 가능 대상에서 제외된 것이다.
  SHOW GLOBAL STATUS LIKE 'perf%_lost';
 ***/
SHOW GLOBAL STATUS LIKE 'perf%_lost';

/**
    메모리 사용량 관련된 변수들은 MySQL 서버 시작 시 설정 파일에 명시하는 형태로만 적용할 수 있음으로 유념해야 된다.

    [mysqld]
    performance_schema_events_waits_history_size=30
						.
						.
    performance_schema_events_transactions_history_long_size=50000
 */

### 18.3.2 - 데이터 수집 및 저장 설정
/**
  Performance 스키마는 생산자(Producer)-소비자(Consumer) 방식으로 구현되 내부적으로 데이터를 '수집하는 부분'과 '저장하는 부분'으로 나뉘어 동작한다.
  '수집 부분'과 관련해서 모니터링 대상들과 수집 대상 이벤트들을 설정할 수 있으며,
  '저장 부분'과 관련해서는 데이터를 얼마나 상세하게 저장할 것인지 데이터 저장 레벨을 설정할 수 있다.

  이 같은 설정을 적용하는 방법으론 런타임으로도 할 수 있고, MySQL 설정 파일을 통해 영구적으로 적용할 수 있다.
 */

-- 각각의 적용 방식을 살펴보자.
#### 18.3.2.1 - 런타임 설정 적용
/**
  란타임 설정 적용은 Performance 스키마에 존재하는 설정 테이블을 통해 이뤄지며,
  Performance 스키마에서 'setup_'이라는 접두사로 시작하는 테이블들이 설정 테이블이다.
  8.0 버전 기준으로 Performance 스키마에서는 총 5개의 설정 테이블이 존재하며
    SELECT TABLE_SCHEMA
         , TABLE_NAME
         , TABLE_COMMENT
         , TABLE_ROWS
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME LIKE '%setup_%';
 */
-- setup_ 관련된 테이블 조회 (5개가 나온다)
SELECT TABLE_SCHEMA
     , TABLE_NAME
     , TABLE_COMMENT
     , TABLE_ROWS
  FROM INFORMATION_SCHEMA.TABLES
 WHERE TABLE_NAME LIKE '%setup_%';

##### 18.3.2.1.1 - 저장 레벨 설정
/**
  Performance 스키마에서 데이터를 수집하고 저장하는 데 가장 큰 영향을 미치는 설정은 저장 레벨 설정이다.
  '저장 레벨이 설정돼 있지 않은 경우'에는 모니터링 대상이나 수집 대상 이벤트가 설정돼 있더라도 Performance 스키마에 데이터가 '저장되지 않는다'.
  '저장 레벨이 설정돼 있으면' 모니터링 대상 및 수집 대상 이벤트들을 바탕으로 저장 레벨에 따라 적절한 테이블에 데이터를 저장한다.

  저장 레벨을 설정할 수 있는 setup_consumers 테이블에는 다음과 같은 설정 데이터들이 저장돼 있다.
  NAME 컬럼의 표시되는 값은 저장 레벨의 이름이며, ENABLED 컬럼은 해당 저장 레벨의 활성화 여부를 나타낸다.
 */
SELECT * FROM performance_schema.setup_consumers;

/**
  저장 레벨들은 다음과 같은 계층 구조를 갖는다. (ㄱ, ㄴ, ㄷ 순)
    ㄱ global_instrumentation - 최상위 저장 레벨 (수집한 데이터를 이벤트 클래스별로 전역적으로만 저장)
        ㄴ thread_instrumentation - 스레드별로도 데이터 저장 가능
            ㄷ events_waits_current
                - events_waits_history
                - events_watis_history_long
            ㄷ events_stages_current
                - events_stages_history
                - events_stages_history_long
            ㄷ events_statements_current
                - events_statements_history
                - events_statements_history_long
            ㄷ events_transactions_current
                - events_transactions_history
                - events_transactions_history_long
        ㄴ statements_digest - 쿼리 다이제스트별로 데이터를 저장해 다이제스트별 통계 정보를 확인할 수 있게

  상위 레벨에서 하위 레벨로 갈수록 데이터를 더 상세하게 저장한다.
  상위 레벨이 비활성화돼 있으면 하위 레벨이 활성화돼 있더라도 하위 레벨의 설정은 Performance 스키마에 적용되지 않는다.
 */
-- 다음과 같은 SQL문을 통해 저장 레벨의 활성화 여부를 설정할 수 있고, 이렇게 설정된 내용은 Performance 스키마에 바로 반영된다.
UPDATE performance_schema.setup_consumers
SET enabled = 'YES'
WHERE NAME LIKE '%변경하고싶은 name 명%';

##### 18.3.2.1.2 - 수집 대상 이벤트 설정
/**
  setup_instruments 테이블을 통해 Performance 스키마가 어떤 이벤트들에 대한 데이터를 수집하게 할 것인지 수집 대상 이벤트를 설정할 수 있다.
  setup_instruments 테이블의 레코드들은 MySQL 소스코드에서 성능 측정이 설정된 객체들의 클래스 목록이 자동으로 표시된 것으로,
  Performance 스키마는 해당 모록에 속한 클래스의 인스턴스들로부터 데이터를 수집할 수 있다.

 */
select * from performance_schema.setup_instruments;
select * from performance_schema.setup_instruments where name like '%memory/performance%'; -- 사용자가 변경하지 못함

/**
  setup_instruments 컬럼에서 enabled 컬럼과 timed 컬럼면 변경 가능하다.
  또한, 'memory/performance_schema/' 로 시작하는 이벤트 클래스는 사용자가 비활성화 할 수 없다.
 */
-- 쿼리가 동작은 하지만, 적용되지 않는다.
update performance_schema.setup_instruments
set enabled='NO'
where name = 'memory/performance_schema/mutex_instances';

/**
  setup_instruments 컬럼에는 다음과 같은 값들이 있다.

    - name
        구분자('/')를 사용해 계층형으로 구성된 이벤트 클래스명
        이벤트 클래스명은 디렉토리 경로와 같은 표현 방법을 사용하고, 구분자를 기준으로 부모 자식 노드의 관계를 갖게 된다.
    - enabled
        성능 지표를 측정할지 여부를 나타내며, 이벤트 데이터들을 수집할 것인지를 결정
    - timed
        이벤트드들에 대해 경과 시간 등과 같은 시간 측정을 수행할 것인지에 대한 여부를 나타낸다.
        이 컬럼의 값이 NULL로 표시되는 이벤트 클래스들은 이러한 시간 측정을 지원하지 않음을 의미
        측정된 시간 값은 수집된 이벤트 데이터들이 저장되는 테이블들에서 이름이 'TIMER_'로 시작하는 컬럼들에 표시
    - properties
        이벤트 클래스의 특성을 나타낸다.
    - volatility
        이벤트 클래스의 휘발성을 나타낸다.
        큰 값일수록 이벤트 클래스의 인스턴스 생성 주기가 짧음을 의미한다.
        0으로 표시되는 경우 이는 알 수 없음을 의미
    - documentation
        이벤트 클래스에 대한 간략한 설명이 나와 있다.
  setup_instruments 테이블에 대한 변경은 대부분 즉시 반영되나, 기존에 생성된 인스턴스에는 영향이 미치지 않는다.
  따라서, volatility 컬럼의 값이 작은 클래스들은 런타임에 변경해도 효과가 없을 수 있다.
  만약, volatility 컬럼의 값이 큰 클래스들은 인스턴스의 생성과 종료가 빈번하게 발생함을 의미하므로 새로 설정된 내용이 빨리 반영된다.

  이벤트 클래스명에서 최상위 분류 값은 이벤트 타입을 의미하며, setup_instruments 테이블에는 다음과 같은 이벤트 타입들이 존재한다.
    - wait
        I/O 작업 및 잠금, 스레드 동기화 등과 같이 시간이 소요되는 이벤트를 의미
    - stage
        SQL 명령문의 처리 단계와 관련된 이벤트를 의미한다.
    - statement
        SQL 명령문 또는 스토어드 프로그램에서 실행되는 내부 명령들에 대한 이벤트를 의미
    - transaction
        MySQL 서버에서 실해된 트랜잭션들에 대한 이벤트를 의미
    - memory
        MySQL 서버에서 사용 중인 메모리와 관련된 이벤트를 의미
    - idle
        유휴 상태에 놓여있는 소켓과 관련된 이벤트를 의미
    - error
        MySQL 서버에서 발생하는 경고 및 에러와 관련된 이벤트를 의미
 */
SELECT DISTINCT SUBSTRING_INDEX(NAME, '/', 1) AS 'Event Type'
FROM performance_schema.setup_instruments;

### 18.3.2.1.3 - 모니터링 대상 설정
/**
  setup_instruments 테이블에서 수집 대상 이벤트들의 데이터를 모두 수집하는 것은 아니다.
  사용자는 setup_objects, setup_threads, setup_actors 테이블을 통해 Performance 스키마가 모니터링할 대상을 설정할 수 있다.

    - setup_objects
        MySQL 서버 내에 존재하는 데이터베이스 객체들에 대한 모니터링 설정 벙보를 담고 있다.
        객체가 현재 모니터링 대상인지 확인하기 위해
        setup_objects 테이블의 obejct_schema, object_name 컬럼을 바탕으로 매칭되는 데이터를 찾는다.

    - setup_threads
        Performance 스키마가 데이터를 수집할 수 있는 스레드 객체의 클래스 목록이 저장돼 있다.
        사용자는 이 테이블을 통해 Performance 스키마가 어떤 스레드를 모니터링하며 데이터를 수집할 것인지 설정 가능
        기본적으로 이 테이블에 있는 모든 스레드 클래스에 대해 enabled 컬럼과 history 컬럼 값은 YES로 설정된다.
        사용자는 enabled, history 컬럼의 값을 변경해서 모니터링 여부를 재설정 할 수 있다.
        단, 기존의 동작 중인 스레드들은 해당 변경 사항이 적용되지 않는다.
        만약, 기존 스레드에 대해 모니터링 설정을 변경하고 싶다면
            Performance 스키마의 threads 테이블에서 INSTRUMENTED 컬럼과 HISTORY 컬럼값을 변경하면 된다.

        사용자가 setup_threads, threads 테이블을 통해 정상적으로 저장되려면
        setup_consumers 테이블에서 global_instrumentation 저장 레벨과 thread_instrumentation 저장 레벨이 모두 YES로 되어 있어야 함
        만약, 과거 이벤트 데이터를 보관하도록 설정돼 있는 경우에는
        history, history_long 키워드가 포함된 저장 레벨도 YES로 설정되어 있어야 한다.

        또한, 클라이언트 연결로 인해 성성되는 포그라운드 스레드의 경우(thread/sql/one_connection 스레드 등..)
        setup_threads 테이블에서 설정된 내용이 무시되고, setup_actors 테이블의 설정이 적용된다. 이 점을 유의해야 한다.
        백그라운드 스레드의 경우는 위와 반대로 setup_actors 테이블에 설정된 내용에 전혀 영향을 받지 않는다.


    - setup_actors
        모니터링 대상 DB 계정을 설정할 수 있고, 기본적으론 모든 DB 계정에 대해 모니터링하고 과거 이벤트 데이터를 보관한다.

        MySQL 서버에 클라이언트 연결 스레드(포그라운드 스레드)가 생성되면 Performance 스키마에서는
        해당 스레드에서 사용하는 DB 계정과 매칭되는 데이터를 setup_actors 테이블에서 확인하고 모니터링 여부를 결정한다.
        setup_objects 테이블과 동일하게 host 컬럼과 user 컬럼의 값이 가장 근저바게 매칭되는 데이터 설정이 스레드에 적용된다.

        각 스레드에 적용된 설정값은 setup_threads 와 마찬가지로
        threads 테이블에 INSTRUMENTED 컬럼과 HISTORY 컬럼의 값을 통해 확인할 수 있다.
        두 컬럼의 값을 직접 변경해서 현재 동작 중인 스레드에 변경된 내용이 바로 적용되게 할 수도 있다.

        사용자가 변경한 setup_actors 테이블의 내용은 변경 이후 생성되는 클라이언트 연결 스레드에만 적용된다.
 */

-- setup_objects 테이블에 관련된 정보
SELECT * FROM performance_schema.setup_objects;
/*
  setup_objects 테이블에 대한 컬럼들 설명

    - object_type
        객체 타입을 나타낸다.
    - object_schema
        객체가 속한 스키마를 나타내며, '%' 값은 모든 스키마를 의미
    - object_name
        객체의 이름을 나타내며, '%' 값은 모든 객체를 의미
    - enabled
        모니터링 대상 여부를 나타낸다.
    - timed
        시간 측정 수행 여부를 나타낸다.
 */

-- setup_threads 테이블에 관련된 정보
SELECT * FROM performance_schema.setup_threads;
/**
  setup_threads 테이블에 대한 컬럼들 설명

    - name
        스레드 클래스명으로, 구분자('/')를 사용해 계층형으로 구성된다.
    - enabled
        성능 지표를 측정할지 여부를 나타내며, 해당 스레드에 대한 모니터링 여부를 결정
    - history
        과거 이벤트 데이터 보관 여부를 나타낸다.
    - properties
        클래스의 특성을 나타낸다.
    - volatility
        클래스의 휘발성을 나타낸다.
        큰 값일수록 이벤트 클래스의 인스턴스 생성 주기가 짧음을 의미
        0 값으로 표시된 경우 이는 알 수 없음을 뜻한다.
    - documentation
        클래스에 대한 간략한 설명
 */

-- setup_actors 테이블에 관련된 정보
SELECT * FROM performance_schema.setup_actors;
/**
  setup_actors 테이블에 대한 컬럼들 설명

    - host
        호스트명을 나타내고, '%' 값은 모든 호스트를 의미
    - user
        유저명을 나타내고, '%' 값은 모든 유저를 의미
    - role
        현재 사용되지 않는 컬럼이다.
    - enalbled
        모니터링 여부를 나타낸다.
    - history
        과거 이벤트 데이터 보관 여부를 나타낸다.
 */

#### 18.3.2.2 - Performance 스키마 설정의 영구 적용
/**
  setup 테이블을 통해 동적으로 변경한 Performance 스키마 설정은 서버가 재시작되면 모두 초기화된다.
  해당 설정을 재시작하더라도 유지하고 싶거나, 서버 시작 시 바로 Performance 스키마에 설정을 적용하고 싶은 경우에는 MySQL 설정 파일을 사용하면 된다.
  단, 설정 파일을 사용하는 스타트업 설정은 'Performance 스키마의 수집 대상 이벤트' 및 '데이터 저장 레벨에 대해서만 가능'하다.

  'Performance 스키마의 수집 대상 이벤트' 설정 파일 적용 방법
    [mysqld]
    performance_schema_instrument='수집_대상_이벤트_클래스명=[0 | 1 | COUNTED]'

	수집_대상_이벤트_클래스명에 와일드 카드(%)를 사용할 수도 있다.

	value 의 값으로 0, 1, COUNTED 를 사용할 수 있으며, 해당 값의 의미는 다음과 같다.
		0 : [OFF 또는 FALSE]로 사용할 수 있고, 수집 대상에서 제외한다.
			setup_instruments 테이블의 ENABLED, TIMED 컬럼이 모두 'NO'로 설정된 것과 동일
		1 : [ON 또는 TRUE]로 사용할 수 있고, 수집 대상으로 설정하며 시간 측정 수행도 활성화한다.
			setup_instruments 테이블의 ENABLED, TIMED 컬럼이 모두 'YES'로 설정된 것과 동일
		COUNTED : 수집 대상으로만 설정하며, 시간 측정은 수행되지 않는다.
				  setup_instruments 테이블의 ENABLED 컬럼만 'YES'로 설정된 것과 동일

  하나의 performance_schema_instrument 옵션에 여러 개의 수집 대상 이벤트 클래스명을 지정할 수는 없다.
  여러 개의 클래스명을 지정하고 싶은 경우에는 원하는 클래스 수만큼 performance_schema_instrument 옵션을 중복해서 사용해야 한다.

  '데이터 저장 레벨'은 다음과 같은 형태로 사용할 수 있다.
    [mysqld]
    performance_schema_consumer_consumer_name=value
  옵션명에 포함되는 'consumer_name'에는 저장 레벨명을 지정하며, 'value'에는 다음의 값으로 설정할 수 있다.
    0, OFF 또는 FALSE : 저장 레벨 비활성화
    1, ON 또는 TRUE : 저장 레벨 활성화

  'consumer_name'에는 '%' 또는 '_' 같은 와일드 카드 문자는 사용할 수 없다.
  setup_consumers 테이블에 있는 저장 레벨들의 이름으로만 지정 가능하고,
  여러 개의 저장 레벨들을 설정하고 싶은 경우 위와 마찬가지로 옵션을 중복해서 사용하면 된다.
 */
