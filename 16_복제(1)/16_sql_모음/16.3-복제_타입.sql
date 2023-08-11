## 16.3 - 복제 타입
-- MySQL의 복제는 소스 서버의 바이너리 로그에 기록된 변경 내역(바이너리 로그 이벤트)들을 식별하는 방식에 따라 두 가지로 나뉘게 된다.
/**
  1. 바이너리 로그 파일 위치 기반 복제(Binary Log FIle Position Based Replication)
  2. 글로벌 트랜잭션 ID 기반 복제(Global Transaction Identifiers Based Replication)
 */

### 16.3.1 - 바이너리 로그 파일 위치 기반 복제(Binary Log FIle Position Based Replication)
/**
  바이너리 로그 파일 위치 기반 복제는 MySQL에 복제 기능이 처음 도입됐을 때부터 제공된 방식으로,
  레플리카 서버에서 소스 서버의 바이너리 로그 파일명과 파일 내에서의 위치(Offset 또는 Position)로 개별 바이너리 로그 이벤트를 식별해서 복제가 진행되는 형태다.

  바이너리 로그 파일 위치 기반 복제에서는 이벤트 하나하나를 소스 서버의 바이너리 로그 파일명과 파일 내에서의 위치 값(File Offset)의 조합으로 식별한다.
  레플리카 서버에서는 각 이벤트들을 식별하고 자신의 적용 내역을 추적함으로써 복제를 일시적으로 중단할 수 있으며,
  재개할 때도 자신이 마지막으로 적용했던 이벤트 이후의 이벤트들부터 다시 읽어올 수 있다.

  바이너리 로그 파일 위치 기반 복제에서 중요한 부분은 바로 "복제에 참여한 MySQL 서버들이 모두 고유한 server_id 값"을 가지고 있어야 한다.
  바이너리 로그에는 각 이벤트별로 이 이벤트가 최초로 발생한 MySQL 서버를 식별하기 위해 부가적인 정보도 함께 저장되는데, 이때 MySQL 서버 id 값이 저장된다.
     - 사용자가 MySQL 서버마다 원하는 값으로 설정할 수 있으며 기본값은 1이다.
  이때, 바이너리 로그 파일에 기록된 이벤트가 레플리카 서버에 설정된 server_id 값과 동일한 server_id 값을 가지는 경우
  레플리카 서버에서는 해당 이벤트를 적용하지 않고 무시하게 된다. 자신의 서버에서 발생한 이벤트로 간주해서 적용하지 않기 때문이다.
  이러한 부분을 제대로 인지하고 사용하지 않으면 복제가 의도한 방향과는 다르게 동작할 수 있다.
  그래서 바이너리 로그 파일 위치 기반으로 복제를 구축할 때 복제의 구성원이 되는 모든 MySQL 서버가 고유한 server_id 값을 갖도록 설정해야 한다.
 */
SELECT @@server_id; -- 1

#### 16.3.1.1 - 바이너리 로그 파일 위치 기반의 복제 구축
-- MySQL 서버 간에 복제를 설정할 때는 각 서버에 데이터가 이미 존재하는지 여부와 복제를 어떻게 활용할 것인지 등에 따라 복제 설정 과정 및 구축 방법이 달라진다.
-- 한 대로 구성해서 사용하던 MySQL 서버에 새로운 레플리카 서버를 바이너리 로그 파일 위치 기반의 복제로 연결하는 과정을 살펴보자.

##### 16.3.1.1.1 - 설정 준비
/**
  MySQL 복제를 사용하려면 기본적으로 소스 서버에서 반드시 바이너리 로그가 활성화돼 있어야 하며,
  바이너리 로그 파일 위치 기반의 복제 설정을 위해서는 앞서 언급했던 것처럼 복제 구성원이 되는 각 MySQL 서버가 고유한 server_id 값을 가져야 한다.
  8.0에서는 바이너리 로그가 기본적으로 활성화 되어 있고, 서버 시작 시 데이터 디렉터리 밑에 "binlog"라는 이름으로 로그 파일이 자동으로 생성된다.
  결론적으로 소스 서버와 레플리카 서버에서 server_id 값만 적절하게 설정해도 복제는 가능하다.
  필요에 따라 바이너리 로그 동기화 방식이나 바이너리 로그를 캐시하기 위한 메모리 크기, 바이너리 로그 파일 크기, 보관 주기 등도 지정할 수 있다.
 */
/**
  ## 소스 서버 설정
  [mysqld]
  server_id=1
  log_bin=/binary-log-dir/path/binary-log-name
  sync_binlog=1
  binlog_cache_size=5M
  max_binlog_size=512M
  binlog_expire_logs_seconds=1209600
  소스 서버에서 바이너리 로그가 정상적으로 기록되고 있는지는 다음과 같이 소스 서버에 로그인해서 SHOW MASTER STATUS라는 명령을 실행해보면 된다.

  ## 레플리카 서버 설정
  [mysqld]
  server_id=2
  replay_log=relay-log-dir-path/relay-log-name
  relay_log_purge=ON
  read_only
  log_slave_updates
 */

SELECT @@log_bin;
show BINARY LOGS ;
show MASTER STATUS ;

##### 16.3.1.1.2 - 복제 계정 준비
/**
  레플리카 서버가 소스 서버로부터 바이너리 로그를 가져오려면 소스 서버에 접속해야 하므로 접속 시 사용할 DB 계정이 필요하다.
  이때 레플리카 서버가 사용할 계정을 복제용 계정이라고 한다.
  복제를 위해 특별히 새로운 계정을 만들 필요 없이 기존의 사용 중인 계정에 복제 관련 권한을 추가로 부여해도 되지만,
    - 복제에서 사용되는 계정의 비밀번호는 레플리카 서버의 커넥션과 메타데이터에 평문으로 저장되므로
    - 보안 측면을 고려해서 복제에 사용되는 권한만 주어진 별도의 계정을 생성해 사용하는 것이 좋다.

  복제용 계정은 복제를 시작하기 전 소스 서버에 미리 준비돼 있어야 하며, 이 계정은 반드시 "REPLICATION SLAVE" 권한을 가지고 있어야 한다.
 */
CREATE USER 'repl_user'@'%' IDENTIFIED BY 'repl_user_password';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
-- 여기선 복제 계정의 호스트 제한을 "%"로 설정했지만 보안을 위해서 꼭 필요한 IP 대역에서만 복제 연결이 가능하도록 제한하는 것이 좋다.

##### 16.3.1.1.3 - 데이터 복사
/**
  소스 서버의 데이터를 레플리카 서버로 가져와서 적재해야 하는데, MySQL 엔터프라이즈 백업이다 mysqldump 등과 같은 툴을 이용하면 된다.
  일반적으로 데이터가 크지 않다면 mysqldump를 사용하면 된다. 덤프 후 레플리카 서버로 가져와서 적재하면 된다.

  mysqldump를 사용해 소스 서버의 데이터를 덤프할 때는 "--single-transaction"과 "--master-data"라는 두 옵션을 반드시 사용해야 한다.
  "--single-transaction" 옵션은 데이터를 덤프할 때 하나의 트랜잭션을 사용해 덤프가 진행되게 해서
    mysqldump가 테이블이나 레코드에 잠금을 걸지 않고 InnoDB 테이블들에 대해 일관된 데이터를 덤프받을 수 있게 한다.

  "--master-data" 옵션은 덤프 시작 시점의 소스 서버의 바이너리 로그 파일명과 위치 정보를 포함하는
    복제 설정 구문(CHANGE REPLICATION SOURCE TO)이 덤프 파일 헤더에 기록될 수 있게 하는 옵션으로, 복제 연결을 위해 반드시 필요한 옵션이다.
  --master-data 옵션은 1 또는 2로 설정할 수 있으며,
  1은 덤프 파일 내의 복제 설정 구문이 모두 실행 가능한 형태로 기록되고,
  2는 해당 구문이 주석으로 처리되어 참조만 할 수 있는 형태로 기록된다.

리눅스에서 덤프 하는 범
linux> mysqldump -u root -p --single-transaction --master-data=2 \
      --opt --routines --triggers --hex-blob --all-databases > source_data.sql

데이터 덤프가 완료되면 source_data.sql 파일을 레플리카 서버로 옮겨 데이터를 적재해야 되는데 적재하는 두 가지 방법이 있다.
    1. MySQL 서버에 직접 접속해 데이터 적재 명령을 실행
        mysql> SOURCE /tmp/master_data.sql
    2. MySQL 서버에 로그인하지 않고 데이터 적재 명령을 실행 (아래 두 명령어 중 사용하고 싶은걸 사용하면 된다.)
        - linux> mysql -u root -p < /tmp/source_data.sql
        - linux> cat /tmp/source_data.sql | mysql -u root -p

**** 주의 사항 *****
  만약 mysqldump에 지정된 --master-data 옵션으로 소스 서버에 "FLUSH TABLES WITH READ LOCK" 명령이 실행되기 전에
  MySQL 서버에 이미 장시간 실행 중인 쿼리가 있다면 글로벌 락 명령어가
  실행 중인 쿼리에서 참조하고 있는 테이블들에 대한 잠금을 획득할 수 없어 완료되지 못하고 대기하게 된다.
  이처럼 글로벌 락 명령어가 대기하는 상황이 발생하면 그 뒤로 유입되는 다른 쿼리들도 연달아 대기해서 쿼리가 실행되지 못하고 적체될 수 있다.
  이렇게 되면 서비스에 문제 될 수 있으므로 장시간 실행 중인 쿼리가 있는지 미리 확ㅇ하는 것이 좋다.
  똑같이 덤프 후에도 대기 현상이 발생하고 있는지 한번 더 확인하는 것이 좋다.
 */

##### 16.3.1.1.4 - 복제 시작
/**
  복제를 설정하는 명령은 CHANGE REPLICATION SOURCE TO(또는 CHANGE MASTER TO) 명령이다.
  mysqldump로 백업 받은 파일의 헤더 부분에서 해당 명령어를 참조할 수 있다.

  백업받은 파일은 크기가 크기 대문에 vi 같은 텍스트 편집기 보다는 less 같은 페이지 단위의 뷰어를 이용해 파일을 여는 것이 좋다. (취향)
  책에선 less 파일 편집기로 대략 24번째 줄에 있는 MASTER_LOG_FILE 부분을 복사하는데 이 부분은 쿼리로 확인할 수 있다.
    - SHOW MASTER STATUS 명령으로 MASTER_LOG_FILE 컬럼의 값과 MASTER_LOG_POS 컬럼의 값만 기억해두면 된다.
  이제 레플리카 서버에서 다음 명령을 실행하면 된다.
 */
-- 8.0.23 이상 버전
CHANGE REPLICATION SOURCE TO
    SOURCE_HOST='source_server_host',
    SOURCE_PORT=3306,
    SOURCE_USER='repl_user',
    SOURCE_PASSWORD='repl_user_password',
    SOURCE_LOG_FILE='위에서_기억한_LOG_FILE_컬럼의_값',
    SOURCE_LOG_POS=위에서_기억한_LOG_POS_컬럼의_값,
    GET_SOURCE_PUBLIC_KEY=1;
-- 8.0.23 이하 버전
CHANGE REPLICATION SOURCE TO
    MASTER_HOST='source_server_host',
    MASTER_PORT=3306,
    MASTER_USER='repl_user',
    MASTER_PASSWORD='repl_user_password',
    MASTER_LOG_FILE='위에서_기억한_LOG_FILE_컬럼의_값',
    MASTER_LOG_POS=위에서_기억한_LOG_POS_컬럼의_값,
    GET_MASTER_PUBLIC_KEY=1;
-- 위 명령을 레플리카 서버 MySQL에 로그인한 뒤 SHOW REPLICA STATUS 명령을 실행해 보면 복제 관련 정보가 레플리카 MySQL에 등록돼 있는 것을 확인할 수 있다.

#### 16.3.1.2 - 바이너리 로그 파일 위치 기반의 복제에서 트랜잭션 건너뛰기
/**
  복제로 구성돼 있는 MySQL 서버들을 운영하다 보면 종종 레플리카 서버에서 소스 서버로부터 넘어온 트랜잭션이
  제대로 실행되지 못하고 에러가 발생해 복제가 멈추기도 한다.
  대표적인 에러로 '중복 키 에러'가 있는데, 문제가 간단하고 해당 트랜잭션을 건너뛰어도 상관 없다면 다음과 같이 진행해도 된다.
  바이너리 로그 위치 기반 복제에서는 sql_slave_skip_counter 시스템 변수를 이용해 문제되는 트랜잭션을 건너 뛸 수 있다.

  sql_slave_skip_counter 변수의 값을 1로 지정해 레플리케이션 SQL 스레드를 재시작하면
  레플리카 서버는 에러가 발생한 INSERT 쿼리를 건너뛰고 정상적으로 복제를 재개하게 된다.
  (1개만 건너뛴다는거 같기도 하고..?)

  sql_slave_skip_counter 변수가 1로 설정되면 MySQL 서버는 DML 쿼리 문장 하나를 무시하는 것이 아니라,
  현재 이벤트를 포함한 이벤트 그룹을 무시한다. 즉, 트랜잭션 단위로 무시한다.
  만약, 트랜잭션을 지원하지 않는 테이블은 DML 문장 하나하나가 이벤트 그룹이 되고,
  중복 키 에러가 발생한 INSERT 문이 트랜재셕으로 하나의 이벤트 그룹안에 포함되어있다면 같은 이벤트 그룹에 속한 DML 쿼리들은 모두 무시된다.
 */


### 16.3.2 - 글로벌 트랜잭션 아이디(GTID) 기반 복제
/**
  5.5 버전까지는 복제를 설정할 때 바이너리 로그 파일 위치 기반 복제 방식만 가능했다.
  이 방식의 문제는 이 같은 식별이 바이너리 로그 파일이 저장돼 있는 소스 서버에서만 유효하다는 것이다.
  하지만, 동일한 이벤트가 레플리카 서버에서도 동일한 파일명의 동일한 위치에 저장된다는 보장이 없다.
  한마디로 복제에 투입된 서버들마다 동일한 이벤트에 대해 서로 다른 식별 값을 갖게 되는 것이다.
  이렇게 복제를 구성하는 서버들이 서로 호환되지 않은 정보를 이용해 복제를 진행함으로써 복제의 토폴로지를 변경하는 작업은 때로 거의 불가능할 때도 많았다.
  복제 토폴로지 변경은 주로 복제에 참여한 서버들 중에서 일부 서버에 장애가 발생했을 때 필요한데,
  토폴로지 변경이 어렵다는 것은 그만큼 복제를 이용한 장애 복구(Failover)가 어렵다는 것을 의미한다.
  그래서 MHA나 MMM 그리고 Orchestrator와 같은 MySQL HA 솔루션들은 내부적으로 복잡한 바이너리 로그 파일 위치 계산을 수행하거나
  때로는 포기해 버리는 형태로 처리되기도 한다.

  그래서, 소스 서버에서 발생한 각 이벤트들이 복제에 참여한 모든 MySQL 서버들에서 동일한 고유 식별 값을 가지는 방식의 GTID 기반 복제가 생기게 되었다.
  이렇게하면 장애가 발생해도 좀 더 손쉽게 복제 토폴로지를 변경할 수 있으며, 장애 복구 시간도 줄어들 것이다.
  복제에 참여한 전체 MySQL 서버들에서 고유하도록 각 이벤트에 부여된 식별 값을 글로벌 트랜잭션 아이디(global Transaction Identifier, GTID)라고 하며,
  이를 기반으로 복제가 진행되는 형태를 "GTID 기반 복제"라 한다.

  GTID는 MySQL 5.6 버전에서 처음 도입됐으며 5.7 버전을 거쳐 8.0까지 계속 개선돼 오면서 그에 따른 신기능도 많이 추가 되었다.
 */

#### 16.3.2.1 - GTID의 필요성
/**
  자주 사용하는 복제 토폴로지를 예제로 살펴보자.

  바이너리 로그 파일 위치 기반 복제의 한계
  하나의 소스 서버(이하 A)에 두 개의 레플리카 서버(이하 B, C)가 연결돼 있는 복제 토폴로지가 구성되어 있는 상황
  이런 형태는 주로 레플리카 서버를 읽기 부하 분산 및 통계나 배치용으로 구성할 때 많이 사용한다.
    - B는 SELECT 쿼리 분산용, C는 배치나 통계용으로 사용

  소스 서버 A의 바이너리 로그 위치는 'binary-log.000002:320'이며
  레플리카 서버 B는 완전히 동기화되어 똑같이 'binary-log.000002:320' 바이너리 로그 이벤트까지 완전히 실행 완료된 상태인 상황이고,
  레플리카 서버 C는 조금 지연이 발생해서 소스 서버의 'binary-log.000002:120' 위치까지만 복제가 동기화된 상태라고 생각해보자.

  위와 같은 상황에서 소스 서버 A가 장애가 발생하면서 비정상적으로 종료됐다고 가정해보자.
  그러면 레플리카 서버 B와 C 중에서 하나를 소스 서버로 승격(Promotion)하고, A 서버로 연결돼 있던 클라이언트 커넥션을 새로 승격된 소스 서버로 교체한다.
  이때 당연히 완전히 동기화된 레플리카 B를 소스 서버로 승격하고 B 서버로 사용자 트래픽이 유입된다. 이때 C 서버를 SELECT 용으로 사용해야 하는데,
  C서버는 A 서버가 종료되어 복제를 최종 시점까지 동기화할 방법이 없다. 그로인해 SELECT 분산용으로 사용하지 못한다. (데이터의 정합성이 맞지않음)
  즉, B 서버의 과부하가 생기게 된다.

  완전히 불가능한 것은 아니다. 래플리카 B의 릴레이 로그가 지워지지 않고 남아있다면 B 서버의 릴레이 로그를 가져와서 필요한 부분만 실행하면 복구가 된다.
  하지만 일반적으로 MySQL 서버에서 릴레이 로그는 불필요한 시점에 자동으로 삭제되므로 이 방법은 상당히 제한적이다.
  물론 수동으로 직접 확인해보는 방법이 있을 수 있지만, 간단한 문제가 아닐뿐더러 자동화는 더 어렵다.

  위와 상황이랑 똑같은 상황에서 글로벌 트랜잭션 아이디를 이용해 복제가 구성된 상황
  소스 서버의 현재 GTID는 'af9995d80-939e-11eb-bb37-ba122a9a8ae3:120' 이고, 레플리카 B는 완전히 동기화
  레플리카 C는 'af9995d80-939e-11eb-bb37-ba122a9a8ae3:98' GTID까지만 동기화 된 상태

  이 상태에서 소스 서버 A에 장애가 발생하면
  B 서버를 C 서버의 소스 서버가 되도록 C 서버에서 'CHANGE REPLICATION SOURCE TO SOURCE_HOST='B', SOURCE_PORT=3306' 명령을 실행한다.
  이때 B 서버의 바이너리 로그 파일명이 무엇인지, 그리고 바이너리 로그 파일에서 어느 위치부터 이벤트를 가져와야 하는지 입력할 필요가 없다.
  A 서버에서 GTID가 '~~~~:98' 이었던 트랜잭션은 B 서버에서도 '~~~~:98'이고, C 서버에서도 '~~~~:98'이다.
  즉, C 서버는 B 서버로 복제를 다시 연결하고 B 서버의 '~~~~:98' 이후의 바이너리 로그 이벤트를 가져와 동기화하면 된다.
  이렇게 레플리카 서버 C가 새로운 소스 서버인 B와 동기화할 수 있도록 준비되면 클라이언트의 쿼리 요청을 B 서버와 C 서버로 나눠서 실행할 수 있다.

  GTID를 사용했을 때 장애 상황 뿐만 아니라 레플리카 서버 확장이나 축소 또는 통합과 같은 여러 요건들도 함꼐 해결될 수 있다.
 */

#### 16.3.2.2 - 글로벌 트랜잭션 아이디
/**
  바이너리 로그 파일에 기록된 이벤트들을 바이너리 로그 파일명과 파일 내의 위치로 식별하는 것은 물리적인 방식이라고 할 수 있다.
  반면, GTID는 노리적인 의미로서 물리적인 파일의 이름이나 위치와는 전혀 무관하게 생성된다. (OS에서 linux 파일 시스템 i-node 링크와 비슷한거 같기도..?)

  GTID는 커밋되어 바이너리 로그에 기록된 트랜잭션에 한에서만 할당된다.
  데이터 읽기만 수행하는 SELECT 쿼리나 sql_log_bin 설정이 비활성화돼 있는 상태에서 발생한 트랜잭션은 바이너리에 기록되지 않으므로 GTID가 할당되지 않는다.

  GTID는 소스 아이디와 트랜잭션 아이디 값의 조합으로 생성되는데, 두 값은 ':'으로 구분되어 표시된다.
  GTID = [source_id]:[transaction_id]
  소스 아이디는 트랜잭션이 발생된 소스 서버를 식별하기 위한 값으로 MySQL 서버의 server_uuid 시스템 변수 값을 사용하고,
  트랜잭션 아이디는 서버에서 커밋된 트랜잭션 순서대로 부여되는 값으로 1부터 1씩 증가하는 형태로 발급된다.
  server_uuid는 사용자가 설정하는 것이 아니라 MySQL 서버가 시작되면서 자동으로 부여되며,
  MySQL 서버가 시작할 때 데이터 디렉터리에 auto.cnf 라는 파일이 생성되는데 그 안에 저장되어 있는 server_uuid 값을 사용한다.
  auto.cnf 파일을 열어보면 "[auto]" 라는 섹션이 있고 그 하위에 현재 서버의 UUID 값이 표기돼 있다.
  아니면 다음 쿼리로 확인해 볼 수 있다.
  mysql> select @@server_uuid;
        +--------------------------------------+
        | @@server_uuid                        |
        +--------------------------------------+
        | 5a8afd66-13e5-11ee-be34-a4bfd0d6be38 |
        +--------------------------------------+
  아니면 select @@datadir; 명령을 통해 mysql 폴더 안에 auto.cnf 파일을 확인해 보면 된다.

  GTID는 각각의 값이 하나씩 개별로 보여지거나 연속된 값들인 경우 범위로 보여질 수 있으며, 이 밖에도 다양한 형태로 값이 보여질 수 있다.
  하나 이상의 GTID 값으로 구성돼 있는 것을 GTID 셋이라 한다.

  mysql.gtid_excuted 테이블은 현재 실행된 GTID 값을 저장하는 것 이외에 MySQL 서버 내부적으로 중요한 역할을 하는데,
  레플리카 서버에서 바이너리 로그가 비활성화돼 있는 상태에서 GTID 기반의 복제를 사용할 수 있게 하고,
  예기치 못한 문제로 바이너리 로그가 손실됐을 때 GTID 값이 보존될 수 있게 한다.

  gtid_exceuted 테이블은 5.7.5 버전에서 처음 도입됐으며 InnoDB 스토리지 엔진으로 설정돼 있다.
  8.0.17 이상의 버전을 사용하는 경우 매 트랜잭션이 커밋될 때마다 gtid_executed 테이블에도 GTID 값이 바로 저장된다.
 */

SELECT * FROM mysql.gtid_executed;

#### 16.3.2.3 - 글로벌 트랜잭션 아이디 기반의 복제 구축
/**
  GTID 복제를 사용하려면 우선 GTID를 활성화 시켜야 된다.
  반대로 GTID를 활성화 한 상태에서 바이너리 로그 파일 위치 기반 복제를 사용할 수도 있다.
  GTID가 비활성화돼 있다 하더라도 MySQL 서버의 재시작(서비스 중단) 없이 GTID를 활성화해서 GTID 기반의 복제를 적용할 수 있다. 16.3.2.5 에서 살펴보자.
  일단 기존에 이미 GTID를 사용하고 있는 소스 서버에서 레플리카 서버를 GTID 기반 복제로 연결하는 과정을 살펴보자.
 */

##### 16.3.2.3.1 - 설정 준비
/**
  위에서 얘기했듯이 GTID 기반의 복제를 사용하려면 복제에 참여한 모든 MySQL 서버들이 GTID가 활성화 돼 있어야 한다.
  또한, 각 서버의 server_id 및 server_uuid가 복제 그룹 내에서 고유해야 한다.

  ## 소스 서버 my.cnf
  [mysqld]
  gtid_mode=ON
  enforce_gtid_consistency=ON
  server_id=1111
  # log_bin=/binary-log-dir-path/binary-log-name --> 아니 왜 log_bin만 설정하며 에러가 나지..? 흠..

  ## 레플리카 서버 설정
  [mysqld]
  gtid_mode=ON
  enforce_gtid_consistency=ON
  server_id=2222
  relay_log=relay-log-dir-path/relay-log-name
  relay_log_purge=ON
  read_only
  log_slave_updates
 */

##### 16.3.2.3.2 - 복제 계정 준비
/**
  mysql> CREATE USER 'repl_user'@'%' IDENTIFIED BY '1234';
         Query OK, 0 rows affected (0.01 sec)

  mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
         Query OK, 0 rows affected (0.01 sec)
 */

##### 16.3.2.3.3 - 데이터 복사
/**
  mysqldump -uroot -p --single-transaction --master-data=2 --set-gtid-purged=ON \
    --opt --routines --triggers --hex-blob (--all-databases | dump하고싶은 databases 명) > source_data.sql
  여기서 --master-data 옵션은 deprecated 된다고 한다. --source-data를 사용하자.

  gtid_executed : MySQL 서버에서 실행되어 바이너리 로그 파일에 기록된 모든 트랜잭션들의 GTID 셋을 나타낸다.
  gtid_purged : 현재 MySQL 서버의 바이너리 로그 파일에 존재하지 않는 모든 트랜잭션들의 GTID 셋을 나타낸다.

  GTID 기반 복제에서 레플리카 서버는 gtid_executed 값을 기반으로 다음 복제 이벤트를 소스 서버로부터 가져온다.
  gtid_executed는 읽기 전용 변수로 사용자가 변경할 수 없으며, 사용자는 gtid_purged 변수 값만 설정할 수 있다.

  MySQL을 설치하고 처음 구동시키면 위 두 값은 비어있는데, 이때 사용자가 gtid_purged에 값을 설정하면 gtid_executed에도 자동으로 동일한 값이 설정
  따라서, 복제를 시작하기 위해 소스 서버에서 데이터 덤프가 시작된 시점의 소스 서버의 GTID 값을
  레플리카 서버의 gtid_purged 시스템 변수에 지정해 gtid_executed 시스템 변수에도 그 값이 설정되게 해야 한다.

  gtid_purged와 gtid_executed 시스템 변수를 동일한 값으로 변경하려면 두 시스템 변수 값이 비어있어야 한다.
  만약 이미 값이 저장된 경우네는 RESET MASTER; 명령을 수행해 두 변수의 값을 초기화 한 후 gtid_purged에 값을 설정하면 된다.
  단, RESET MASTER; 명령은 해당 서버가 가지고 있던 바이너리 로그 파일들이 모두 삭제되므로 바이너리 로그 파일이 필요한지 고려한 후 실행하자.

  이를 위해 mysqldump에서는 --set-gtid-purged라는 옵션을 제공하며, 이 옵션이 활성화되면 덤프가 시작된 GTID가 덤프 파일에 기록된다.
  또한, sql_log_bin 시스템 변수를 비활성화하는 구문도 함께 기록되는데,
            show variables like 'sql_log_bin';
            select @@sql_log_bin;
  이는 덤프 파일을 실행할 때 적용되는 트랜잭션들이 레플리카 서버에서 새로운 GTID를 발급받는 것을 방지한다.
                        (도커에선 ON으로 되어있다..?) (dump 파일엔 OFF로 되어있긴 하다.)

  사용자가 mysqldump를 실행할 때 명시적으로 이 옵션을 적지 않더라도 --set-gtid-purged 옵션은 AUTO 값으로 설정되어 동작한다.
  AUTO :
    덤프를 받는 서버에서 GTID가 활성화 되어 있으면 덤프를 시작하는 시점의 GTID 값 및 sql_log_bin 비활성화 구문을 덤프 파일에 기록하며,
    만약 GTID가 비활성상태인 서버의 경우 해당 내용들을 기록하지 않는다.
  OFF :
    덤프 시작 시점의 GTID 값 및 sql_log_bin 비활성화 구문을 덤프 파일에 기록하지 않는다.
  ON :
    덤프 시작 시점의 GTID 값 및 sql_log_bin 비활성화 구문을 덤프 파일에 기록한다.
    만약, GTID가 활성화돼 있지 않는 서버에서 이 옵션값을 사용하는 경우 에러가 발생한다.
  COMMENTED :
    8.0.17 이상 버전부터 사용할 수 있는 값으로, 이 값이 설정되면 ON 값으로 설정됐을 때와 동일하게 동작하되,
    덤프 시작 시점의 GTID 값이 주석으로 처리되어 기록된다. sql_log_bin 비활성화 구문은 주석으로 처리되지 않고
    다른 경우와 동일하게 바로 적용 가능한 형태로 기록된다.

  ***** 참고 *****
  만약 레플리카 서버 구축을 위해서가 아니라 단순히 다른 DB 서버로의 데이터 마이그레이션을 위해 mysqldump를 사용하는 경우에는
  mysqldump 실행 시 '--set-gtid-purged=OFF' 옵션을 명시하여 sql_log_bin 시스템 변수를 비활성화하는 구문이 덤프 파일에 기록되지 않도록 해야 한다.
 */
SET GLOBAL SUPER_READ_ONLY = OFF;
show variables like 'sql_log_bin';
select @@sql_log_bin;

##### 16.3.2.3.4 - 복제 시작
/**
  여기까지 레플리카 서버의 초기 데이터는 모두 준비되었는데, 소스 서버에서 백업을 실행했던 과거 시점의 데이터이며, 백업 이후 데이터들은 동기화가 안 되어 있다.

  CHANGE REPLICATION SOURCE TO
	SOURCE_HOST='mysql-gtid-master',
	SOURCE_USER='repl_user',
	SOURCE_PASSWORD='1234',
	SOURCE_AUTO_POSITION=1,
	GET_SOURCE_PUBLIC_KEY=1;
  위 명령어를 실행 후

  START REPLICA; 를 하면 동기화가 완료된다.
 */

#### 16.3.2.4 - 글로벌 트랜잭션 아이디 기반 복제에서 트랜잭션 건너뛰기
/**
  복제를 진행하던 중 에러가 발생했으면 STOP REPLICA; 를 통해 복제를 중단한 뒤,

  select * from performance_schema.replication_applier_status_by_worker\G
  을 통해 쿼리를 확인해 보고 사용 안 할거 같은 쿼리면 해당 트랜잭션을 레플리카 서버에서 빈 트랜잭션으로 채워놓은 다음
  바이너리 로그 스트림에 밀어넣으면 된다.

  mysql> stop replica;
         Query OK, 0 rows affected (0.00 sec)
  mysql> set gtid_next='18afeb7f-3802-11ee-9934-0242ac110003:8'; # performance_schema 또는 show replica status\G 에서 확인한 정보
         Query OK, 0 rows affected (0.00 sec)
  mysql> BEGIN; COMMIT;
         Query OK, 0 rows affected (0.00 sec)
         Query OK, 0 rows affected (0.00 sec)
  mysql> SET gtid_next='AUTOMATIC';
         Query OK, 0 rows affected (0.00 sec)
  mysql> start replica;
         Query OK, 0 rows affected (0.02 sec)
 */

select * from performance_schema.replication_applier_status_by_worker;
-- 또는
show SLAVE STATUS;
# 위 두 명령어를 통해 나오는 트랜잭션에러를 스킵하거나 수동으로 처리하면 된다.

#### 16.3.2.5 - Non-GTID 기반 복제에서 GTID 기반 복제로 온라인 변경
/**
  8.0에서는 서비스가 현재 동작하고 있는 상태에서 MySQL 서버가 GTID를 사용하거나 사용하지 않도록 온라인으로 전환할 수 있는 기능을 제공한다.
  이 기능을 통해 기존에 바이너리 로그 위치 기반의 복제를 GTID 기반의 복제로 변경할 수 있으며, 반대의 경우도 가능하다.
  온라인으로 전환되는 것이 5.7.6 버전부터인데, 전 버전에서는 소스 서버와 레플리 서버에서 MySQL을 재시작해야만 GTID 모드를 활성화, 비활성화 할 수 있었다.
  GTID 모드를 전환하는 작업은 간단하게 GTID 관련된 두 시스템 변수의 값만 순차적으로 변경하면 된다.
  먼저 이 두 시스템 변수에 대해 살펴보자.

  GTID 모드를 전환할 때 사용되는 시스템 변수는 enforce_gtid_consistency 와 gtid_mode 이다.
  이 두 변수 모두 MySQL 서버를 재시작하는 과정 없이 동적으로 값 변경이 가능하다.

  enforce_gtid_consistency :
    GTID 기반 복제에서 소스 서버와 레플리카 서버 간의 데이터 일관성을 해칠 수 있는 쿼리들이 MySQL 서버에서 실행되는 것을 허용할지 제어하는 변수이다.
      GITD를 사용하는 복제 환경에서는 다음과 같은 패턴의 쿼리들은 안전하지 않다.
        1. 트랜잭션을 지원하는 테이블과 지원하지 않는 테이블을 함께 변경하는 쿼리 혹은 트랜잭션
        2. CREATE TABLE ... SELECT ... 구문
        3. 트랜잭션 내에서 CREATE TEMPORARY TABLE, DROP TEMPORARY TABLE 구문
      여기 패턴들의 공통적인 특지은 소스 서버에서 레플리카 서버로 복제되어 적용될 때 '단일 트랜잭션으로 처리되지 않을 수'도 있다는 점이다.
         ****** 참고 ******
         * 8.0.13 버전부터는 서버의 바이너리 로그 포맷이 ROW 나 MIXED로 설정된 경우 트랜잭션 내에서 CREATE 또는 DROP TEMPORARY 구문 사용 가능
         * 8.0.21 버전부터는 Atomic DDL 기능을 지원하는 InnoDB 스토리지 엔진 테이블에 핸해 CREATE TABLE ... SELECT 구문을 사용할 수 있다
         *****************
    enforce_gtid_consistency 옵션을 통해 이러한 쿼리들의 실행 가능 여부를 제어할 수 있고, 설정할 수 있는 옵션으론 다음과 같다.
    OFF : GTID 일관성을 해칠 수 있는 쿼리들을 허용
    ON : GTID 일관성을 해칠 수 있는 쿼리들을 허용하지 않음
    WARN : GTID 일관성을 해칠 수 있는 쿼리들을 허용하지만 그러한 쿼리들이 실행될 때 경고 메시지가 발생

  gtid_mode :
    바이너리 로그에 트랜잭션들이 GTID 기반으로 로깅될 수 있는지 여부와 트랜잭션 유형별로 MySQL 서버에서 처리 가능 여부를 제어하는 변수
    바이너리 로그에 기록되는 트랜잭션 유형에는 익명(Anonymous) 트랜잭션과 GTID 트랜잭션이 있는데,
    익명 트랜잭션은 GTID가 부여되지 않은 트랜잭션으로 바이너리 로그 파일명과 위치로 식별되며,
    GTID 트랜잭션은 고유한 식별값인 GTID가 부여된 트랜잭션을 지칭한다.

  gtid_mode 시스템 변수에 지정할 수 있는 값은 다음과 같고, gtid_mode에 설정된 값에 따라
  MySQL 서버에서 직접 실행된 신규 트랜잭션 및 복제로 넘어온 트랜잭션에 대한 처리 방식이 달라지므로 아래를 확인해보자.

                    신규 트랜잭션으로 넘어올 때      복제된 트랜잭션으로 넘어올 때
    OFF             익명 트랜잭션으로 기록          익명 트랜잭셔만 처리 가능
    OFF_PERMISSIVE  익명 트랜잭션으로 기록          익명, GTID 모두 처리 가능
    ON_PERMISSIVE   GTID 트랜잭션으로 기록         익명, GTID 모두 처리 가능
    ON              GTID 트랜잭션으로 기록         GTID 트랜잭셔만 처리 가능

  위에 적혀진 값 순서를 기준으로 한 번에 한 단계씩만 변경할 수 있다.
  예를 들어 gtid_mode가 현재 OFF_PERMISSIVE로 설정돼 있는 경우 OFF 또는 ON_PERMISSIVE로 변경할 수는 있찌만 ON으로는 변경할 수 없다.
  gtid_mode를 변경할 때는 서버별로 순차적으로 값 변경이 이뤄지므로 변경하기 전에 서로 다른 값으로 설정된 MySQL 서버 사이의 호환성 여부를 확인해 보는 것이 좋다.
    안 되는 상황만 보면 3가지 상황이 있다.
      1. 소스 서버, 레플리카 서버가 각각 ON, OFF 이면 복제가 진행되지 않는다. (반대도 마찬가지)
      2. 소스 서버, 레플리카 서버가 각각 ON_PERMISSIVE, OFF 모드일 때 복제가 안된다.
      3; 소스 서버, 레플리카 서버가 각각 OFF_PERMISSIVE, ON 모드일 때 복제가 안된다.
 */

--  Non-GTID 기반으로 복제가 구성돼 있는 소스 서버와 레플리카 서버를 GTID 기반으로 변경하는 과정
--  1. 각 서버에서 enforce_gtid_consistency 시스템 변수 값을 WARN으로 변경
/*
 WARN 으로 설정된 경우에는 GTID 사용 시 일관성을 해치는 트랜잭션들을 감지해 에러 로그에 경고 메시지를 남긴다.
 따라서, 경고 메시지가 출력되는지 모니터링해야 되며, 경고 메시지가 있다면 이를 확인해 애플리케이션을 수정한 뒤 다음 단계로 넘어가야 된다.
 */
SET GLOBAL enforce_gtid_consistency = WARN;

-- 2. 각 서버에서 enforce_gtid_consistency 시스템 변수 값을 ON으로 변경
/*
 ON으로 변경되면 GTID를 사용했을 때 안전하게 처리될 수 있는 쿼리들만 실행할 수 있게 되므로 GTID 모드를 변경하기 전에 반드시 설정해야 한다.
 */
SET GLOBAL enforce_gtid_consistency = ON;

-- 3. 각 서버에서 gtid_mode 시스템 변수 값을 OFF_PERMISSIVE로 변경
/*
 gtid_mode가 OFF_PERMISSIVE로 변경되면 소스 서버에서 신규 트랜잭션은 여전히 바이너리 로그에 익명 트랜잭션으로 기록되지만,
 레플리카 서버에서는 복제 시 익명 트랜잭션과 GTID 트랜잭션 둘 다 처리할 수 있게 된다.
 소스 서버와 레플리카 서버 중 어느 서버를 먼저 변경하든 상관은 없으며,
 복제 토폴로지에 속하는 모든 서버들이 gtid_mode 를 꼭 OFF_PERMISSIVE로 설정되어 있어야 한다.
 */
SET GLOBAL gtid_mode = OFF_PERMISSIVE;

-- 4. 각 서버에서 gtid_mode 시스템 변수 값을 ON_PERMISSIVE로 변경
/*
 ON_PERMISSIVE로 변경되면 소스 서버에서 신규 트랜잭션이 바이너리 로그에 GTID 트랜잭션으로 기록되며,
 레플리카 서버에서는 복제 시 익명 트랜잭션과 GTID 트랜잭션 둘 다 처리할 수 있다.
 */
SET GLOBAL gtid_mode = ON_PERMISSIVE;

-- 5. 잔여 익명 트랜잭션 확인
/*
 복제 토폴로지에 속하는 모든 서버에서 위 명령어를 통해 잔여 익명 트랜잭션이 남아 있는지 확인한다.
 레플리카 서버에서는 이 상태 값이 0으로 보여졌다가 다시 0이 아닌 값으로 보여질 수 있는데, 0이 한번이라도 보여졌다면 다음 단계를 진행해도 된다.
 */
SHOW GLOBAL STATUS LIKE 'Ongoing_anonymous_transaction_count';

-- 6. 각 서버에서 gtid_mode 시스템 변수 값을 ON으로 변경
/*
 *** 참고 ***
 ON으로 변경하게 되면 GTID가 부여되지 않은 트랜잭션, 즉 익명 트랜잭션을 포함하는 바이너리 로그는 PIT 백업 및 복구와 같은 작업에서 사용할 수 없다.
 이런 부분이 신경쓰이면 gtid_mode를 ON으로 변경하기 전 백업이 수행되는 서버에서 FLUSH LOGS 명령을 실행한 후 명시적으로 다시 백업을 받아두는 것이 좋다.
 */
SET GLOBAL gtid_mode = ON;

-- 7. my.cnf 파일 변경
/*
 [mysqld]
 gtid_mode=ON
 enforce_gtid_consistency=ON

 재시작할 때도 해당 설정들이 유지될 수 있도록 my.cnf 파일에 설정값들을 넣는다.
 */

-- 8. GTID 기반 복제를 사용하도록 복제 설정을 변경
/*
 gtid_mode ON으로 변경하고 나면 익명 트랜잭션은 더이상 생성되지 않으므로 기존 바이너리 로그 위치 기반 복제도 GTID 기반의 복제로 변경한다.
 소스 서버를 제외한 레플리카 서버에서 다음 명령어를 실행하면 GTID 기반의 복제로 설정된다.
 */
STOP REPLICA;
CHANGE REPLICATION SOURCE TO SOURCE_AUTO_POSITION=1;
START REPLICA;
-- GTID를 비활성화 하는 작업은 위의 작업들을 역순으로 진행하면 된다.

#### 16.3.2.6 - GTID 기반 복제 제약 사항
/**
  - GTID가 활성화된 MySQL 서버에서는 GTID 일관성을 해칠 수 있는 유형의 쿼리는 시행할 수 없다.
  - GTID 기반 복제가 설정된 레플리카 서버에서는 sql_slave_skip_counter 변수를 사용해 트랜잭션을 건너뛸 수 없다.
  - GTID 기반 복제에서 CHANGE REPLICATION SOURCE TO 구문의 IGNORE_SERVER_IDS 옵션은 더 이상 사용되지 않는다.
    -- IGNORE_SERVER_IDS 옵션은 순환 복제 구조에서 한 서버가 장애로 인해 복제 토폴로지에서 제외됐을 때
    -- 장애 서버에서 발생한 이벤트가 중복으로 적용되지 않게 할 때 유용하게 사용할 수 있는데
    -- 어차피 GTID를 사용하면 레플리카 서버는 이미 적용된 트랜잭션을 식별할 수 있어 자동으로 무시한다.
 */
