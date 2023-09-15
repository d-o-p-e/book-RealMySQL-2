---

### 18.1 - Performance 스키마란?

> `Performance` 스키마를 위해 다른 스토리지 엔진을 제공할까? (o / x) (648p)
>
- o : `Performance` 스키마를 위해 `PERFORMANCE_SCHEMA` 라는 스토리지 엔진을 사용한다.

> `PERFORMANCE_SCHEMA` 스토리지 엔진이 수집한 정보는 하드웨어 내에서 어디에 저장될까? (648p)
>
- 수집한 정보를 디스크가 아닌 **메모리에 저장**한다.
- Tables in the Performance Schema are in-memory tables that use no persistent on-disk storage. \
The contents are repopulated beginning at server startup and discarded at server shutdown. [[공식문서](https://dev.mysql.com/doc/mysql-perfschema-excerpt/8.0/en/performance-schema.html)]

> 위와 같이 사용했을 때 CPU나 메모리에 오버헤드를 어떻게 처리할 수 있을까?
>
- 전체 데이터를 수집하는게 아니라 **특정 이벤트들에 대한 데이터들만 수집**하도록 설정하면 된다.

> MySQL 서버가 복제나 클러스터 형태로 구성되어 있을 때 `Performance` 스키마에서 발생하는 데이터 변경들은 어떻게 될까?
>
- `Performance` 스키마에서 발생하는 데이터 변경은 MySQL 서버의 바이너리 로그에 기록되지 않기 때문에 \
  복제로 연결된 레플리카(세컨더리) 서버로 복제되지 않는다.

### 18.3.1 - 메모리 사용량 설정

> 위의 문제에서 봤듯이 `Performance` 스키마에 저장되는 데이터는 모두 메모리에 저장된다. \
따라서, `Performance` 스키마의 메모리를 제어하기 위한 변수들이 존재한다. \
변수들의 값중 `-1`로 설정되어 있는 부분들이 있는데 이 `-1`은 무엇을 의미할까? (663p)
>
- `-1` 값은 정해진 제한 없이 필요에 따라 자동으로 크기가 증가할 수 있음을 의미한다.

> `Performance` 스키마의 메모리 사용량 관련 시스템 변수들은 크게 두 가지로 분류할 수 있는데 무엇일까? (665p)
>
- 테이블에 저장되는 **데이터 수를 제한**하는 변수
- **데이터를 수집할 수 있는 이벤트 클래스 개수** 및 해당 클래스의 구현체인 **인스턴스들의 수를 제한하는 변수**
- 이렇게 두 가지로 분류할 수 있다.

> `Performance` 스키마의 메모리 사용량 설정과 관련된 변수를 설정할 때 유의 사항으로 무엇이 있을까? (671p)
>
- 메모리 사용량 관련된 변수들은 MySQL 서버 시작 시 설정 파일에 명시하는 형태로만 적용할 수 있음으로 유념해야 된다.

  ex) 다음과 같이 설정할 수 있다.

    ```sql
    [mysqld]
    performance_schema_events_waits_history_size=30
    			.
    			.
    			.
    performance_schema_events_transactions_history_long_size=50000
    ```


### 18.3.2.1.1 - 저장 레벨 설정

> `Performance` 스키마에서 모니터링 대상이나 수집 대상 이벤트를 설정해놓고 저장 레벨을 설정해놓지 않은 경우 어떻게 될까? (672p)
>
- 저장 레벨을 설정해놓지 않으면 `Performance` 스키마에 데이터가 저장되지 않는다.

> `events_transactions_history`의 저장 레벨을 활성화하고, `events_transactions_current` 저장 레벨을 비활성화 하면 어떻게 될까? (673p)
>
- `Performance` 스키마에 저장 레벨은 다음과 같은 계층 구조를 가진다. 하위 레벨을 활성화해도, 상위 레벨이 활성화되지 않으면 저장되지 않는다. \
따라서, `events_transactions_history`은 저장되지 않는다.
- 저장 레벨의 계층 구조
    - `global_instrumentation` 최상위 저장 레벨 (수집한 데이터를 이벤트 클래스별 전역적으로만 저장)
        - `thread_instrumentation` - 스레드별로도 데이터 저장 가능
            - `events_waits_current`
                - `events_waits_history`
                - `events_watis_history_long`
            - `events_stages_current`
                - `events_stages_history`
                - `events_stages_history_long`
            - `events_statements_current`
                - `events_statements_history`
                - `events_statements_history_long`
            - `events_transactions_current`
                - `events_transactions_history`
                - `events_transactions_history_long`
        - `statements_digest` - 쿼리 다이제스트별로 데이터를 저장해 다이제스트별 통계 정보를 확인

  `events_` 로 서직하는 저장 레벨은 각 저장 레벨명과 일치하는 Performance 스키마 테이블의 데이터 저장 가능 여부를 결정한다.


> `setup_instruments` 테이블에서 이름이 “`memory/performance_schema`”로 시작하는 이벤트 클래스들은 항상 활성화 되어 있다. \
 사용자가 이를 비활성화 시킬 수 있을까? (o / x) (677p)
>
- x : 위와 관련된 이벤트 클래스들은 사용자가 비활성화 할 수 없다.

    ```sql
    -- 업데이트 쿼리가 실행은 되지만 적용되지 않는다.
    update performance_schema.setup_instruments
    set enabled='NO'
    where name = 'memory/performance_schema/mutex_instances';
    ```

- 그 외 나머지 이벤트 클래스들에 대해서는 사용자가 데이터 수집 여부를 재설성할 수 있다.

    ```sql
    -- 다른 이벤트 클래스들을 업데이트하는 방법
    UPDATE performance_schema.setup_instruments
    SET ENABLED='YES', TIMED='YES'
    WHERE NAME='stage/innodb/alter table%';
    ```

- `enabled`, `timed` 컬럼만 변경할 수 있다.

> `performance.setup_threads` 테이블에는 Performance 스키마가 데이터를 수집할 수 있는 스레드 객체의 클래스 목록이 저장되어 있다. \
이때 클라이언트 연결로 인해 생성된 포그라운드 스레드의 경우 유의해야 될 점이 있는데 무엇일까? (681p)
>
- **포그라운드 스레드의 경우** `setup_threads` 테이블에서 설정된 내용이 무시되고, `setup_actors` 테이블의 설정이 적용된다.
- **백그라운드 스레드의 경우**는 위와 반대로 `setup_actors` 테이블에 설정된 내용에 전혀 영향을 받지 않는다.

### 18.3.2.2 - Performance 스키마 설정의 영구 적용

> `setup` 테이블을 통해 동적으로 `Performance` 스키마 설정을 변경하고, 서버를 재시작해야 될 일이 생겼다. 이때 어떻게 될까? (682p)
>
- `setup` 테이블을 통해 동적으로 변경한 `Performance` 스키마 설정은 서버 재시작시 모두 초기화된다.
- 따라서, 재시작하더라도 유지하고 싶거나, 서버 시작 시 바로 설정을 적용하고 싶은 경우에는 다음과 같이 MySQL 설정 파일을 사용 하면 된다.
    - 단, 설정 파일을 사용했을 경우 `Performance 스키마에 수집 대상 이벤트`와 `데이터 저장 레벨`에 대해서만 가능하다.

    ```sql
    [mysqld]
    performance_schema_instrument='수집_대상_이벤트_클래스명 = [0 | 1 | COUNTED]'
    
    /**
    	수집_대상_이벤트_클래스명에 와일드 카드(%)를 사용할 수도 있다.
    
    	value 의 값으로 0, 1, COUNTED 를 사용할 수 있으며, 해당 값의 의미는 다음과 같다.
    		0 : [OFF 또는 FALSE]로 사용할 수 있고, 수집 대상에서 제외한다.
    			setup_instruments 테이블의 ENABLED, TIMED 컬럼이 모두 'NO'로 설정된 것과 동일
    		1 : [ON 또는 TRUE]로 사용할 수 있고, 수집 대상으로 설정하며 시간 측정 수행도 활성화한다.
    		    setup_instruments 테이블의 ENABLED, TIMED 컬럼이 모두 'YES'로 설정된 것과 동일
    		COUNTED : 수집 대상으로만 설정하며, 시간 측정은 수행되지 않는다.
    			  setup_instruments 테이블의 ENABLED 컬럼만 'YES'로 설정된 것과 동일
     */
    ```

    - 단, 여러 개의 이벤트 클래스를 사용하려면 원하는 클래스 수만큼 해당 설정을`performance_schema_instrument='클래스명=[0 | 1 | COUNTED]'` 중복해서 사용하면 된다.

### 18.6 - Sys 스키마 구성

- Sys 스키마에서 각 설명에 대한 공식문서
    - https://dev.mysql.com/doc/refman/8.0/en/sys-schema-reference.html
