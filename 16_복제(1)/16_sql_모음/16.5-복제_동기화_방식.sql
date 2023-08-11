## 16.5 - 복제 동기화 방식
/**
  소스 서버와 레플리카 서버 간의 복제 동기화에 대해 두 가지 방식을 제공한다.
  하나는 오래 전부터 사용돼온 비동기 복제(Asynchronous replication) 방식이며,
  다른 하나는 5.5 버전부터 도입된 반동기 복제(Semi-synchronous replication) 방식이다.
 */

### 16.5.1 - 비동기 복제(Asynchronous replication)
/**
  MySQL의 복제는 기본적으로 비동기 방식으로 동작한다.
  변경 이벤트가 정상적으로 전달되어 적용됐는지를 확인하지 않는 방식이다.
  소스 서버에서 커밋된 트랜잭션은 바이너리 로그에 기록되며, 레플리카 서버에서 주기적으로 신규 트랜잭션에 대한 바이너리 로그를 소스 서버에 요청한다.
  이로 인해 소스 서버에 장애가 발생하면 소스 서버에서 최근까지 적용된 트랜잭션이 레플리카 서버로 전송되지 않을 수 있다.
  따라서, 장애가 발생해 레플리카 서버를 소스 서버로 승격 시키는 경우 소스 서버로부터 전달받지 못한 트랜잭션이 있는지 직접 확인하고
  그런 것들이 있다면 수동으로 다시 적용해야 한다.

  하지만, 이런 비동기적인 부분 때문에 트랜잭션 처리 성능에 있어서 더 좋고, 레플리카 서버에 문제가 생겨도 소스 서버는 아무런 영향도 받지 않는다는 장점이 있다.
 */

### 16.5.2 - 반동기 복제(Semi-synchronous replication)
/**
  반동기 복제는 비동기 복제보다 좀 더 향상된 데이터 무결성을 제공하는 복제 동기화 방식으로,
  반동기 복제에서 소스 서버는 레플리카 서버가 소스 서버로부터 전달받은 변경 이벤트를 릴레이 로그에 기록 후 응답(ACK)을 보내면
  그때 트랜잭션을 완전히 커밋시키고 클라이언트에 결과를 반환한다.
  따라서, 반동기 복제에서는 소스 서버에서 커밋되어 정상적으로 결과가 반환된 모든 트랜잭션들에 대해
  적어도 하나의 레플리카 서버에는 해당 트랜잭션들이 "전송"됐음을 보장한다.
  다만, "전송"됐음을 보장하는 것이지 "적용"되는 것까지 보장한다는 것은 아니다. 그래서 이름이 반동기인 것이다.

  반동기 복제에서는 소스 서버가 트랜잭션 처리 중 어느 지점에서 레플리카 서버의 응답을 기다리냐에 따라
  소스 서버에서 장애가 발생했을 때 사용자가 겪을 수 있는 문제 상황이 조금 다를 수 있다.

  사용자는 rpl_semi_sync_master_wait_point 시스템 변수를 통해 소스 서버가 레플리카 서버의 응답을 기다리는 지점을 제어할 수 있다.
  시스템 변수에는 AFTER_SYNC 또는 AFTER_COMMIT 값으로 설정 가능하다.
    - AFTER_SYNC로 설정된 경우
            소스 서버의 트랜잭션을 바이너리 로그에 기록하고 난 후 스토리지 엔진에 커밋하기 전 단계에서 레플리카 서버의 응답을 기다리게 된다.
    - AFTER_COMMIT 설정된 경우
            소스 서버의 트랜잭션을 바이너리 로그에 기록, 스토리지 엔진도 커밋 후 클라이언트에 결과를 반환하기 전에 레플리카 서버의 응답을 기다린다.
  5.7 버전에서 AFTER_SYNC 방식이 도입됐으며 8.0 버전에서 기본적으로 설정된 동작 방식은 AFTER_SYNC다.

  AFTER_SYNC 방식은 AFTER_COMMIT 방식과 비교해서 다음과 같은 장점이 있다.
    - 소스 서버에 장애가 발생했을 때 팬텀 리드(Phantom REad)가 발생하지 않음
    - 장애가 발생한 소스 서버에 대해 좀 더 수월하게 복구 처리가 가능

  AFTER_COMMIT 에서는 스토리지 엔진 커밋까지 처리된 후 레플리카 응답을 기다리는 것이라 스토리지 엔진 커밋이 완료된 데이터는 다른 세션에서 조회가 가능하다.
  이로 인해 스토리지 엔진 커밋 후 레플리카 서버의 응답을 기다리고 있는 상황에서 소스 서버에 장애가 난 경우 사용자는 이전 소스 서버에서 조회했던 데이터를 보지 못할 수도 있다.

  반동기 복제는 트랜잭션을 처리하는 중에 레플리카 서버의 응답을 기다리므로 비동기 방식과 비교했을 때 트랜잭션의 처리 속도가 더 느릴 수 있다.
  최초 레플리카 서버로 응답을 요청하고 전달받기까지 네트워크 왕복 시간만큼 더 걸린다.
  이처럼 네트워크로 통신하는 부분으로 인해 반도기 복제는 물리적으로 가깝게 위치한 레플리카 서버와의 복제에 더 적합하다고 할 수 있다.
  소스 서버는 무기한 응답을 기다릴 수 없으므로 지정된 타임아웃 시간 동안 레플리카 서버의 응답이 없으면 자동으로 비동기 복제 방식으로 전환된다.
  또한, 레플리카 서버가 여러 대가 있을 경우 연결된 전체 레플리카 서버의 응답을 기다려야 하는 것은 아니다. (응답을 받아야 하는 레플리카 수를 설정할 수 있음)
 */

#### 16.5.2.1 - 반동기 복제 설정 방법
/**
  반동기 복제 기능은 플러그인 형태로 구현돼 있으므로 이를 사용하려면 먼저 관련 플러그인을 설치해야 한다.
  소스와 레플리카 서버 모두 플러그인을 설치해야 한다.

  -- 소스 서버 플러그인 설치
  INSTALL PLUGIN rpl_semi_sync_master SONAME 'semisync_master.so';

  -- 레플리카 서버 플러그인 설치
  INSTALL PLUGIN rpl_semi_sync_slave SONAME 'semisync_slave.so';

  플러그인이 정상적으로 설치됐는지는 information_schema.PLUGINS 테이블을 조회하거나 SHOW PLUGINS 명령을 통해 확인할 수 있다.
 */
SELECT plugin_name, plugin_status
FROM information_schema.plugins
WHERE plugin_name LIKE '%semi%';

/**
  이제 반동기 복제 사용을 위해 관련 시스템 변수들을 적절히 설정해야 한다.
  이 시스템 변수들은 플러그인이 정상적으로 설치된 이후에 SHOW GLOBAL VARIABLES 명령 등에서 확인할 수 있다.
  반동기 복제와 관련된 시스템 변수들은 다음과 같다.
    - rpl_semi_sync_master_enabled
        소스 서버에서 반동기 복제의 활성화 여부를 제어한다. ON(1) 또는 OFF(0)로 설정 가능하다.
    - rpl_semi_sync_master_timeout
        소스 서버에서 레플리카 서버의 응답이 올 때까지 대기하는 시간으로, 밀리초 단위로 설정할 수 있다.
        이 변수에 지정된 시간만큼 레플리카 서버의 응답을 기다렸다가 만약 지정된 시간이 초과할 때까지 응답이 오지 않으면 비동기 복제로 전환한다.
        기본값은 10000(10초)다.
    - rpl_semi_sync_master_trace_level
        소스 서버에서 반동기 복제에 대해 디버깅 시 어느 정도 수준으로 디버그 로그가 출력되게 할 것인지 디버깅 추적 레벨을 지정하는 설정이다.
        1, 16, 32, 64 값으로 설정 가능하다.
    - rpl_semi_sync_master_wait_for_slave_count
        소스 서버에서 반드시 응답을 받아야 하는 레플리카 수를 결정한다. 기본값은 1이며, 최대 65535까지 설정 가능하다.
        응답을 받아야 하는 레플리카 수가 많을수록 소스 서버의 처리 성능은 저하된다.
    - rpl_semi_sync_master_wait_no_slave
        rpl_semi_sync_master_timeout에 지정된 시간 동안 소스 서버에서 반동기 복제로 연결된 레플리카 서버 수가
        rpl_semi_sync_master_wait_for_slave_count에 지정된 수보다 적어졌을 때 어떻게 처리할 것인지 결정하는 수이다.
        ON(1)이면 레플리카 수가 적어지더라도 타임아웃 시간 동안 반동기 복제를 그대로 유지하고,
        OFF(0)이면 레플리카 수가 적어지는 즉시 비동기 복제로 전환된다.
        show global status 명령문의 결과에서 반동기 복제로 연결된 레플리카 서버 수를 확인할 수 있다.(repl_semi_sync_master_clients 값)
    - rpl_semi_sync_master_wait_point
        소스 서버가 트랜잭션 처리 단계 중 레플리카 서버의 응답을 대기하는 지점을 설정하는 옵션.
        AFTER_SYNC와 AFTER_COMMIT 값으로 설정 가능하며, 기본값은 AFTER_SYNC
    - rpl_semi_sync_slave_enabled
        레플리카 서버에서 반도기 복제의 활성화 여부, ON(1) OFF(0)로 설정 가능
    - rpl_semi_sync_slave_trace_level
        레플리카 서버에서 반동기 복제에 대한 디버그 로그 위의 master랑 똑같다.
 */

/**
  반동기 복제 활성화를 위해 소스 서버와 레플리카 서버에서 다음과 같이 변수들을 설정해보자
  -- 소스 서버
  SET GLOBAL rpl_semi_sync_master_enabled = 1;
  SET GLOBAL rpl_semi_sync_master_timeout = 5000;

  -- 레플리카 서버
  SET GLOBAL rpl_semi_sync_slave_enabled = 1;

  위와 같이 진행한 후 기존에 복제가 실행 중인 상태라면 반동기 복제 적용을 위해 I/O 스레드를 재시작 해야 한다.
  STOP REPLICA IO_THREAD;
  START REPLICA IO_THREAD;

  -- 소스 서버에서 반도기 복제 관련 상태 값을 확인
  SHOW GLOBAL STATUS LIKE '%semi_sync_master%';

  -- 레플리카 서버에서 반도기 복제 관련 상태 값을 확인
  SHOW GLOBAL STATUS LIKE '%semi_sync_slave%';

  활성화한 복제 설정이 재시작하더라도 적용될 수 있도록 cnf 파일 수정
  -- 소스 서버
  [mysqld]
  rpl_semi_sync_master_enabled=1
  rpl_semi_sync_master_timeout=5000

  -- 레플리카 서버
  [mysqld]
  rpl_semi_sync_slave_enabled=1
 */
