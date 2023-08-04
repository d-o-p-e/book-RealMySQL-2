### 14.3.2 - DETERMINISTIC과 NON DETERMINISTIC 옵션
-- DETERMINISTIC, NON DETERMINISTIC 옵션도 이 전에 본 DEFINER, SQL SECURITY와 같이 중요한 옵션이다.
-- 이 두 옵션은 성능과 관련된 옵션이다. 이 두 옵션은 서로 배타적이라 둘 중 하나를 반드시 선택해야 한다.
/*
    DETERMINISTIC이란 '스토어드 프로그램의 입력이 같다면 시점이나 상황에 관계없이 결과가 항상 같다(확장적이다)'를 의미하는 키워드
    반대로 NOT DETERMINISTIC이란 입력이 같아도 시점에 따라 결과가 달라질 수도 있음을 의미한다.

    일반적으로 한 번만 실행되는 스토어드 프로시저는 이 옵션의 영향을 거의 받지 않는다.
    하지만, 반복적으로 호출될 수 있는 스토어드 함수는 영향을 많이 받으며, 쿼리의 성능을 급격하게 떨어뜨리기도 한다.
*/

-- DETERMINISTIC과 NOT DETERMINISTIC으로 정으된 스토어드 함수의 차이 예제
CREATE FUNCTION sf_getdate1() -- 매 레코드마다 WHERE 조건의 값이 재평가(호출)돼야 한다. 이거 때문에 풀 스캔 발생
    RETURNS DATETIME
    NOT DETERMINISTIC
BEGIN
    RETURN NOW();
END;

CREATE FUNCTION sf_getdate2() -- 실행 시점을 기준으로 상수화 한다.
    RETURNS DATETIME
    DETERMINISTIC
BEGIN
    RETURN NOW();
END;

EXPLAIN SELECT * FROM dept_emp WHERE from_date > sf_getdate1(); -- type 컬럼이 ALL이다, 풀 스캔 발생
EXPLAIN SELECT * FROM dept_emp WHERE from_date > sf_getdate2(); -- type 컬럼이 range, 레인지 스캔

/*
    NON DETERMINISTIC 옵션으로 정의된 스토어드 함수를 사용하는 쿼리는 풀 테이블 스캔을 사용한다.
    이는 입력값이 같아도 호출되는 시점에 따라 값이 달라진다는 사실을 MySQL에 알려주는 숨겨진 비밀 때문에 풀 테이블 스캔이 발생한다.

    DETERMINISTIC으로 정의된 함수는 쿼리를 실행하기 위해 한 번만 스토어드 함수를 호출하고, 함수의 결괏값을 상수화해서 쿼리를 실행한다.
    하지만 NOT DETERMINISTIC으로 정의된 함수는 WHERE 절이 비교를 수행하는 레코드마다 매번 값이 재평가(호출)돼야 한다.
    NOT DETERMINISTIC 옵션으로 '입력값이 같더라도' '시점에 따라 스토어드 함수의 결과가 달라진다'고 MySQL 서버에 알려줬기 때문이다.

    따라서 NOT DETERMINISTIC으로 정의된 스토어드 함수는 절대 상수가 될 수 없다.

    풀 테이블 스캔을 유도하는 NOT DETERMINISTIC 옵션이 스토어드 함수의 기본 값이므로 조심해야 한다.
    따라서, 어떠한 형태로 스토어드 함수를 사용하더라도 DETERMINISTIC 옵션은 꼭 설정하자.
*/
