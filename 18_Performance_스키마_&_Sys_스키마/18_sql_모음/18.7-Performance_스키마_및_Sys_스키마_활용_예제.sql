## 18.7 - Performance 스키마 및 Sys 스키마 활용 예제
/**
  Performance 스키마와 Sys 스키마를 활용하는 대표적인 예제를 확인해보자.
 */

### 18.7.1 - 호스트 접속 이력 확인
-- MySQL 서버가 구동된 시점부터 현재까지 MySQL에 접속했던 호스트들의 전체 목록을 얻고자 할 때
SELECT * FROM performance_schema.hosts;
/**
  host의 컬럼이 NULL 인 데이터는 MySQL 내부 스레드 및 연결 시 인증에 실패한 커넥션들이 포함된다.
  current_conections 컬럼은 현재 연결된 커넥션 수를 뜻한다.
  total_connections 컬럼은 연결했던 커넥션 총 수를 뜻한다.
 */

-- MySQL에 원격으로 접속한 호스트들에 대해 호스트별로 현재 연결된 커넥션 수를 확인하고자 할 때
SELECT host, current_connections
FROM performance_schema.hosts
WHERE current_connections > 0 AND host NOT IN ('NULL', '127.0.0.1')
ORDER BY host;

### 18.7.2 - 미사용 DB 계정 확인
/**
  MySQL 서버가 구동된 시점부터 현재까지 사용되지 않은 DB 계정들을 확인하고자 할 때 사용할 수 있다.
  현재 MySQL에 생성돼 있는 계정들을 대상으로
    - 계정별 접속 이력 유무와 뷰
    - 스토어드 프로그램들(프로시저, 트리거 등)의 생성 유무
  위의 두 경우 모두 해당되지 않는 계정들의 목록을 출력한다.
 */
SELECT DISTINCT m_u.user, m_u.host
FROM mysql.user m_u
LEFT JOIN performance_schema.accounts ps_a ON m_u.user = ps_a.user AND ps_a.host = m_u.host
LEFT JOIN information_schema.views is_v ON is_v.definer = CONCAT(m_u.user, '@', m_u.host) AND is_v.security_type = 'DEFINER'
    LEFT JOIN information_schema.routines is_r ON is_r.definer = CONCAT(m_u.user, '@', m_u.host) AND is_r.security_type = 'DEFINER'
    LEFT JOIN information_schema.events is_e ON is_e.definer = CONCAT(m_u.user, '@', m_u.host)
    LEFT JOIN information_schema.triggers is_t ON is_t.definer = CONCAT(m_u.user, '@', m_u.host)
WHERE ps_a.user IS NULL
    AND is_v.definer IS NULL
    AND is_r.definer IS NULL
    AND is_e.definer IS NULL
    AND is_t.definer IS NULL
ORDER BY m_u.user, m_u.host;

### 18.7.3 - MySQL 총 메모리 사용량 확인
-- MySQL 서버가 사용하고 있는 메모리 전체 사용량을 확인하는 쿼리
SELECT * FROM sys.memory_global_total;

### 18.7.4 - 스레드별 메모리 사용량 확인
-- MySQL 서버에서 동작 중인 스레드들의 메모리 사용량을 확인하는 쿼리 (내부 백그라운드 스레드 및 클라이언트 연결 스레드들의 현재 메모리 사용량이 출력)
-- 기본적으로 current_allocated 컬럼을 기준으로 내림차순으로 출력된다.
SELECT thread_id, user, current_allocated
FROM sys.memory_by_thread_by_current_bytes
LIMIT 10;

-- 특정 스레드에 대해 구체적인 메모리 할당 내역을 확인하고 싶은 경우
SELECT thread_id,
       event_name,
       sys.format_bytes(current_number_of_bytes_used) as `current_allocated`
FROM performance_schema.memory_summary_by_thread_by_event_name
WHERE thread_id = 55
ORDER BY current_number_of_bytes_used DESC
LIMIT 10;
/**
  이 위에서 나오는 thread_id 값은 SHOW PROCESSLIST 의 결과에 표시되는 ID 컬럼과는 다른 값이다.
    - Performance 스키마에서 스레드를 식별하기 위해 부여한 ID 값이다.
  SHOW PROCESSLIST의 ID 값을 바탕으로 Performance 스키마 THREAD_ID 값을 확인하려면 다음과 같이 사용할 수 있다.
 */
-- show processlist의 id 값이 14인 스레드의 performance 스키마 thread_id 확인하는 방법
-- 방법 1
SELECT thread_id, processlist_id
FROM performance_schema.threads
WHERE processlist_id = 14;

-- 방법 2
SELECT sys.ps_thread_id(14);

### 18.7.5 - 미사용 인덱스 확인
/**
  Sys 스키마의 schema_unused_indexes 뷰를 통해 서버가 구동된 시점부터 조회 시점까지 사용되지 않은 인덱스의 목록을 확인할 수 있다.
  사용하지 않은 인덱스는 서버 관리 측면에서도 제거하는 것이 좋다.
  제거할 때는 전에서 봤듯이 INVISIBLE 상태로 먼저 변경하고, 일정 기간 문제가 없음을 확인한 뒤 제거하는 것이 좋다.
*/
-- 사용되지 않은 인덱스 목록확인하는 쿼리
SELECT * FROM sys.schema_unused_indexes;

-- 인덱스를 INVISIBLE 상태로 변경
ALTER TABLE 테이블명 ALTER INDEX 인덱스_명 INVISIBLE;

-- INVISIBLE 상태 확인
SELECT TALBE_NAME, INDEX_NAME, IS_VISIBLE
FROM information_schema.statistics
WHERE table_schema='데이터베이스_이름' AND table_name='테이블_명' AND index_name = '인덱스_명';

### 18.7.6 - 중복된 인덱스 확인
-- Sys 스키마의 schema_redundant_indexes 뷰를 통해 중복된 인덱스의 목록을 확인하는 쿼리
-- 조회된 뷰에서 'redundant_'로 시작하는 컬럼은 중복된 것으로 간주되는 인덱스 정보가 표시되고,
-- 'dominant_'로 시작하는 컬럼은 중복된 인덱스를 중복으로 판단되게 한 인제스의 정보가 표시된다.
-- 'sql_drop_index' 컬럼을 통해 중복된 인덱스를 제거하기 위한 ALTER 문도 제공한다.
SELECT * FROM sys.schema_redundant_indexes LIMIT 1;

### 18.7.7 - 변경이 없는 테이블 목록 확인
-- 쓰기가 발생하지 않는 테이블의 목록을 확인하고자 할 때
SELECT t.table_schema, t.table_name, t.table_rows, tio.count_read, tio.count_write
FROM information_schema.tables AS t
JOIN performance_schema.table_io_waits_summary_by_table AS tio
  ON tio.object_schema = t.table_schema AND tio.object_name = t.table_name
WHERE t.table_schema NOT IN ('mysql', 'performance_schema', 'sys')
  AND tio.count_write = 0
ORDER BY t.table_schema, t.table_name;

### 18.7.8 - I/O 요청이 많은 테이블 목록 확인
/**
  Sys 스키마의 io_global_by_file_by_bytes 뷰를 조회해서 테이블드에 대한 I/O 발생량을 종합억으로 확인해볼 수 있다.
  해당 뷰는 기본적으로 파일별로 발생한 읽기, 쓰기 전체 총량을 기준으로 내림차순으로 결과를 보여준다.
 */
SELECT * FROM sys.io_global_by_file_by_bytes WHERE file LIKE '%ibd';

### 18.7.9 - 테이블별 작업량 통계 확인
-- Sys 스키마의 schema_table_statistics 뷰를 통해 각 테이블에 대해 데이터 작업 유형, I/O 유형별 전체 통계 정보를 확인할 때
SELECT table_schema, table_name,
       rows_fetched, rows_inserted, rows_updated, rows_deleted, io_read, io_write
FROM sys.schema_table_statistics
WHERE table_schema NOT IN ('mysql', 'performance_schema', 'sys');
-- 사용 형태를 알고 그에 맞춰 현재 상태로부터 개선할 방향을 결정할 때 사용한다.
-- ex. 데이터 변경은 거의 없고, 조회는 자주 발생할 때 조회 쿼리를 확인해서 캐싱을 적용하는 방법 등이 있다.

### 18.7.10 - 테이블의 AUto-Increment 컬럼 사용량 확인
/**
  Auto-Increment 컬럼은 저장할 수 있는 최댓값이 존재한다.
  최댓값보다 큰 값을 가지는 데이터는 저장할 수 없으므로 많은 양의 데이터가 저장되는 테이블을 사용 중인 경우에 주기적으로 해당 컬럼을 확인해야 한다.
  다음 쿼리는 Auto-Increment 컬럼의 값을 확인할 때 사용하는 쿼리이다.
 */
SELECT table_schema, table_name, column_name,
       auto_increment AS 'current_value', max_value,
       ROUND(auto_increment_ratio * 100, 2) AS 'usage_ratio'
FROM sys.schema_auto_increment_columns;

### 18.7.11 - 풀 테이블 스캔 확인
/**
  쿼리의 성능을 개선하려면 테이블 풀스캔은 피하고 해당 쿼리들을 수정하는 것이 좋다.
  슬로우 쿼리 로그(Slow Query Log) 파일에서도 쿼리 실행 시간이 긴 쿼리들을 확인할 수 있다.
  하지만, 슬로우 쿼리 로그 파일에는 풀 스캔 뿐만 아니라 실행 시간이 오래 걸리는 다양한 쿼리가 존재한다.

  테이블 풀스캔하는 쿼리들만 확인하고 싶은 경우 다음의 쿼리를 사용할 수 있다.
 */
SELECT db, query, exec_count,
       sys.format_time(total_latency) as 'formatted_total_latency',
       rows_sent_avg, rows_examined_avg, last_seen
FROM sys.statements_with_full_table_scans
ORDER BY total_latency DESC;

### 18.7.12 - 자주 실행되는 쿼리 목록 확인
-- 빈번하게 실행되는 쿼리들를 확인하고자 할 때
SELECT db, exec_count, query
FROM sys.statement_analysis
ORDER BY exec_count DESC;

### 18.7.13 - 실행 시간이 긴 쿼리 목록 확인
-- 오랫동안 실행된 쿼리들의 목록을 확인하고자 할 때
-- 풀 테이블 스캔과 마찬가지로 슬로우 쿼리 로그(Slow Query Log) 파일을 이용해도 되지만 sys 스키마를 이용해보자.
-- Sys 스키마에서는 오래 실행된 쿼리들에 대해 쿼리 유형별로 '누적 실행 횟수'와 '평균 실행 시간' 등의 통계 정보도 함께 제공한다.
SELECT query, exec_count, sys.format_time(avg_latency) as 'formatted_avg_latency',
       rows_sent_avg, rows_examined, last_seen
FROM sys.statement_analysis
ORDER BY avg_latency DESC;

### 18.7.14 - 정렬 작업을 수행한 쿼리 목록 확인
-- 정렬 작업이 들어가면 CPU 자원을 더 많이 수행한다. 따라서, 쿼리를 수정하거나 테이블 인덱스를 조정해 새로운 인덱스를 추가하는 것도 방법이다.
-- 다음 쿼리를 통해 정렬 작업을 수행한 쿼리들의 목록을 확인할 수 있다.
SELECT * FROM sys.statements_with_sorting ORDER BY last_seen DESC LIMIT 1;

### 18.7.15 - 임시 테이블을 생성하는 쿼리 목록 확인
-- 임시 테이블을 생성하는 쿼리들에 대해 쿼리 형태별로 해당 쿼리에서 생성한 임시 테이블 종류, 개수 등에 대해 알고 싶을 때
SELECT * FROM sys.statements_with_temp_tables LIMIT 10;

### 18.7.16 - 트랜잭션이 활성 상태인 커넥션에서 실행한 쿼리 내역 확인
/**
  종종 MySQL 서버에서 어떤 트랜잭션 세션이 정상적으로 종료되지 않고 오랫동안 남아있는 경우가 있다.
  이 경우 해당 트랜잭션에서 실행한 쿼리들로 인해 다른 세션에서 실행된 쿼리가 처리되지 못하고 대기할 수 있으며,
  다량으로 쌓인 언두 데이터로 인해 쿼리 성능이 저하될 수 있다.
  이 같은 문제 상황이 발생하지 않도록 트랜잭션이 남아있는 원인을 파악하고 해결하는 것이 중요하다.

   - 원인 파악을 위한 가장 간단한 방법 - 트랜잭션에서 실행된 쿼리들을 확인하는 것
   -
 */
-- 원인 파악을 위한 가장 간단한 방법 - 트랜잭션에서 실행된 쿼리들을 확인하는 것
SELECT ps_t.processlist_id,
       ps_esh.thread_id,
       CONCAT(ps_t.processlist_user, '@', ps_t.processlist_host) AS 'db_account',
       ps_esh.event_name,
       ps_esh.sql_text,
       sys.format_time(ps_esh.timer_wait) AS 'duration',
        DATE_SUB(NOW(), INTERVAL (SELECT variable_value FROM performance_schema.global_status WHERE
                variable_name='UPTIME') - ps_esh.TIMER_START*10e-13 second) AS `start_time`,
       DATE_SUB(NOW(), INTERVAL (SELECT variable_value FROM performance_schema.global_status WHERE
                variable_name='UPTIME') - ps_esh.TIMER_START*10e-13 second) AS `end_time`
FROM performance_schema.threads ps_t
  INNER JOIN performance_schema.events_transactions_current ps_etc on ps_etc.thread_id = ps_t.thread_id
  INNER JOIN performance_schema.events_statements_history ps_esh on ps_esh.nesting_event_id = ps_etc.event_id
WHERE ps_etc.STATE='ACTIVE'
  AND ps_esh.MYSQL_ERRNO=9
ORDER BY ps_t.processlist_id, ps_esh.TIMER_START;

-- 특정 세션에서 실행된 쿼리들의 전체 내역을 확인하고 싶은 경우 (쿼리 내역을 살펴보고 싶은 세션의 PROCESSLIST ID 값을 먼저 알아야 된다.)
SELECT
    ps_t.processlist_id,
    ps_esh.thread_id,
    CONCAT(ps_t.processlist_user, '@', ps_t.processlist_host) AS 'db_account',
    ps_esh.event_name,
    ps_esh.sql_text,
    DATE_SUB(NOW(), INTERVAL (SELECT variable_value FROM performance_schema.global_status WHERE
            variable_name='UPTIME') - ps_esh.timer_start * 10e-13 second) AS `start_time`,
    DATE_SUB(NOW(), INTERVAL (SELECT variable_value FROM performance_schema.global_status WHERE
            variable_name='UPTIME') - ps_esh.timer_start * 10e-13 second) AS `end_time`,
    sys.format_time(ps_esh.timer_wait) AS `duration`
FROM performance_schema.events_statements_history ps_esh
  INNER JOIN performance_schema.threads ps_t ON ps_t.thread_id = ps_esh.thread_id
WHERE ps_t.processlist_id = '쿼리_내역을_확인해보고_싶은_세션의_processlist_id_값'
  AND ps_esh.sql_text IS NOT NULL
  AND ps_esh.mysql_errno = 0
ORDER BY ps_esh.timer_start;

### 18.7.17 - 쿼리 프로파일링
/**
  쿼리가 처리될 때 처리 단계별로 시간이 어느 정도 소요됐는지 확인이 필요할 때 다음과 같이 확인할 수 있다.
  SHOW PROFILE, SHOW PROFILES 명령을 사용하거나 Performance 스키마를 통해 처리 단계별 소요 시간을 확인할 수 있다.
  SHOW PROFILE, SHOW PROFILES 명령은 5.6.7 버전부터 Deprecated 됐으므로 Performance 스키마를 이용하는 법을 살펴보자.

  Performance 스키마를 통해 프로파일링을 적용하려면 특정 설정이 반드시 활성화 돼야 한다.
  따라서, 쿼리 프로파일링을 완료한 뒤 원래 설정으로 되돌리고 싶으면 Sys 스키마의 ps_setup_save() 프로시저를 실행하는 것이 좋다.
 */
-- 현재 Performance 스키마 설정을 저장
CALL sys.ps_setup_save(10);

-- 쿼리 프로파일링을 위해 설정 변경을 진행
UPDATE performance_schema.setup_instruments
SET enabled = 'YES', timed = 'YES'
WHERE name LIKE '%statement/%' OR name LIKE '%stage/%';

UPDATE performance_schema.setup_consumers
SET enabled = 'YES'
WHERE name LIKE '%events_statements_%' OR name LIKE '%events_stages_%';

/**
  위 작업으로 설정이 완료되면 프로파일링 정보를 확인하고자 하는 쿼리를 실행한 뒤 events_statements_history_long 테이블에서
  해당 쿼리에 매핑되는 Performance 스키마의 이벤트 ID 값을 확인하면 된다.
 */
-- 프로파일링 대상 쿼리를 진행
SELECT * FROM real_my_sql_80_book.employees WHERE emp_no = 20012;

-- 실해된 쿼리에 매핑되는 이벤트 ID 값을 확인
SELECT event_id,
       sql_text,
       sys.format_time(timer_wait) AS 'Duration'
FROM performance_schema.events_statements_history_long
WHERE sql_text like '%20012%';

-- 위에서 확인한 이벤트 ID 값으로 Performance 스키마의 events_stages_history_long 테이블을 조회하면 쿼리 프로파일링 정보를 확인할 수 있다.
SELECT event_name AS 'Stage',
       sys.format_time(timer_wait) AS 'Duration'
FROM performance_schema.events_stages_history_long
WHERE nesting_event_id = 위에서_확인한_ID_값
ORDER BY timer_start;

-- Performance 스키마의 설정을 되돌리고 싶으면 Sys 스키마의 ps_setup_reload_saved() 프로시저를 이용하면 된다.
CALL sys.ps_setup_reload_saved();

### 18.7.18 - ALTER 작업 진행률 확인
/**
  ALTER TABLE 명령문을 사용해 테이블 스키마를 변경하는 작업의 진행률을 Performance 스키마의 이벤트 데이터를 통해 확인할 수 있다.
  '18.7.17 - 쿼리 프로파일링'과 마찬가지로 ALTER 작업과 관련된 설정들을 활성화 해야 한다.
 */
-- ALTER 작엽 관련 설정이 잘 되어 있는지 확인하는 쿼리 (모두 YES 여야 함)
SELECT name, enabled, timed
FROM performance_schema.setup_instruments
WHERE NAME LIKE 'stage/innodb/alter%';

-- 여기 또한 모두 YES 여야 한다.
SELECT * FROM performance_schema.setup_consumers WHERE name LIKE '%stages%';

-- YES 가 아니라면 활성화 시켜기
UPDATE performance_schema.setup_instruments
SET enabled = 'YES', timed = 'YES'
WHERE name LIKE 'stage/innodb/alter%';

UPDATE performance_schema.setup_consumers
SET enabled = 'YES'
WHERE name LIKE '%stages%';

-- ALTER TABLE 명령 실행 (mysql_session 1 에서 작업 )
ALTER TABLE 변경하고싶은_테이블_명 ADD KEY ix_col1 (col1);

-- ALTER 작업 진행률 확인 (mysql_session 2 에서 작업 )
SELECT ps_estc.nesting_event_id,
       ps_esmc.sql_text,
       ps_estc.event_name,
       ps_estc.work_completed,
       ps_estc.work_estimated,
       ROUND((work_completed / work_estimated) * 100, 2) as 'PROGRESS(%)'
FROM performance_schema.events_stages_current ps_estc
INNER JOIN performance_schema.events_statements_current ps_esmc
    ON ps_estc.nesting_event_id = ps_esmc.event_id
WHERE ps_estc.event_name LIKE 'stage/innodb/alter%';

-- performance 스키마의 events_stages_history_long 테이블을 조회해서 ALTER 작업에 대해 진행 단계, 단계별 소요 시간을 확인할 수도 있다.
-- 다음의 쿼리를 사용하고, 쿼리의 WHERE 절에서 nesting_event_id 컬럼에는 alter 명령문의 이벤트 ID 값을 조건으로 전달하면 된다.
SELECT nesting_event_id, event_id, event_name,
       sys.format_time(timer_wait) AS 'ELAPSED_TIME'
FROM performance_schema.events_stages_history_long
WHERE nesting_event_id = 이벤트_ID_값
ORDER BY timer_start

### 18.7.19 - 메타데이터 락 대기 확인
/**
  다른 세션에서 변경 대상 테이블에 메타 데이터 락을 걸어놓은 경우 현재 세션에서의 ALTER TABLE 문은 실행되지 못한다.
  Sys 스키마의 schema_table_lock_waits 뷰를 조회해서 현재 ALTER TABLE 작업을 대기하게 만든 세션에 대한 정보를 얻을 수 있다.

  'waiting_' 으로 시작하는 컬럼들은 ALTER TABLE 명령문을 실행했고, 현재 메타데이터 락을 대기하고 있는 세션과 관련된 정보를 보여준다.
  'blocking_'으로 시작하는 컬럼은 ALTER TABLE 명령문을 대기하게 만든 세션과 관련된 정보를 보여준다.
  'sql_'로 시작하는 컬럼엔 메타데이터 락을 점유한 세션에서 실행 중인 쿼리, 세션 자체를 종료시키는 쿼리 문이 표시된다.
  따라서, 필요한 경우 해당 쿼리들을 사용해 점유된 메타데이터 락을 강제로 해제할 수 있다.
    ALTER TABLE 명령으로 인해 대기가 발생하면 MySQL 서버에서 연쇄적으로 대기가 발생할 수 있으므로 ALTER TABLE 명령을 바로 취소하는 것이 좋다.
    취소 후 performance 스키마의 metadata_locks 테이블을 조회해서
    ALTER 작업 대상 테이블에 대한 메타데이터 락을 오랫종안 점유하고 있는 세션이 존재하는지 확인한다.
    ALTER 명령을 실행기 전 해당 테이블의 데이터를 조회해서 대기 상황이 발생할 가능성이 있는지 먼저 살펴보는 것도 좋은 방법이다.
 */
-- 현재 ALTER TABLE 작업을 대기하게 만든 세션에 대한 정보 확인 쿼리
SELECT *
FROM sys.schema_table_lock_waits
WHERE waiting_thread_id != blocking_thread_id;

### 18.7.20 - 데이터 락 대기 확인
-- 서로 다른 세션 간에 데이터 락 대기가 발생한 경우 대기가 발생한 데이터 락과 관련된 정보를 확인이 필요할 때
/**
  'wait_'으로 시작하는 컬럼들에는 대기가 시작된 시점과 경과 시간이 표시
  'locked_'로 시작하는 컬럼에는 락과 관련된 데이터베이스 객체와 락 종류 등의 내용이 표시
  'waiting_'으로 시작하는 컬럼에는 현재 데이터 락을 대기 중인 트랜잭션과 관련된 정보가 표시
  'blocking_'으로 시작하는 컬럼에는 락을 점유하고 있는 트랜잭션과 관련된 정보가 표시
  'sql_'로 시작하는 컬럼에는 데이터 락을 점유하고 있는 세션, 해당 세션에서 실행 중인 쿼리를 종료시키는 쿼리문이 표시
 */
SELECT * FROM sys.innodb_lock_waits;
select * FROM real_my_sql_80_book.employees LIMIT 10 FOR UPDATE;
select * FROM real_my_sql_80_book.employees WHERE SLEEP(10)=0 LIMIT 10 FOR UPDATE;
