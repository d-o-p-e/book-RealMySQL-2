### 14.2.2 - 스토어드 프로시저
-- 스토어드 프로시저는 서로 데이터를 주고바당야 하는 여러 쿼리를 하나의 그룹으로 묶어서 독립적으로 실행하기 위해 사용하는 것이다.
-- 배치 프로그램에서 첫 번째 쿼리의 결과를 이용해 두 번째 쿼리를 실행해야 할 때가 대푲거인 예다.
-- 스토어드 프로시저는 반드시 독립적으로 호출돼야 하며, SELECT, UPDATE 같은 SQL 문장에서 스토어드 프로시저를 참조할 수 없다.

#### 14.2.2.1 - 스토어드 프로시저 생성 및 삭제
-- CREATE PROCEDURE 명령으로 생성할 수 있다.
CREATE PROCEDURE sp_sum (IN param1 INTEGER, IN param2 INTEGER, OUT param3 INTEGER)
BEGIN
    SET param3 = param1 + param2;
END ;;

-- 스토어드 프로시저를 생서할 때 두 가지 주의 사항
/*
    1. 기본 반환값이 없다. 즉, 프로시저 내부에서 RETURN 같은 명령을 사용할 수 없다.
    2. 스토어드 프로시저의 각 파라미터는 다음의 3 가지 특성 중 하나를 지닌다.
        2.1 - IN 타입으로 정의된 파라미터는 입력 전용 파라미터를 의미한다. 외부에서 스토어드 프로그램을 호출할 때 프로시저에 값을 전달하는 용도.
        2.2 - OUT 타읍으로 정의된 파라미터는 출력 전용 파라미터다. 스토어드 프로시저의 실행이 완료되면 외부 호출자로 결과 값을 전달하는 용도
        2.3 - INOUT 타입으로 정의된 파라미터는 입력 및 출력 모두 사용할 수 있다.
*/

-- 스토어드 프로시저를 포함한 스토어드 프로그램을 사용할 때는 SQL 문장의 구분자를 변경해야 한다.
-- 일반적으로 MySQL 프로그램에서는 ";" 문자가 쿼리의 끝을 의미한다. 하지만, 스토어드 프로그램은 본문 내부에 무수히 많은 ";" 문자를 포함하므로
-- MySQL 클라이언트가 CREATE PROCEDURE 명령의 끝을 정확히 찾을 수 없다. 그래서 명령의 끝을 정확히 판별할 수 있게 별도의 문자열을 구부낮로 설정해야 한다.
-- 명령의 끝을 알려주는 종료 문자를 변경하는 명령어는 DELIMITER 이다.

-- 종료 문자를 ;; 로 변경
DELIMITER ;;
CREATE PROCEDURE sp_sum (IN param1 INTEGER, IN param2 INTEGER, OUT param3 INTEGER)
BEGIN
    SET param3 = param1 + param2;
END ;;
-- 스토어드 프로그램의 생성이 완료되면 다시 종료 문자를 기본 종료 문자인 ";"로 복구
DELIMITER ;

-- 스토어드 프로시저를 변경할 때는 ALTER PROCEDURE 명령을 사용하고, 삭제할 때는 DROP PROCEDURE 명령을 사용하면 된다.
-- 스토어드 프로시저에서 제공하는 보안 및 작동 방식과 관련된 특셩을 변경할 때만 ALTER PROCEDURE 명령을 사용할 수 있다.
-- sp_um 프로시저의 보안 옵션을 DEFINER 로 변경
ALTER PROCEDURE sp_sum SQL SECURITY DEFINER;

-- 스토어드 프로시저의 파라미터나 프로시저의 처리 내용을 변경할 때는 ALTER PROCEDURE 명령을 사용하지 못한다.
-- 이때는 DROP PROCEDURE 로 먼저 프로시저를 삭제한 후 다시 CREATE 해야 된다. - 이것이 유일한 방법이다.
DROP PROCEDURE sp_sum;

#### 14.2.2.2 - 스토어드 프로시저 실행
-- 스토어드 프로시저와 스토어드 함수의 큰 차이점 가운데 하나는 프로그램을 실행하는 방법이다.
-- 스토어드 프로시저는 SELECT 쿼리에 사용될 수 없으며, 반드시 CALL 명령어로 실행해야 한다.
-- IN 타입의 파라미터는 상숫값을 그대로 전달해도 무방하지만 OUT이나 INOUT 타입의 파라미터는 세션 변수를 이용해 값을 주고받아야 한다.

-- result 라는 이름으로 값을 0으로 초기화한 세션 변수 생성
SET @result = 0;
SELECT @result;

-- sp_sum 프로시저 실행
CALL sp_sum(1, 2, @result);
SELECT @result;

-- 자바나 C/C++ 같은 프로그래밍 언어에서는 위와 같이 세션 변수를 사용하지 않고 바로 OUT 이나 INOUT 타입의 변숫값을 읽어올 수 있다.
#### 14.2.2.3 - 스토어드 프로시저의 커서 반환
-- 명시적으로 커서를 파라미터로 전달받거나 반환할 수 없다. 하지만, 프로시저 내에서 커서를 오픈하지 않거나 SELECT 쿼리의 결과 셋을 패치하지 않으면
    -- 해당 쿼리의 결과 셋은 클라이언트로 바로 전송된다.
-- 프로시저 목록을 찾아보기 위한 쿼리
SHOW PROCEDURE STATUS WHERE db = 'real_my_sql_80_book';

-- 프로시저에서는 파라미터로 전달받은 사원 번호를 이용해 SELECT 쿼리를 실행했지만, 그 결과를 사용하지 않는다.
CREATE PROCEDURE sp_selectEmployees(IN in_empno INTEGER)
BEGIN
    SELECT * FROM employees WHERE emp_no = in_empno;
END;
-- 위의 프로시저 사용
CALL sp_selectEmployees(10001);
-- 바로 위의 예제에서 보았듯 OUT 변수를 사용하지도 않고 화면에 출력하지도 않았는데, 쿼리의 결과가 클라이언트로 전송된다.
-- 이를 JDBC 자바, NODE 사용할 수 있다. 하나의 스토어드 프로시저에서 2개 이상의 결과 셋을 반환할 수 있다.
-- 쿼리의 결과 셋을 클라이언트로 전송하는 기능은 스토어드 프로시저의 디버깅 용로도로 자주 사용한다.
-- 스토어드 프로시저는 메시지를 화면에 출력하는 기능이 없고, 또한 로그 파일에 기록하는 기능도 없다.
-- 이럴때 위에서 사용한 SELECT 쿼리의 결과 셋을 이용해 디버깅하기도 한다. 다음과 같이 사용할 수도 있다.

-- sp_sum 스토어드 프로시저를 디버깅 하면서 사용하기
DELIMITER ;;
CREATE PROCEDURE sp_sum (IN param1 INTEGER, IN param2 INTEGER, OUT param3 INTEGER)
BEGIN
    SELECT '> Stored procedure started.' AS debug_message;
    SELECT CONCAT(' > param1 : ', param1) AS debug_message;
    SELECT CONCAT(' > param2 : ', param2) AS debug_message;

    SET param3 = param1 + param2;
    SELECT '> Stored procedure completed.' AS debug_message;
END ;;
DELIMITER ;
CALL sp_sum(1, 2, @result); -- dataGrip 에선 나오지 않는다. 터미널에서 실행

#### 14.2.2.4 - 스토어드 프로시저 딕셔너리
-- 8.0 이전 버전까지는 스토어드 프로시저는 mysql 데이터베이스의 proc 테이블에 저장됐지만
-- 8.0 버전부터는 사용자에게 보이지 않는 시스템 테이블로 저장된다.
-- 확인하려면 information_schema DB의 ROUTINES 뷰를 통해 프로시저 정보를 조회할 수 있다.
-- PROCEDURE 쿼리까지 조회할 수 있다.
SELECT routine_schema, routine_name, routine_body, routine_definition
FROM information_schema.routines
WHERE routine_schema = 'real_my_sql_80_book'
  AND routine_type='PROCEDURE';

-- 다른 방식으로 조회하는 법, 간단하게 조회할 수 있다.
SHOW PROCEDURE STATUS WHERE db = 'real_my_sql_80_book';
SHOW FUNCTION STATUS WHERE db = 'real_my_sql_80_book';

