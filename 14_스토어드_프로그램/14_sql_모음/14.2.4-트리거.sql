### 14.2.4. - 트리거
-- 트리거는 테이블의 레코드가 저장되거나 변경될 때 미리 정의해둔 작업을 자동으로 실행해주는 스토어드 프로그램이다.
-- 트리거는 테이블 레코드가 INSERT, UPDATE, DELETE 될 때 시작되도록 설정할 수 있다.
-- 대표적으로 컬럼의 유효성 체크나 다른 테이블로의 복사나 백업, 계산된 결과를 다른 테이블에 함께 업데이트 등의 작업을 위해 트리거를 자주 사용한다.
-- 트리거는 스토어드 함수나, 프로시저보다 필요성이 떨어진다.
    -- 사실 트리거가 없이도 애플리케이션을 개발하는 것이 어려워지거나 성능 저하가 발생하지 않는다.
    -- 오히려 트리거가 생성돼 있는 테이블에 컬럼을 추가하거나 삭제할 때 실행 시간이 훨씬 더 오래 걸린다.
    -- 테이블에 컬럼을 추가하거나 삭제하는 작업은 임시 테이블에 데이터를 복사하는 작업이 필요한데, 이때 레코드마다 트리거를 한 번씩 실행해야 하기 때문이다.
-- 트리거는 테이블에 대해서만 생성할 수 있다. 5.7 이전에선 2개 이상 트리거를 설정할 수 없지만, 5.7 이후 버전은 2개 이상 트리거를 생성할 수 있다.

#### 14.2.4.1 - 트리거 생성
-- CREATE TRIGGER 명령으로 생성할 수 있다.
-- BEFORE AFTER 키워드와 INSERT, UPDATE, DELETE 로 트리거가 실행될 이벤트와 시점(변경 전, 변경 후)을 명시할 수 있다.
-- 트리거 정의부 끝에 FOR EACH ROW 키워드를 붙여 개별 레코드 단위로 트리거가 실행되게 한다.
    -- 예전 버전에서는 FOR EACH STATEMENT 키워드를 이용해 문장 기반으로 트리거 작동을 구현할 예정이었지만 해당 기능은 제거됐다.
-- MySQL 서버의 트리거는 레코드(Row) 단위로만 작동하지만 트리거의 정의부에 FOR EACH ROW 키워드는 그대로 사용하도록 문법이 구현돼 있다.

-- employees 테이블의 레코드가 삭제되기 전에 실행하는 on_delete 트리거를 생성
CREATE TRIGGER on_delete BEFORE DELETE ON employees
    FOR EACH ROW
BEGIN
    DELETE FROM salaries WHERE emp_no = OLD.emp_no;
END;;
/*
    - 트리거 이름 뒤에 "BEFORE DELETE"로 트리거가 언제 실행될지를 명시한다. BEFORE DELETE 와 같은 형식으로 다음의 조합이 가능하다.
    [BEFORE | AFTER], [INSERT | UPDATE | DELETE] 왼쪽 두개와 오른쪽 세개의 조합으로 다양하게 사용 가능하다.
    BEFORE 는 대상 레코드가 변경되기 전에 실행, AFTER 는 대상 레로크가 변경 후 실행

    - 테이블명 뒤에는 트리거가 실행될 단위를 명시하는데, FOR EACH ROW 만 가능하므로 모든 트리거는 항상 레코드 단위로 실행 된다.

    - 에제 트리거에서 사용된 OLD 키워드는 employees 테이블이 변경되기 전 레코드를 지칭한다.
    employees 테이블의 변경될 레코드를 지칭하고자 할 때는 NEW 키워드를 사용하면 된다.

    참고로 테이블에 대해 DROP 이나 TRUNCATE 가 실행되는 경우에는 트리거 이벤트는 발생하지 않는다.

    트리거의 BEGIN ... END 블록 사이에서는 NEW 또는 OLD 라는 특별한 객체를 사용할 수 있다.
    OLD 는 해당 테이블에서 변경이 가해지기 전 레코드를 지칭하는 키워드이며, NEW 는 변경될 레코드를 지칭할 때 사용한다.

*/

/*
    트리거의 BEGIN ... END 의 코드 블록에서 사용하지 못하는 몇 가지 유형의 작업

    - 트리거는 외래키 관계에 의해 자동으로 변경되는 경우 호출되지 않는다.
    - 복제에 의해 레플리카 서버에 업데이트되는 데이터는 레코드 기반의 복제(row Based Replication)에서는
     레플리카 서버의 트리거를 기동시키지 않지만 문장 기반의 복제(statement Based Replication)에서는 레플리카 서버에서도 트리거를 기동시킨다.
    - 명시적 또는 묵시적인 ROLLBACK/COMMIT 을 유발하는 SQL 문장을 사용할 수 없다.
    - RETURN 문장을 사용할 수 없으며, 트리거를 종료할 때는 LEAVE 명령을 사용한다.
    - MySQL 과 information_schema, performance_schema 데이터베이스에 존재하는 테이블에 대해서는 트리거를 생성할 수 없다.
*/

#### 14.2.4.2 - 트리거 실행
-- 트리거가 등록된 테이블에 직접 레코드를 INSERT 하거나 UPDATE, DELETE 를 숭해서 작동을 확인해 볼 수밖에 없다.

#### 14.2.4.3 - 트리거 딕셔너리
-- 8.0 이전 버전까지 트리거는 해당 데이터베이스 디렉터리의 *.TRG 라는 파일로 기록됐다.
-- 하지만, 8.0 버전부터는 딕셔너리 정보가 InnoDB 스토리지 엔진을 사용하는 시스템 테이블로 통합 저장되면서 더이상 *.TRG 파일로 저장되지 않는다.
-- 전의 스토어드 프로지서, 함수들과 같이 information_schema 를 통해 조회할 수 있다.

-- 간단하게 트리거를 확인해보고 싶을 때
SHOW TRIGGERS FROM real_my_sql_80_book;

-- SELECT 쿼리로 확인하고 싶을 때
SELECT trigger_schema, trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE trigger_schema = 'real_my_sql_80_book';
