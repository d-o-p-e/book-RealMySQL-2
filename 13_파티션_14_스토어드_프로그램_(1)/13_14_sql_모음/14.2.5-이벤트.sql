### 14.2.5 - 이벤트
-- 주어진 특정한 시간에 스토어드 프로그램을 실행할 수 있는 스케줄러 기능을 이벤트라고 한다.
SHOW GLOBAL VARIABLES LIKE 'event_scheduler'; -- ON 이여야 한다. 이게 활성화된 경우에만 이벤트가 실행한다.
SHOW PROCESSLIST; -- User 컬럼에서 even_scheduler 의 값이 있다.

-- MySQL 의 이벤트는 전체 실행 이력을 보관하지 않으며, 가장 최근에 실행한 정보만 information_schema 데이터베이스의 events 로 확인할 수 있다.
-- 실행 이력이 필요하다면 별도로 사용자 테이블을 생성하고 이벤트의 처리 로직에서 직접 기록하는 것이 좋다.
SELECT * FROM information_schema.events;

#### 14.2.5.1 - 이벤트 생성
-- 이벤트는 반복 실행 여부에 따라 크게 일회성 이벤트와 반복성 이벤트로 나눌 수 있다.
-- 일회성 이벤트를 등록하려면 ON SCHEDULE AT 절을 명시하면 된다.

-- 1시간 뒤에 실행될 이벤트를 등록하는 명령의 예제
-- AT 절에는 '2020-07-07 01:00:00' 과 같은 정확한 시간을 명시할 수도 있고, 현재 시점부터 1시간 뒤와 같이 상대적인 시간을 명시할 수도 있다.
CREATE EVENT onetime_job
  ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 1 HOUR
DO
  INSERT INTO daily_rank_log VALUES (NOW(), 'Done');

-- 2020년 9월 7일 새벽 1시부터 2020년 말까지 반복해서 실행하는 daily_ranking 이벤트를 생성하는 예제
-- STARTS 와 ENDS 로 범위를 지정할 수 있다.
-- 1 DAY 말고, YEAR, QUARTER, MONTH, HOUR, MINUTE, WEEK, SECOND, .. 등의 반복 주기를 설정할 수 있다.
CREATE EVENT daily_ranking
  ON SCHEDULE EVERY 1 DAY STARTS '2020-09-07 01:00:00' ENDS '2021-01-01 00:00:00'
DO
  INSERT INTO daily_rank_log VALUES (NOW(), 'Done');

-- 반복성, 일회성 상관없이 이벤트의 처리 내용을 작성하는 DO 절은 여러 가지 방식으로 사용할 수 있다.
-- DO 절에는 단순히 하나의 쿼리나 스토어드 프로시저를 호출하는 명령을 사용하거나 BEGIN ... END 로 구성되는 복합 절을 사용할 수 있다.
-- 단인 SQL 만 실행하려면 별도로 BEGIN ... END 블록을 사용하지 않아도 무방하다.
CREATE TRIGGER daily_ranking
    ON SCHEDULE EVERY 1 DAY STARTS '2020-09-16 01:00:00' ENDS '2021-01-01 00:00:00'
DO
    CALL SP_INSERT_BATCH_LOG(NOW(), 'Done');

-- 여러 개의 SQL 문장과 연산 작업이 필요하다면 BEGIN ... END 블록을 사용하면 된다.
CREATE TRIGGER daily_ranking
    ON SCHEDULE EVERY 1 DAY STARTS '2020-09-16 01:00:00' ENDS '2021-01-01 00:00:00'
DO BEGIN
    INSERT INTO daily_rank_log VALUES (NOW(), 'Start');
    -- 랭킹 정보 수집 & 처리
    INSERT INTO daily_rank_log VALUES (NOW(), 'Done');
END;;

-- 이벤트의 반복성 여부와 관계없이 ON COMPLETION 절을 이용해 완전히 종료된 이벤트를 삭제할지, 그대로 유지할지 선택할 수 있다.
-- 기본적으로 완전히 종료된 이벤트는 자동으로 삭제된다.
    -- 하지만, ON COMPLETION PRESERVE 옵션과 함께 이벤트를 등록하면 이벤트가 끝나도 이벤트를 삭제하지 않는다.
-- 이벤트를 생성할 때 ENABLE, DISABLE, DISABLE ON SLAVE 의 3 가지 상태로 생성할 수 있다.
/*
    기본적으로 복제 소스 서버에서는 ENABLE 되며, 복제된 레플리카 서버에서는 SLAVESIDE_DISABLED 상태로 생성된다.
        - SLAVESIDE_DISABLED 상태란 DISABLE ON SLAVE 옵션을 설정한 것처럼 보인다.
    복제 소스 서버에서는 실행된 이벤트가 만들어낸 데이터 변경 사항은 자동으로 레플리카 서버로 복제되기 때문에 레플리카 서버에서 이벤트는 중복해서 실행할 필요는 없다.
    다만, 레플리카 서버가 소스 서버로 승격(Promotion, 레플리카 서버가 소스 서버로 용도 전환되는 과정)되면 수동으로 이벤트의 상태를 ENABLE 상태로 변경해야 된다.
*/
-- 레플리카 서버에서만 DISABLE 된 이벤트의 목록은 다음과 같이 확인할 수 있다.
SELECT event_schema, event_name
FROM information_schema.events
WHERE status = 'SLAVESIDE_DISABLED';

-- 수동으로 이벤트의 상태를 ENABLED 로 변경
ALTER EVENT 이벤트_명 ENABLE;

#### 14.2.5.2 - 이벤트 실행 및 결과 확인
-- 이벤트 또한 트리거와 같이 특정한 사건이 발생해야 실행되는 스토어드 프로그램이라서 테스트를 위해 강제로 실행시켜볼 수는 없다.

-- 테스트를 위해 테이블과 이벤트를 생성
DELIMITER ;;
CREATE TABLE daily_rank_log (exec_dttm DATETIME, eec_msg VARCHAR(50));;

CREATE EVENT daily_ranking
    ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 1 MINUTE
    ON COMPLETION PRESERVE -- 이벤트가 완료돼도 EVENTS 뷰에서 삭제되지 않게 하는 옵션
DO BEGIN
    INSERT INTO daily_rank_log VALUES (NOW(), 'Done');
END ;;
-- 위에서 등록한 이벤트의 스케줄링 정보나 최종 실행 시간 정보는 아래와 같이 information_schema DB의 events 뷰를 통해 조회할 수 있다.
-- information_schema.events 테이블에선 항상 마지막 실행 로그만 가지고 있기 때문에 전체 실행 로그가 필요한 경우에는 별도의 로그 테이블이 필요하다.
SELECT * FROM information_schema.events;
SELECT * FROM daily_rank_log; -- 1분 뒤에 확인해보면 값이 잘 입력되어 있다.

-- events 테이블에 이벤트가 등록되어 있으면 동일한 이름을 실행이 안되므로 삭제하는 것도 좋을거 같다.
DROP EVENT daily_ranking;

#### 14.2.5.3 - 이벤트 딕셔너리
-- 아래 쿼리는 events 뷰를 통해 이벤트의 목록과 상세 내용을 확인할 수 있다. 그리고, 이벤트의 메타 정보뿐만 아니라 마지막 실행 이력도 함께 보여준다.
-- events 뷰를 통해 해당 이벤트가 반복인지 일회성인지, 언제 실행될지를 확인할 수 있으며 이벤트의 코드도 확인할 수 있다.
-- 또한 ORIGINATOR 컬럼은 server_id 시스템 변수값이다.
    -- 이 값은 레플리카 서버에서 이벤트의 상태를 SLAVESIDE_DISABLED 로 자동 설정하기 위해서 관리된다.
SELECT * FROM information_schema.events;
