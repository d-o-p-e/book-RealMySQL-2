## 18.6 - Sys 스키마 구성
/**
  Sys 스키마는 '테이블', '뷰', '프로시저', '함수'들로 구성돼 있다.
  다음의 공식문서를 통해 '테이블', '뷰', '프로시저', '함수' 등을 자세히 확인할 수 있다.
  https://dev.mysql.com/doc/refman/8.0/en/sys-schema-reference.html

  - 테이블
    Sys 스키마에서 일반 테이블로는 'Sys 스키마의 데이터베이스 객체에서 사용되는 옵션의 정보가 저장돼 있는 테이블 하나만 존재'하며,
    이 테이블은 'InnoDB 스토리지 엔진으로 설정'돼 있어 데이터가 '영구적으로 보존'된다.

    - sys_config
        Sys 스키마의 함수 및 프로시저에서 참조되는 옵션들이 저장돼 있는 테이블이다.
        옵션들이 참조되는 Sys 스키마 함수와 프로시저는 variable 컬럼의 '.' 앞에 되어 있는 부분들이다. (ex. 'diagnostics'.include_raw)
        따라서, 'SELCT * FROM sys.sys_conf' 쿼리로 확인했을 때 참조하는 네 개의 객체가 있다.

        diagnostics() 프로시저 객체
        ps_thread_trx_info() 함수 객체
        statement_performance_analyzer() 프로시저 객체
        format_statement() 함수 객체 (-> 이 부분만 '.' 앞에 이나다 variable 컬럼의 값중 statement_truncate_len 이 참조하는 객체다.)

        이러한 옵션들을 참조하는 Sys 스키마 함수 및 프로시저에서는 sys_)config 테이블에서 옵션 값을 조회하기 전에 먼저
        '@sys.' 접두사를 가지며, sys_config 테이블에 정의된 옵션명과 동일한 사용자 정의 변수가 존재하는지 확인한다.
        만약 프로시저를 호출한 세션에서 동일한 사용자 정의 변수가 정의돼 있고, 값이 NULL이 아니면 사용자 정의 변수에 설정된 값을 우선적으로 사용한다.

  - 뷰
    Sys 스키마의 뷰에는 'Formatted-View' 와 'Raw-View'로 구분된다.

    - Formatted-View
        출력되는 결과에서 사람이 쉽게 읽을 수 있는(Human Readable) 수치로 변환해서 보여주는 뷰이다.
    - Raw-View
        'x$'라는 접두사로 시작하고, 데이터를 저장된 원본 형태 그대로 출력해서 보여준다.

    -- Formatted-View, Raw-View 형태로 Sys 스키마의 뷰를 살펴보자.
        host_summary, x$host_summary
        호스트별로 쿼리 처리 및 파일 I/O와 관련된 정보, 그리고 커넥션 수 및 메모리 사용량 등의 종합적인 정보가 출력

        host_summary_by_file_io, x$host_summary_by_file_io_type
        호스트 및 파일 I/O 이벤트 유형별로 발생한 파일 I/O 이벤트 총수 및 대기 시간에 대한 정보가 출력

        host_summary_by_stages, x$host_summary_by_stages
        호스트별로 실행된 쿼리들의 처리 단계별 이벤트 총수와 대기 시간에 대한 정보가 출력된다.

        host_summary_by_statement_latency, x$host_summary_by_statement_latency
        호스트별로 쿼리 처리와 관련해서 지연 시간, 접근한 로우 수, 풀스캔으로 처리된 횟수 등에 대한 정보가 출력된다.

        host_summary_by_statement_type, x$host_summary_by_statement_type
        호스트별로 실행된 명령문 유형별 지연 시간, 접근한 로우 수, 풀스캔으로 처리된 횟수 등에 대한 정보가 출력된다.

                                        .
                                        .

        등등 다양하게 존재하고 있다. 더 알고 싶으면 Real MySQL 2권 688p 이후를 보거나 아래 공식문서 링크를 통해 확인해봐도 된다.
        https://dev.mysql.com/doc/refman/8.0/en/sys-schema-views.html 여기를 통해 확인할 수 있다.

  - 스토어드 프로시저
    Sys 스키마에서 제공하는 스토어드 프로시저들을 사용해 Performance 스키마의 설정을 손쉽게 확인, 변경할 수 있다.
    MySQL 서버 상태와 현재 실행 중인 쿼리들에 대해 종합적으로 분석한 보고서 형태의 데이터도 확인할 수 있다.

    여기에도 다양하게 존재하기 때문에 필요한 상황일 때 공식 문서를 참고하거나 Real MySQL 2권 693p 이후를 살펴보자.
    https://dev.mysql.com/doc/refman/8.0/en/sys-schema-procedures.html

    - ps_setup_save(in_timeout INT)
        현재 Performance 스키마 설정을 임시 테이블(Temporary Table)을 생성해 백업한다.
        다음 테이블의 데이터가 백업되며, 백업 시 다른 세션에서 동일하게 백업이 수행되는 것을 방지하고자 GET_LOCK() 함수를 통해
        'sys.ps_setup_save' 문자열에 대한 잠금을 생성한다.
        - performance_schema.setup_actors
        - performance_schema.setup_consumers
        - performance_schema.setup_instruments
        - performance_schema.threads

        해당 문자열에 대한 잠금이 이미 생성돼 있는 경우 인자로 주어진 타임아웃 시간(초 단위)만큼 대기하며,
        타임아웃 시간을 초과하면 프로시저 실행은 실패한다.
        정상적으로 생성된 잠금은 동일한 세션에서 ps_setup_reload_saved() 프로시저가 실행되거나 세션이 종료될 때 임시 테이블과 함께 사라진다.

  - 함수
    Sys 스키마에서는 값의 단위를 변환하고, Performance 스키마의 설정 및 데이터를 조회하는 등의 다양한 기능을 가진 함수들을 제공한다.
    이 같은 함수들은 주로 Sys 스키마의 뷰와 프로시저에서 사용된다.

    관련된 공식문서 링크 - https://dev.mysql.com/doc/refman/8.0/en/sys-schema-functions.html
 */
select * from sys.host_summary;
select * from sys.x$host_summary;
call sys.ps_setup_show_disabled(FALSE, FALSE);
call sys.ps_setup_show_disabled_consumers();
call sys.ps_setup_show_disabled_instruments();
call sys.ps_statement_avg_latency_histogram();
