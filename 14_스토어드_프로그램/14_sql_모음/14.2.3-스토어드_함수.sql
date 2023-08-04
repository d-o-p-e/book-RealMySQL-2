### 14.2.3 - 스토어드 함수
-- 스토어드 함수는 하나의 SQL 문자을 작성이 불가능한 기능을 하나의 SQL 문장으로 구현해야 할 때 사용한다.
/*
    부서별로 가장 최근에 배속된 사원을 2명씩 가져오는 기능을 생각해보자.
    dept_emp 테이블의 데이터를 부서별로 그루핑하는 것까지는 가능하지만,
    해당 부서별로 최근 2명씩 잘라서 가져오는 방법은 없다.
    이럴 때 부서 코드를 인자로 입력받아 최근 2명의 사원 번호만 SELECT 한 뒤 문자열로 결합해서 변환하는 함수 만든다.
*/

-- 부서별로 최근에 배속된 사원 2명씩 가져오는 함수가 있다고 가정하면 아래처럼 사용하면 된다.
SELECT dept_no, sf_getRecentEmp(emp_no) -- 동작하진 않지만 대충 아래와 같은 형태로 사용하면 될 듯?
FROM dept_emp
GROUP BY dept_no;

DROP FUNCTION IF EXISTS sf_getRecentEmp;
CREATE FUNCTION sf_getRecentEmp(param1 VARCHAR(10))
    RETURNS VARCHAR(20)
BEGIN
    DECLARE result VARCHAR(20);
    set result = (SELECT first_name FROM employees WHERE emp_no=param1 LIMIT 1);
    RETURN result;
END;

/*
    참고
    5.7 버전까지는 위 예제와 같이 특정 그룹별로 몇 건씩만 레코드를 조회하는 기능을
    스토어드 함수의 도움 없이 단일 SQL 문으로 작성할 수 있는 방법은 없다.
    하지만, 8.0 버전부터는 래터럴 조인이나 윈도우 함수를 이용해 구현할 수 있다.
*/
-- SQL 문장과 관계없이 별도로 실행되는 기능이라면 굳이 스토어드 함수를 개발할 필요가 없다.
-- 독립적으로 실행돼도 된다면 스토어드 프로시저를 사용하는 것이 좋다. 이유는 스토어드 함수는 프로시저보다 제약 사항이 더 많기 때문에 그렇다.
-- 스토어드 프로시저와 함수를 비교해봤을 때 함수의 유일한 장점은 SQL 문장의 일부로 사용할 수 있다는 점이다.

#### 14.2.3.1 - 스토어드 함수 생성 및 삭제
-- 스토어드 함수는 CREATE FUNCTION 명령으로 생성할 수 있으며, 모든 입력 파라미터는 읽기 전용이라서 IN 이나 OUT, INOUT 같은 형식을 지정할 수 없다.
-- 스토어드 함수는 반드시 정의부에 RETURNS 키워드를 이용해 반환되는 값의 타입을 명시해야 한다.

-- 두 파라미터를 입력받고 그 합을 구한 뒤 반환하는 스토어드 함수
DELIMITER //
CREATE FUNCTION sf_sum(param1 INTEGER, param2 INTEGER)
    RETURNS INTEGER
BEGIN
    DECLARE param3 INTEGER DEFAULT 0;
    SET param3 = param1 + param2;
    RETURN param3;
END//
DELIMITER ;

SELECT sf_sum(1, 2);

-- 함수가 실행되지 않는다면 아래의 값을 수정해야 한다.
SHOW GLOBAL VARIABLES LIKE 'log_bin_trust_function_creators';
SET GLOBAL log_bin_trust_function_creators = 1; -- ON
-- SET GLOBAL log_bin_trust_function_creators = 0; -- OFF

-- 스토어드 함수와 프로시저의 차이
/*
    함수는 정의부에 RETURNS 로 반환되는 값의 타입을 명시해야 한다.
    함수 본문 마지막에 정의부에 지정된 타입과 동일한 타입의 값을 RETURN 명령으로 반환해야 한다.

    프로시저와 달리 함수의 본문에선 아래와 같은 사항을 사용하지 못한다.
     - PREPARE 와 EXECUTE 명령을 이용한 프리페어 스테이트먼트를 사용할 수 없다.
     - 명시적 또는 묵시적인 ROLLBACK/COMMIT 을 유발하는 SQL 문장을 사용할 수없다.
     - 재귀 호출을 사용할 수없다.
     - 스토어드 함수 내에서 프로시저를 호출할 수 없다.
     - 결과 셋을 반환하는 SQL 문장을 사용할 수 없다.
*/
SELECT * FROM employees LIMIT 2;
-- 결과 셋을 패치(Fetch)하지 않아서 결과 셋이 클라이언트로 전송되는 스토어드 함수를 생성하면 에러 발생 테스트
CREATE FUNCTION sf_result_test()
    RETURNS INTEGER
BEGIN
    DECLARE res INTEGER DEFAULT 0;
    SELECT 'Start stored function' AS debug_message;
    RETURN res;
END; -- Not allowed to return a result set from a function 에러 발생

-- 프로시저와 마찬가지로 함수도 ALTER FUNCTION 명령을 사용할 수 있지만 단지 스토어드 함수의 특성만 변경할 수 있다.
ALTER FUNCTION sf_sum SQL SECURITY DEFINER;
SELECT sf_sum(1, 2);

#### 14.2.3.2 - 스토어드 함수 실행
-- 위에서 사용했듯이 사용하면 된다.
SELECT sf_sum(1, 2) AS sum;

