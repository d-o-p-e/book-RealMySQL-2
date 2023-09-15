## 18.5 - Sys 스키마 사용을 위한 사전 설정
/**
  Sys 스키마의 데이터베이스 객체들은 Performance 스키마에 저장된 데이터를 참조한다.
  따라서, Sys 스키마를 제대로 사용하기 위해서는 Perforamnce 스키마 기능이 활성화돼 있어야 한다.
  8.0 버전부터는 기본적으로 활성화 되어 있고, 설정 파일을 이용해 명시적으로 설정하고 싶은 경우 다음과 같이 하면 된다.
    [mysqld]
    performance_schema=ON

  Performance 스키마가 활성화 되어 있다면 해당 설정 내용을 바탕으로 데이터가 수집 및 저장되고,
  사용자는 Sys 스키마를 통해 Performance 스키마에 저장돼 있는 데이터를 바로 조회해 볼 수 있다.

  MySQL 서버가 구동 중인 상태에서 Performance 스키마에 대한 설정 변경은 Sys 스키마에서 제공하는 프로시저를 통해 진행할 수도 있다.
*/

# Performance 스키마 현재 설정 확인
-- Performance 스키마에서 비활성화된 설정 전체를 확인
CALL sys.ps_setup_show_disabled(TRUE, TRUE);

-- Performance 스키마에서 비활성화된 저장 레벨 설정을 확인
CALL sys.ps_setup_show_disabled_consumers();

-- Performance 스키마에서 비활성화된 수집 이벤트들을 확인
CALL sys.ps_setup_show_disabled_instruments();

-- Performance 스키마에서 활성화된 설정 전체를 확인
CALL sys.ps_setup_show_enabled(TRUE, TRUE);

-- Performance 스키마에서 활성화된 저장 레벨 설정을 확인
CALL sys.ps_setup_show_enabled_consumers();

-- Performance 스키마에서 활성화된 수집 이벤트들을 확인
CALL sys.ps_setup_show_enabled_instruments();

# Performance 스키마 설정 변경
-- Performance 스키마에서 백그라운드 스레드들에 대해 모니터링을 비활성화
CALL sys.ps_setup_disable_background_threads();

-- Performance 스키마에서 'wait' 문자열이 포함된 저장 레벨들을 모두 비활성화
CALL sys.ps_setup_disable_consumer('wait');

-- Performance 스키마에서 'wait' 문자열이 포함된 수집 이벤트들을 모두 비활성화
CALL sys.ps_setup_disable_instrument('wait');

-- Performance 스키마에서 특정 스레드에 대해 모니터링을 비활성화
CALL sys.ps_setup_disable_thread(123);

-- Performance 스키마에서 백그라운드 스레드들에 대해 모니터링을 활성화
CALL sys.ps_setup_enable_background_threads();

-- Performance 스키마에서 'wait' 문자열이 포함된 저장 레벨들 모두 활성화
CALL sys.ps_setup_enable_consumer('wait');

-- Performacne 스키마에서 'wait' 문자열이 포함된 수집 이벤트들을 모두 활성화
CALL sys.ps_setup_enable_instrument('wait');

-- Performance 스키마에서 특정 스레드에 대해 모니터링 활성화
CALL sys.ps_setup_enable_thread(123);

# Performance 스키마의 설정을 기본 설정으로 초기화
CALL sys.ps_setup_reset_to_default(TRUE);

/**
  사용자가 root 와 같이 MySQL에 대해 전체 권한을 가진 DB 계정으로 접속한 경우 Sys 스키마에서 제공하는 모든 데이터베이스 객체를 자유롭게 사용할 수 있다.
  제한적인 권한을 가진 DB 계정에는 Sys 스키마를 사용하기 위해 추가 권한이 필요하다.
  다음의 권환들을 해당 계정에 추가한 뒤 사용하면 된다.
 */
GRANT PROCESS ON *.* TO `user`@`host`;
GRANT SYSTEM_VARIABLES_ADMIN ON *.* TO `user`@`host`;
GRANT ALL PRIVILEGES ON `sys`.* TO `user`@`host`;
GRANT SELECT, INSERT, UPDATE, DELETE DROP ON `perforamnce_schema`.* TO `user`@`host`;
