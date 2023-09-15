## 18.2 - Performance 스키마 구성
-- Performance 스키마에는 100여 개의 테이블이 존재하며, 크게 '스키마 설정 관련 테이블', '스키마가 수집한 데이터'로 분류된다.

### 18.2.1 - Setup 테이블
/**
  Setup 테이블에는 Performance 스키마의 데이터 수집 및 저장과 관련된 설정 정보가 저장되어 있다.
  이 테이블을 통해 Performance 스키마의 설정을 동적으로 변경할 수 있다.

    - setup_actors
        Performance 스키마가 모니터링하며 데이터를 수집할 대상 유저 목록이 저장

    - setup_consumers
        Performance 스키마가 얼마나 상세한 수준으로 데이터를 수집하고 저장할 것인지 결정하는 데이터 저장 레벨이 설정이 저장

    - setup_instruments
        Performance 스키마가 데이터를 수집할 수 있는 MySQL 내부 객체들의 클래스 목록과 클래스별 데이터 수집 여부 설정이 저장

    - seup_objects
        Performance 스키마가 데이터를 수집할 대상 데이터베이스 객체(프로시저, 테이블, 등과 같은) 목록이 저장

    - setup_threads
        Performance 스키마가 데이터를 수집할 수 있는 MySQL 내부 스레드들의 목록과 스레드별 데이터 수집 여부 설정이 저장
 */

### 18.2.2 - Instance 테이블
/**
  Instance 테이블들은 Performance 스키마가 데이터를 수집하는 대상인 실체화된 객체들, 즉 인스턴스들에 대한 정보를 제공
  인스턴스 종류별로 테이블이 구분돼 있다.

    - cond_instances
        현재 MySQL 서버에서 동작 중인 스레드들이 대기하는 조건(Condition) 인스턴스들의 목록을 확인할 수 있다.
        조건은 스레드 간 동기화 처리와 관련해 특정 이벤트가 발생했음을 알리기 위해 사용되는 것으로,
        스레드들은 자신들이 기다리고 있는 조건이 참이 되면 작업을 재개한다.

    - file_instances
        현재 MySQL 서버가 열어서 사용 중인 파일들의 목록을 확인할 수 있다.
        사용하던 파일이 삭제되면 이 테이블에서도 데이터가 삭제된다.

    - mutex_instances
        현재 MySQL 서버에서 사용 중인 뮤텍스 인스턴스들의 목록을 확인할 수 있다.

    - relock_instances
        현재 MySQL 서버에서 사용 중인 읽기 및 쓰기 잠금 인스턴스의 목록을 확인할 수 있다.

    - socket_instances
        현재 MySQL 서버가 클라이언트의 요청을 대기하고 있는 소켓(Socket) 인스턴스들의 목록을 확인할 수 있다.
 */

### 18.2.3 - Connection 테이블
/**
  MySQL에서 생성된 커넥션들에 대한 통계 및 속성 정보를 제공한다.

    - accounts
        DB 계정명과 MySQL 서버로 연결한 클라이언트 호스트 단위로 커넥션 통계 정보를 확인할 수 있다.

    - hosts
        호스트별 커넥션 통계 정보를 확인할 수 있다.

    - users
        DB 계정명별 커넥션 통계 정보를 확인할 수 있다.

    - session account connect attrs
        현재 세션 및 현재 세션에서 MySOL에 접속하기 위해 사용한
        DB 계정과 동일한 계정으로 접속한 다른 세션들의 커넥션 속성 정보를 확인할수 있다.

    - session connect attrs
        MySQL어| 연결된 전체 세션들의 커넥션 속성 정보를 확인할수 있다.
 */

### 18.2.4 - Variable 테이블
/**
  MySQL 서버의 시스템 변수 및 사용자 정의 변수와 상태 변수들에 대한 정보를 제공한다.

    - global_variables
        전역 시스템 변수들에 대한 정보가 저장돼있다.

    - session_variables
        현재 세션에 대한 세션 범위의 시스템 변수들의 정보가 저장돼 있으며,
        현재 세션에서 설정한 값들을 확인할 수 있다.

    - variables_by_thread
        현재 MySQL에 연경돼 있는 전체 세션에 대한 세션 범위의 시스템 변수들의 정보가 저장돼 있다

    - persisted_variables
        SET PERSIST 또는 SET PERSIST_ONLY 구문을 통해 영구적으로 설정된 시스템 변수에 대한 정보가 저장돼 있다.
        psersisted_variables 테입르은 mysqld-auto.cnf 파일에 저장돼 있는 내용을 테이블 형태로 나타낸 겻으로,
        사용자가 SQL 문을 사용해 해당 파일의 내용을 수정할 수 있게 한다.

    - variables_info
        전체 시스템 변수에 대해 설정 가능한 값 범위 및 가장 최근의 변수의 값을 변경한 계정 정보 등이 저장돼 있다.

    - user_variables_by_thread
        현재 MySQL에 연결돼 있는 세션들에서 생성한 사용자 정의 변수들에 대한 정보(변수명 및 값)가 저장돼 있다.

    - global_status
        전역 상태 변수들에 대한 정보가 저장돼 있다

    - session_status
        현재 세션에 대한 세션 범위의 상태 변수들의 정보가 저장돼 있다.

    - status_by_thread
        현재 MySQL에 연결돼 있는 전체 세션들에 대한 세션 범위의 상태 변수들의 정보가 저장돼 있다.
        세션별로 구분될 수 있는 상태 변수만 저장된다.
 */
SELECT * FROM performance_schema.global_variables;
SELECT * FROM performance_schema.session_variables;
SELECT * FROM performance_schema.persisted_variables;

### 18.2.5 - Event 테이블
/**
  이벤트 테이블은 크게 Wait, STage, STatement, Transaction 이벤트 테이블로 구분돼 있으며,
  위 네 가지 이벤트들은 일반적으로 스레드에서 실행된 쿼리 처리와 관련된 이벤트로서 다음과 같은 계층 구조를 가진다.

  - Transaction Events
    - Statement Events
      - Stage Events
        - Wait Events
            - io, lock, sych ... 등

  각 이벤트는 세 가지 유형의 테이블을 가지고, 테이블명 후미에 해당 테이블이 속해있는 유형의 이름이 표시된다.
  유형으론 다음과 같다.
    - current
        스레드별로 가장 최신의 이벤트 1건만 저장되며, 스레드가 종료되면 해당 스레드의 이벤트 데이터는 바로 삭제된다.

    - history
        스레드별로 가장 최신의 이벤트가 지정된 최대 개수만큼 저장된다.
        스레드가 종료되면 해당 스르데의 이벤트 데이터는 바로 삭제되며, 계속 사용 중이면서 스레드별 최대 저장 개수를 넘은 경우
        이전 이벤트를 삭제하고 최근 이벤트를 새로 저장함으로써 최대 개수를 유지한다.

    - history_long
        전체 스레드에에 대한 최근 이벤트들을 모두 저장하며, 지정된 전체 최대 개수만큼 데이터가 저장된다.
        스레드가 종료되는 것과 관계없이 지정된 최대 개수만큼 이벤트 데이터를 가지고 있으며,
        저장된 이벤트 데이터가 전체 최대 저장 개수를 넘어가면 이전 이벤트들을 삭제하고 최근 이벤트들 새로 저장함으로써 최대 개수를 유지한다.

  이벤트 타입별로 데이터가 저장되는 테이블 목록은 다음과 같다.
    - Wait Event 테이블
        각 스레드에서 대기하고 있는 이벤트들에 대한 정보를 확인할 수 있다.
        일반적으로 잠금 경합 또는 I/O 작업 등으로 인해 스레드가 대기한다.

        ㅁ events_waits_current
        ㅁ events_waits_hisotry
        ㅁ events_waits_history_long

    - Stage Event 테이블
        각 스레드에서 실행한 쿼리들의 처리 단계에 대한 정보를 확인할 수 있다.
        이를 통해 실행된 쿼리가 구문 분석, 테이블 열기, 정렬 등과 같은 쿼리 처리 단계 중
        현재 어느 단계를 수행하고 있는지와 처리 달계별 소요 시간 등을 알 수 있다.

        ㅁ events_stages_current
        ㅁ events_stages_history
        ㅁ events_stages_history_long

    - Statement Event 테이블
        각 스레드에서 실행한 쿼리들에 대한 정보를 확인할 수 있다.
        실행된 쿼리와 쿼리에서 반화노딘 레코드 수, 인덱스 사용 유무 및 처리된 방식 등의 다양한 정보를 함꼐 확인할 수 있다.

        ㅁ events_statements_current
        ㅁ events_statements_history
        ㅁ events_statements_history_long

    - Transaction Event 테이블
        각 스레드에서 실행한 트랜잭션에 대한 정보를 확인할 수 있다.
        트랜잭션별로 트랜잭션 종류와 현재 상태, 격리 수준 등을 알 수 있다.

        ㅁ events_transactions_current
        ㅁ events_transactions_history
        ㅁ events_transactions_history_long

  위에서 얘기했듯이 Wait, STage, Statement, Transaction 이벤트들은 계층 구조를 가지므로
  각 이벤트 테이블에는 상위 계층에 대한 정보가 저장되는 컬럼들이 존재한다.
  테이블에서 'NESTING_EVENT_' 로 시작하는 컬럼들이 이에 해당한다.
 */

### 18.2.6 - Summary 테이블
/**
  Summary 테이블들은 Performance 스키마가 수집한 이벤트들을 '특정 기준별로 집계한 후' 요약한 정보를 제공한다.
  이벤트 타입별로, 집계 기준별로 다양한 Summary 테이블들이 존재한다.
    - events_waits_summary_by_account_by_event_name
        DB 계정별, 이벤트 클래스별로 분류해서 집계한 Wait 이벤트 통계 정보를 보여준다

    - events_waits_summary_by_host_by_event_name
        호스트별, 이벤트 클래스별로 분류해서 집계한 Wait 이벤트 통계 정보를 보여준다.

    - events_waits_summary_by_instance
        이벤트 인스턴스별로 분류해서 집계한 Wait 이벤트 통계 정보를 보여준다

    - events_waits_summary_by_thread_by_envent_name
        스레드별, 이벤트 클래스별로 분류해서 집계한 Wait 이벤트 통계 정보를 보여준다.

    - events_waits_summary_by_user_by_event_name
        DB 계정명별, 이벤트 클래스별로 분류해서 집계한 Wait 이벤트 통계 정보를 보여준다.

    - events_waits_summary_global_by_envent_name
        이벤트 클래스별로 분류해서 집계한 Wait 이벤트 통계 정보를 보여준다.

    - events_stages_summary_by_account_by_event_name
        DB 계정별, 이벤트 클래스별로 분류해서 집계한 Stage 이벤트 통계 정보를 보여준다.

    - events_stages_summary_by_host_by_event_name
        호스트별, 이벤트 클래스별로 분류해서 집계한 Stage 이벤트 통계 정보를 보여준다.

    - events_stages_summary_by_thread_by_event_name
        스레드별, 이벤트 클래스별로 분류해서 집계한 Stage 이벤트 통계 정보를 보여준다.

    - events_stages_summary_by_user_by_event_name
        DB 계정명별, 이벤트 클래스별로 분류해서 집계한 Stage 이벤트 통계 정보를 보여준다.

    - events_stages_summary_global_by_event_name
        이벤트 클래스별로 분류해서 집계한 Stage 이벤트 통계 정보를 보여준다.

    -  events_statements_histogram_by_digest
        스키마별, 쿼리 다이제트별로 쿼리 실행 시간에 대한 히스토그램 정보를 보여준다.

    - events_statements_histogram_global
        MySQL 서버에서 실행된 전체 쿼리들에 대한 실행 시간 히스토그램 정보를 보여준다.

    - events_statements_summary_by_account_by_event_name
        DB 계정별, 이벤트 클래스별로 분류해서 집계한 Statement 이벤트통계 정보를 보여준다.

    - events_statements_summary_by_digest
        스키마별, 쿼리 다이제스트별로 분류해서 집계한 Statement 이벤트 통계 정보를 보여준다.

    - events_statements_summary_by_host_by_event_name
        호스트별, 이벤트 클래스별로분류해서 집계한 Statement 이벤트 통계 정보를 보여준다.

    - events_statements_summary_by_program
        스토어드 프로시저 또는 함수, 트리거, 이벤트 등과 같은 스토어드 프로그램별로 분류해서 집계한 Statement 이벤트 통계 정보를 보여준다.

    - events_statements_summary_by_thread_by_event_name
        스레드별. 이벤트 클래스별로 분류해서 집계한 Statement 이벤트통계 정보를 보여준다.

    - events_statements_summary_by_user_by_event_name
        DB 계정명별, 이벤트 클래스별로 분류해서 집계한 Statement 이벤트통계 정보를 보여준다.

    - events_statements_summary_global_by_event_name
        이벤트 클래스별로 분류해서 집계한 Statement 이벤트 통계 정보를 보여준다.

    - prepared_statements_instances
        생성된 프리페어 스테이트먼트 인스턴스 목록을 보여준다.

    - events_transactions_summary_by_account_by_event_name
        DB 계정별, 이벤트 클래스별로 분류해서 집계한 Transaction 이벤트통계 정보를 보여준다.

    - events_transactions_summary_by_host_by_event_name
        호스트별, 이벤트 클래스별로 분류해서 집계한 Transaction 이벤트 통계 정보를 보여준다.

    - events_transactions_summary_by_thread_by_event_name
        스레드별, 이벤트 클래스별로 분류해서 집계한 Transaction 이벤트 통계 정보를 보여준다.

    - events_transactions_summary_by_user_by_event_name
        DB 계정명별, 이벤트클래스별로 분류해서 집계한 Transaction 이벤트 통계 정보를 보여준다.

    - events_transactions_summary_global_by_event_name
        이벤트 클래스별로 분류해서 집계한 Transaction 이벤트 통계 정보를 보여준다.

    - objects_summary_global_by_type
        데이터베이스 객체별로 분류해서 집계한 대기 시간 통계 정보를 보여준다.

    - file_summary_by_event_name
        이벤트 클래스별로 분류해서 집계한 파일 1/0 작업 관련 소요 시간 통계 정보를 보여준다.

    - file_summary_by_instance
        이벤트 인스턴스별로 분류해서 집계한 파일 1/0 작엽 관련 소요 시간 통계 정보를 보여준다.

    - table_io_waits_summary_by_index_usage
        인텍스별로 분류해서 집계한 1/0 작업 관련 소요 시간 통계 정보를 보여준다.

    - table_io_waits_summary_by_table
        테이블별로 분류해서 집계한 1/0 작업 관련 소요 시간 통계 정보를 보여준다.

    - table_lock_waits_summary_by_table
        테이블별로 분류해서 집계한 잠금 종류별 대기 시간 통계 정보를 보여준다

    - socket_summary_by_event_name
        이벤트 클래스별로 분류해서 집계한 소켓 1/0 작 관련 통계 정보를 보여준다

    - socket summary by instance
        이벤트 인스턴스별로 분류해서 집계한 소켓 1/0 작업 관련 통계 정보를 보여준다.

    - memory_summary_by_account_by_event_name
        DB 계정별, 이벤트 클래스별로 분류해서 집계한 메모리 할당 및 해제에 대한통계 정보를 보여준다.

    - memory_summary_by_host_by_event name
        호스트별, 이벤트 클래스별로 분류해서 집계한 메모리 할당 및 해제에 대한 통계 정보를 보여준다.

    - memory_summary_by_thread_by_event_name
        스레드별, 이벤트 클래스별로 분류해서 집계한 메모리 할당 및 해제에 대한통계 정보를 보여준다.

    - memory_summary_by_user_by_event_name
        DB 계정명별, 이벤트 클래스별로 분류해서 집계한 메모리 할당 및 해제에 대한통계 정보를 보여준다.

    - memory_summary_global_by_event_name
        이벤트 클래스별로 분류해서 집계한 메모리 할당 및 해제에 대한 통계 정보를 보여준다.

    - events_errors_summary_by_account_by_error
        DB 계정별, 에러 코드별로 분류해서 집계한 MySQL 에러 발생 및 처리에 대한 통계 정보를 보여준다.

    - events_errors_summary_by_host_by_error
        호스트별, 에러 코드별로 분류해서 집계한 MySQL 에러 발생 및 처리에 대한 통계 정보를 보여준다.

    - events_errors_summary_by_thread_by_error
        스레드별, 에러 코드별로 분류해서 집계한 MySQL 에러 발생 및 처리에 대한 통계 정보를 보여준다.

    - events_errors_summary_by_user_by_error
        DB 계정명별, 에러 코드별로 분류해서 집계한 MySQL 에러 발생 및 처리에 대한 통계 정보를 보여준다

    - events_errors summary_global_by_error
        에러 코드별로 분류해서 집계한 MySQL 에러 발생 및 처리에 대한 통계 정보를 보여준다.

    - status_by_account
        DB 계정별 상태 변숫값을 보여준다

    - status_by_host
        호스트별 상태 변숫값을보여준다.

    - status_by_user
        DB 계정영별 상태 변숫값을 보여준다
 */
desc performance_schema.events_waits_summary_global_by_event_name;
desc performance_schema.memory_summary_by_account_by_event_name;
select * from performance_schema.memory_summary_by_account_by_event_name;
select * from performance_schema.memory_summary_by_thread_by_event_name;

SET @stmt = 'SELECT * FROM real_my_sql_80_book.employees LIMIT 1';
select @stmt;
# select statement_digest(@stmt); # 해시한 값으로 나타내기
# select statement_digest_text(@stmt); # 해시된 값을 문자로 변환하기

### 18.2.7 - Lock 테이블
/**
  MySQL에서 발생한 잠금과 관련된 정보를 제공한다.

    - data_locks
        현재 잠금이 점유됐거나 잠금이 요청된 상태에 있는 데이터 관련 락(레코드, 갭 락)에 대한 정보를 보여준다.

    - data_lock_waits
        이미 점유된 데이터 락과 이로 인해 잠금 요청이 차단된 데이터 락 간의 관계 정보를 보여준다.

    - metadata_locks
        현재 잠금이 점유된 메타데이터 락들에 대한 정보를 보여준다.

    - table_handles
        현재 잠금이 점유된 테이블 락들에 대한 정보를 보여준다.
 */

### 18.2.8 - Replication 테이블
/**
  Replication 테이블에서는 "SHOW [REPLICA | SLAVE] STATUS" 명령문에서 제공하는 것보다 더 상세한 복제 관련 정보를 제공한다.

    - replication_connection_configuration
        소스 서버로의 복제 연결 설정 정보가 저장돼 있다.

    - replication_connection_status
        소스 서버에 대한 복제 연결의 현재 상태 정보를 보여준다.

    - replication_asynchronous_connection_failover
        비동기 복제 연결 장애 조치 매커니즘에서 사용될 소스 서버 목록이 저장된다.

    - replication_applier_configuration
        레플리카 서버의 레플리케이션 어플라이어 스레드(SQL 스레드)에 설정된 정보를 보여준다.

    - replication_applier_status
        레플리케이션 어플라이어 스레드의 상태 정보를 보여준다.

    - replication_applier_status_by_coordinator
        레플리케이션 코디네이터 스레드(Replication Coordinator Thread)의 상태 정보를 보여준다.
        복제가 멀티 스레드 복제로 설정되지 않은 경우에는 테이블은 비어 있다.

    - replicaion_applier_status_by_worker
        레플리케이션 워커 스레드(Replication Worker Thread)의 상태 정보를 보여준다.

    - replication_applier_filters
        특정 복제 채널에 설정된 복제 필터에 대한 정보를 보여준다.

    - replication_applier_global_filters
        모든 복제 채널에 적용되는 전역 복제 필터에 대한 정보를 보여준다.

    - replication_group_members
        그룹 복제를 구성하는 멤버들에 대한 네트워크 및 상태 정보를 보여준다.

    - replication_group_member_stats
        각 그룹 복제 멈버의 트랜잭션 처리 통계 정보 등을 보여준다.

    - binary_log_transaction_compression_stats
        바이너리 로그 및 릴레이 ㅇ로그에 저장되는 트랜잭션의 압축에 대한 통계 정보를 보여준다.
        이 테이블은 MySQL 서버에서 바이너리 로그가 활성화돼 있고,
        binlog_transaction_compression 시스템 변수가 ON으로 설정된 경우에만 데이터가 저장된다.
 */

### 18.2.9 - Clone 테이블
/**
  Clone 테이블은 Clone 플러그인을 통해 수행되는 복제 작업에 대한 정보를 제공한다.
  따라서, Clone 플러그인을 설치하면 Clone 테이블이 자동으로 생성되고, 플러그인이 삭제되면 함께 제거된다.

    - clone_status
        현재 또는 마지막으로 실행된 클론 작업에 대한 '상태 정보'를 보여준다.
    - clone_progress
        현재 또는 마지막으로 실행된 클론 작업에 대한 '진행 정보'를 보여준다.
 */

### 18.2.10 - 기타 테이블
/**
  앞서 분류된 범주들에 속하지 않는 테이블들을 의미하며, 다음과 같은 테이블들이 존재한다.

    - error_log
        MySQL 에러 로그 파일의 내용이 저장돼 있다.

    - host_cache
        MySQL의 호스트 캐시 정보가 저장돼 있다.

    - keyring_keys
        MySQL의 Keyring 플러그인에서 사용되는 키에 대한 정보가 저장돼 있다.

    - log_status
        MySQL 서버 로그 파일들의 포지션 정보가 저장돼 있다. (온라인 백업 시 활용 가능)

    - performance_timers
        Performance 스키마에서 사용 가능한 이벤트 타이머들과 해당 특성에 대한 정보가 저장돼 있다.
        관련된 정보가 모두 NULL 값으로 표시되는 타이머는 현재 MySQL이 동작 중인 서버에서는 지원하지 않음을 의미한다.

    - processlist
        MySQL 서버에 연결된 세션 목록과 각 세션의 현재 상태, 세션에서 실행 중인 쿼리 정보가 저장돼 있다.
        processlist 테이블에서 보여지는 데이터는 SHOW PROCESSLIST 명령문을 실행하거나
        information_schema 데이터베이스의 PROCESSLIST 테이블을 조회해서 얻은 결과와 동일하다.

    - threads
        MySQL 서버 내부의 백그라운드 스레드 및 클라이언트 연결에 해당하는 포그라운드 스레드들에 대한 정보가 저장돼 있다.
        스레드별로 모니터링 및 과거 이벤트 데이터 보관 설정 여부도 확인할 수 있다.

    - tls_channel_status
        MySQL 연결 인터페이스별 TLS(SSL) 속성 정보가 저장된다.

    - user_defined_functions
        컴포넌트나 플러그인에 의해 자동으로 등록됐거나 CREATE FUNCTION 명령문에 의해 생성된 사용자 정의 함수들에 대한 정보가 저장된다.
 */
