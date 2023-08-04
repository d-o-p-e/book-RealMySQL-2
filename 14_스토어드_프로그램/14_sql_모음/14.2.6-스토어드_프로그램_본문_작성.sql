### 14.2.6 - 스토어드 프로그램 본문(Body) 작성
-- 스토어드 프로그램은 생성하고 실행하는 방법에 조금씩 차이가 있지만
    -- 각 스토어드 프로그램으로 처리하려는 내용을 작성하는 본문부(BEGIN ... END 블록)는 모두 똑같은 문법을 사용한다.
-- 이제 모든 스토어드 프로그램이 본문에서 곹옹으로 사용할 수 있는 제어문을 살펴보자.

#### BEGIN ... END 블록과 트랜잭션
-- 스토어드 프로그램의 본문은 BEGIN 으로 시작해서 END 로 끝나며, 하나의 BEGIN END 블록은 또 다른 여러개의 BEGIN END 블록을 중첩해서 포함할 수 있다.
-- BEGIN ... END 블록 내에서 주의해야 할 것은 트랜잭션 처리다.
/*
    MySQL 에서 트랜잭션을 시작하는 명령으로는 다음 두 가지가 있다.
    - BEGIN
    - START TRANSACTION

    하지만, BEGIN ... END 블록 내에서 사용된 BEGIN 명령은 트랜잭션의 시작이 아니라 BEGIN ... END 블록의 시작 키워드인 BEGIN 으로 해석된다.
    따라서, 스토어드 프로그램의 본문에서 트랜잭션을 시작할 때는 START TRANSACTION 으로 사용해야 된다. (COMMIT ROLLBACK 은 똑같음)
    또한, 스토어드 프로시저나 이벤트의 본문에서만 트랜잭션을 사용할 수 있으며, 함수나 트리거에서는 트랜잭션을 적용할 수 없다.
*/

-- 스토어드 프로시저와 이벤트의 BEGIN ... END 블록 내에서 트랜잭션을 시작하고 종료하는 방법
-- 프로시저가 실행되면서 tb_hello 테이블에 레코드를 INSERT 하고 즉시 COMMIT 을 실행해 트랜잭션을 완료한다.
-- 아래처럼 프로시저 내부에서 COMMIT/ROLLBACK 명령으로 트랜잭션을 완료하면 프로시저를 호출한 외부에서 COMMIT/ROLLBACK 을 실행해도 아무런 의미가 없다.
CREATE PROCEDURE sp_hello (IN name VARCHAR(50))
BEGIN
    START TRANSACTION;
    INSERT INTO tb_hello VALUES (name, CONCAT('Hello', name));
    COMMIT;
END;;

-- 아래 프로시저는 외부에서 트랜잭션을 조유할 수 있지만, 프로시저 내부에서 트랜잭션을 완료하면 외부에서 조절할 수 없다.
CREATE TABLE tb_hello (name VARCHAR(100), message VARCHAR(100)) ENGINE = InnoDB;
CREATE PROCEDURE sp_hello (IN name VARCHAR(50))
BEGIN
    INSERT INTO tb_hello VALUES (name, CONCAT('Hello ', name));
END;

START TRANSACTION;
CALL sp_hello('Frist');
COMMIT;
SELECT * FROM tb_hello;

START TRANSACTION;
CALL sp_hello('Second');
ROLLBACK;
SELECT * FROM tb_hello; -- Second 가 Rollback 되었다.

#### 14.2.6.2 - 변수
-- 스토어드 프로그램의 BEGIN ... END 블록 사이에서 사용하는 변수는 사용자 변수와는 다르므로 혼동하면 안된다.
-- 아래에서부터 스토어드 프로그램에서 사용하는 변수를 로컬 변수라고 표현한다.
/*
    로컬 변수는 DECLARE 명령으로 정의되고 반드시 타입이 함께 명시돼야 한다.
    로컬 변수의 값을 할당하는 방법은 SET 명령 또는 SELECT ... INTO ... 문장으로 가능하다.
    로컬 변수는 현재 스토어드 프로그램의 BEGIN ... END 블록 내에서만 유효하며, 사용자 변수보다는 빠르며
        다른 쿼리나 스토어드 프로그램과의 간섭을 발생시키지 않는다.
    로컬 변수는 반드시 타입과 함께 정의되기 때문에 컴파일러 수준에서 타입 오류를 체크할 수 있다.
*/

-- 로컬 변수 정의
DECLARE v_name VARCHAR(50) DEFAULT 'Matt'; -- DEFAULT 값을 명시하지 않으면 NULL 로 초기화한다.
DECLARE v_email VARCHAR(50) DEFAULT 'matt@email.com';

-- 로컬 변수에 값을 할당
SET v_name = 'Kim', v_email = 'kim@email.com'; -- SET 명령으로 DECLARE 로 정의한 변수에 값을 할당

-- SELECT INTO 구문을 이용한 값의 할당
-- SELECT 명령은 반두스 1개의 레코드를 반환하는 SQL 이어야 한다.
-- 정확히 1건의 레코드가 보장되지 않는 쿼리에서는 커서를 사용하거나 SELECT 쿼리에 LIMIT 1과 같은 조건을 추가해서 사용해야 한다.
SELECT emp_no, first_name, last_name INTO v_empno, v_firstname, v_lastname -- SELECT 한 레코드의 컬럼 값을 로컬 변수에 할당
FROM employees
WHERE emp_no=10001
LIMIT 1;

-- 스토어드 프로그램의 입력 파라미터, 로컬 변수, 테이블 컬럼명 이 세 가지 모두 이름이 같을 수도 있다.
-- 이름이 모두 같을 때 우선순위는 다음과 같다.
/*
    1. DECLARE 로 정의한 로컬 변수
    2. 스토어드 프로그램의 입력 파라미터
    3. 테이블의 컬럼
*/
-- first_name 은 프로시저의 입력 파라미터의 이름으로도 사용 내부에서 정의 employees 테이블의 컬러명으로 사용되는 로컬 변수 예제
CREATE PROCEDURE same_variable_sp_hello (IN first_name VARCHAR(50))
BEGIN
    DECLARE first_name VARCHAR(50) DEFAULT 'Kim';
    SELECT CONCAT('Hello ', first_name) FROM employees LIMIT 1;
END;
CALL same_variable_sp_hello('Lee'); -- 로컬 변수의 값을 할당한 Kim 이 출력된다.

-- 따라서 변수명을 명확하게 구분하기 위해 변수명에 접두사(Prefix)를 사용하는 것도 좋은 방법이다.
-- 파라미터는 (p_) 로컬 변수는 (v_) 이런 식으로

#### 14.2.6.3 - 제어문
-- 스토어드 프로그램에서는 SQL 문과 달리 조건 비교 및 반복과 같은 절차적인 처리를 위해 여러 가지 제어 문장을 이용할 수 있다.

##### 14.2.6.3.1 IF ... ELSEIF ... ELSE ... END IF
CREATE FUNCTION sf_greatest(p_value1 INT, p_value2 INT)
    RETURNS INT
BEGIN
    IF p_value1 IS NULL THEN -- IF 문은 END IF 문으로 IF 블록을 종료해야 한다.
        RETURN p_value2;
    ELSEIF p_value2 IS NULL THEN
        RETURN p_value1;
    ELSEIF p_value1 >= p_value2 THEN
        RETURN p_value1;
    ELSE
        RETURN p_value2;
    END IF;
END;

##### 14.2.6.3.2 - CASE WHEN ... THEN ... ELSE ... END CASE
-- CASE WHEN 은 일반 프로그래밍에서 SWITCH 와 비슷한 형태의 제어문이다.
-- 다음과 같이 사용할 수 있다.
CASE 변수
    WHEN 비교대상값1 THEN 처리내용1
    WHEN 비교대상값2 THEN 처리내용2
    ELSE 처리내용3
END CASE;

CASE
    WHEN 비교조건식1 THEN 처리내용1
    WHEN 비교조건식2 THEN 처리내용2
    ELSE 처리내용3
END CASE;

-- CASE WHEN 문법을 ㅣㅇ용해 IF ... END IF 예제를 다시 작성
CREATE FUNCTION sf_greatest1 (p_value1 INT, p_value2 INt)
    RETURNS INT
BEGIN
    CASE
        WHEN p_value1 IS NULL THEN
            RETURN p_value2;
        WHEN p_value2 IS NULL THEN
            RETURN p_value1;
        WHEN p_value1 >= p_value2 THEN
            RETURN p_value1;
        ELSE
            RETURN p_value2;
    END CASE;
END;

##### 14.2.6.3.3 - 반복 루프
-- LOOP, REPEAT, WHILE 구문을 사용할 수 있다.
/*
    LOOP 문은 별도의 반복 조건을 명시하지 못한다.
    REPEAT 와 WHILE 문은 ㅂ나복 조건을 명시할 수 있다.

    LOOP 구문에서 반복 루프를 벗어나려면 LEAVE 명령을 사용하면 된다.
    REPEAT 문은 본문을 처리하고 반복 조건을 체크, WHILE 문은 반대로 실행된다.
*/

-- 반복 루프를 통해 팩토리얼을 구해보는 예제
CREATE FUNCTION sf_factorial1 (p_max INT) -- LOOP 문을 통해 팩토리얼 구하는 예제
    RETURNS INT
BEGIN
    DECLARE v_factorial INT DEFAULT 1;

    factorial_loop : LOOP
        SET v_factorial = v_factorial * p_max;
        SET p_max = p_max - 1;
        IF p_max <= 1 THEN
            LEAVE factorial_loop;
        END IF;
    END LOOP;

    RETURN v_factorial;
END;

CREATE FUNCTION sf_factorial2 (p_max INT) -- REPEAT 문을 통해 팩토리얼 구하는 예제
    RETURNS INT
BEGIN
    DECLARE v_factorial INT DEFAULT 1;
    REPEAT
        SET v_factorial = v_factorial * p_max;
        SET p_max = p_max - 1;
    UNTIL p_max <= 1 END REPEAT;

    RETURN v_factorial;
END;

CREATE FUNCTION sf_factorial3 (p_max INT) -- WHILE 문을 통해 팩토리얼 구하는 예제
    RETURNS INT
BEGIN
    DECLARE v_factorial INT DEFAULT 1;

    WHILE p_max > 1 DO
        SET v_factorial = v_factorial * p_max;
        SET p_max = p_max - 1;
    END WHILE;

    RETURN v_factorial;
END;

#### 14.2.6.4 - 핸들러와 컨디션을 이용한 에러 핸들링
/*
    핸들러는 거의 모든 SQL 문장의 처리 상태에 대해 핸드러를 등록할 수 있다.
    핸들러는 이미 정의한 커디션 또는 사용자가 정의한 컨디션을 어떻게 처리(핸들링)할지 정의하는 기능이다.
 */
/*
    컨디션은 SQL 문장의 처리 상태에 대해 별명을 붙이는 것과 같은 역할을 수행한다.
    컨디션은 꼭 필요한 것은 아니도 스토어드 프로그램의 가독성을 좀 더 높이는 요소로 생각할 수 있다.
*/

-- 핸들러를 이해하려면 MySQL 에서 사용하는 SQLSTATE 와 에러 번호(Error No)의 의미와 관계를 알고 있어야 한다.
##### 14.2.6.4.1 - SQLSTATE 와 에러 번호(Error No)
-- 일부로 에러를 만들어 보고 확인해보자.
SELECT * FROM error_table;
-- ERROR 1146 (42S02): Table 'error_table' doesn't exist
/*
    ERROR - NO
     - 4자리(현재까지) 숫자 값으로 구성된 에러 코드로, MySQL 에서만 유효한 에러 식별 번호다.
     - 즉, 1146이라는 에러 코드 값은 MySQL 에서는 '테이블이 존재하지 않는다'라고 의미하고 다른 DBMS 와는 호환되는 에러 코드는 아니다.

    SQL - STATE
     - 다섯 글자의 알파뱃과 숫자로 구성되며, 에러뿐만 아니라 여러 가지 상태를 의미하는 코드다.
     - 이 값은 DBMS 종류가 다르더라도 ANSI SQL 표준을 준수하는 DBMS 에서는 모두 똑같은 값을 가진다.
     - 즉, 이 값은 표준 값이라서 DBMS 벤더에 의존적이지 않다.
     - 대부분의 MySQL 에러 번호는 특정 SqlState 값과 매핑돼 있으며, 매핑되지 않는 에러번호는 SqlState 값이 'HY000'(General error)으로 설정된다.

    SqlState 값의 앞 2글자는 다음과 같은 의미를 가진다.
     - "00" 청상 처리됨 (에러 아님)
     - "01" 경고 메시지 (Warning)
     - "02" Not found (SELECT 또는 CURSOR 에서 결과가 없는 경우에만 사용됨)
     - 그 이외의 값은 DBMS 별로 할당된 각자의 에러 케이스를 의미

    ERROR - MESSAGE
     - 포매팅된 텍스트 문장으로, 사람이 읽을 수 있는 형태의 에러 메시지다. DBMS 벤더별로 내용이나 구조가 다르다.

    다음의 공식문서에서 자세히 확인할 수 있다.
    https://dev.mysql.com/doc/mysql-errors/8.0/en/server-error-reference.html
*/

/*
    스토어드 프로그램에서 핸들러를 정의할 때 에러 번호로 핸들러를 정의할 수 있지만,
    똑같은 원인에 대해 여러 개의 에러 번호를 가지는 경우도 있으므로 에러 번호보다는 "SQLSTATE"를 핸들러에 사용하는 것이 좋다.
*/

#### 14.2.6.4.2 - 핸들러
-- MySQL스토어드 프로그램을 사용할 때 발생하는 에러나 예외 상황에 대한 핸들링이 필요할 때 사용한다.
-- DECLARE ... HANDLER  구문을 이용해 사용할 수 있다.
/*
    HANDLER 의 문법

    DECLARE handler_type HANDLER
      FOR condition_value [, condition_value] ... handler_statements

    handler_type
        CONTINUE : handler_statements 를 실행하고 SP의 마지막 실행 지점으로 다시 돌아가서 나머지 코드를 처리한다.
        EXIT : 정의된 handler_statements 를 실행한 뒤에 핸들러가 정의된 BEGIN ... END 블록을 벗어난다.

    핸들러가 최상위 BEGIN ... END 블록에 정의 됐다면
        현재 스토어드 프로그램을 벗어나서 종료된다.

    스토어드 함수에서 EXIT 핸들러가 정의 됐다면
        이 핸들러의 handler_statements 부분에 함수의 반환 타입에 맞는 적절한 값을 반환하는 코드가 포함돼 있어야 한다.
*/

/*
    핸들러 정의 문장의 컨디션 값(Condition value)의 여러 가지 형태 - (SP, 스토어드 프로그램)

    - SQLSTATE 키워드 :
        SP이 실행되는 도중 어떤 이벤트가 발생했을 때 해당 이벤트의 SQLSTATE 값이 일치할 때 실행되는 핸들러를 정의할 때 사용
    - SQLWARNING 키워드 :
        SP에서 코드를 실행하던 중 경고(SQL Warning)가 발생했을 때 실행되는 핸들러를 정의할 때 사용
        SQLWARNING 키워드는 SQLSTATE 값이 "01"로 시작하는 이벤트를 의미
    - NOT FOUND 키워드 :
        SELECT 쿼리 문의 결과가 1건도 없거나 CURSOR 의 레코드를 마지막까지 읽은 뒤이 실행하는 핸들러를 정의할 때 사용
        NOT FUND 키워드는 SQLSTATE 값이 "02"로 시작되는 이벤트를 의미
    - SQLEXCEPTION 키워드 :
        경고(SQL Warning, "01")와 NOT FOUND("02"), "00"(정상 처리)으로 시작하는 SQLSTATE 이외의 모든 케이스를 의미하는 키워드
    - MySQL의 에러 코드 값을 직접 명시 :
        코드 실행 중 어떤 이벤트가 발생했을 때 SQLSTATE 값이 아닌 MySQL의 에러 번호 값을 비교해서 실행되는 핸들러를 정의할 때 사용

    - 사용자 정의 CONDITION 생성하고 해당 CONDITION 의 이름을 명시할 수 있다.
        이때는 SP에서 발생한 이벤트가 정의된 컨디션과 일치하면 핸들러의 처리 내용을 수행한다.
        condition_value 는 구분자(",")를 이용해 여러 개를 동시에 나열할 수도 있다.
        값이 "00000"인 SQLSTATE 와 에러 번호 0은 모두 정상적으로 처리됐음을 의미하는 값이라서 condition_value 값으로 사용하면 안 된다.
*/

-- handler_statements 단순한 명령문 하나만 사용할 수도 있으며, BEGIN ... END 로 감싸 여러 명령문이 포함된 블록을 작성할 수도 있다.
-- 간단한 핸들러 정의 문장을 살펴보자.

-- SQLSTATE 가 "00", "01", "02" 이외의 값으로 시작하는 에러가 발생했을 때 error_flag 로컬 변수의 값을 1로 설정하고,
-- 마지막 실행했던 SP의 코드로 돌아가서 계속 실행(CONTINUE)하게 하는 핸들러.
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET error_flag = 1;

-- SQLSTATE 가 "00", "01", "02" 이외의 값으로 시작하는 에러가 발생했을 때
-- 핸들러의 BEGIN ... END 블록으로 감싼 ROLLBACK 과 SELECT 문장을 실행한 후 에러가 발생하는 코드가 포함된 BEGIN ... END 블록을 벗어난다.
-- 만약, 에러가 발생했던 코드가 SP의 최상위 블록에 있엇다면 SP은 종료된다.
/*
    스토어드 프로시저에서는 아래 예제처럼 결과를 읽거나, 사용하지 않는 SELECT 쿼리가 실행되면 MySQL서버는 이 결과를 직시 클라이언트로 전송한다.
    그래서, SP을 실행하는 도중에 문제가 있으면 사용자의 화면에 'Error occurred - terminating' 메시지가 출력된다.
    SELECT 를 통해 클라이언트 화면에 표시되는 방식은 스토어드 프로시저에서의 디버깅 용도로만 사용할 수 있고,
    다른 스토어드 함수나, 트리거, 이벤트에서는 이런 결과 셋을 반환하는 기능을 사용할 수 없다.
*/
DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
ROLLBACK;
SELECT 'Error occurred - terminating';
END ;;

-- 에러 번호가 1022, 1062 인 예외가 발생했을 때 클라이언트로 'Duplicate key in index'라는 메시지를 출력한다.
-- 메시지를 출력하고 SP의 원래 실행 지점으로 돌아가서 나머지 코드를 실행한다.
-- 이 예제 또한 SELECT 쿼리 문장을 이용해 커서를 호출자에게 반환하는 것이라서 스토어드 프로시저에서만 사용할 수 있다. (핸들러 자체는 사용할 수 있음)
DECLARE CONTINUE HANDLER FOR 1022, 1062 SELECT 'Duplicate key in index';

-- SQLSTATE가 23000인 이벤트가 발생했을 때 클라이언트로 Duplicate key in index 라는 결과 셋을 출력하고, SP의 원래 지점으로 돌아가 CONTINUE 한다.
-- MySQL에서 중복 키 오류는 여러 개의 에러 번호를 가지고 있으므로 1022, 1062 보다 SQLSTATE 값을 명시(여기선 '23000')하는 것이 좀 더 좋다.
# DECLARE CONTINUE HANDLER FOR SQLSTATE '23000' SELECT 'Duplicate key in index';
CREATE PROCEDURE duplicate_key_handler_test ()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '23000' SELECT 'Duplicate key in index test 중'; -- 핸들러 정의
    INSERT INTO employees VALUES (10001, NOW(), 'test', 'test', 1, now());
END ;;
CALL duplicate_key_handler_test(); -- Duplicate key in index test

-- SELECT 문을 실행했지만 결과 레코드가 없거나, CURSOR 의 결과 셋에서 더는 읽어올 레코드가 남지 않았을 때
-- process_done 로컬 변숫값을 1로 설정하고 스토어드 프로그램의 마지막 실행 지점으로 돌아가서 나머지 코드를 실행하는 예제
DECLARE CONTINUE HANDLER FOR NOT FOUND SET process_done = 1
-- 위의 예제랑 똑같은데 SQLSTATE를 이용하는 방식 - SQLSTATE 가 '02000' 이면 NOT FOUND 와 똑같다.
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET process_done = 1
-- 위랑 똑같은데, MySQL에러 번호를 이용한 방식 - MySQL의 '1329' 에러 코드는 NOT FOUND 와 똑같다.
    DECLARE CONTINUE HANDLER FOR 1329 SET process_done = 1;

-- SQLWARNING, SQLEXCEPTION이 발생하면 모두 ROLLBACK 하고 클라이언트 화면에 에러와 경고 메시지를 출력한 뒤 SP 종료 예제
DECLARE EXIT HANDLER FOR SQLWARNING, SQLEXCEPTION
BEGIN
ROLLBACK;
SELECT 'Process terminated, Because error';
SHOW ERRORS;
SHOW WARNINGS;
END;

##### 14.2.6.4.3 - 컨디션(Condition)
-- MySQL핸들러는 어떤 조건(이벤트)이 발생했을 때 실행할지 명시하는 여러 방법이 있는데, 그중 하나가 컨디션이다.
/*
    단순히 MySQL의 에러 번호나 SQLSTATE 숫자 값만으로 어떤 조건을 의미하는지 이해하기 어려울 수도 있는데,
    각 에러 번호나 SQLSTATE 가 어떤 의미인지 예측할 수 있는 이름을 만들어 두면 더 쉽게 코드를 이해할 수 있다.
    이러한 조건의 이름을 등록하는 것이 컨디션이다.
    SQLWARNING, SQLEXCEPTION, NOT FOUND 등은 MySQL이 미리 정의해 둔 컨디션이라고 볼 수 있다.
*/

-- 간단히 컨디션을 정의하는 방법
DECLARE 컨디션_이름 CONDITION FOR condition_value
-- 컨디션_이름은 부여하고 싶은 이름을 지정하면 되고, condition_value를 부여하는 방법은 다음과 같다.
/*
    condition_value는 2가지 방법

    - MySQL의 에러 번호를 사용할 때는 contition_value에 바로 MySQL의 에러 번호를 입력하면 된다.
        CONDITION을 정의할 때는 에러 코드의 값을 여러 개 동시에 명시할 수 없다.
    - SQLSTATE를 명시하는 경우에는 SQLSTATE 키워드를 입력하한 뒤 SQLSTATE값을 입력하면 된다.
*/
-- MySQL 에러 번호를 이용한 컨디션 예
DECLARE mysql_error_number_dup_key CONDITION FOR 1062;
-- SQLSTATE를 이용해 컨디션을 정하는 예
DECLARE sqlstate_number_dup_key CONDITION FOR SQLSTATE '02000';

##### 14.2.6.4.4 - 컨디션을 사용하는 핸들러 정의
-- 스토어드 함수에서 컨디션을 사용하는 예제
-- 예제를 보기 전에 스토어드 함수를 만드려면 아래 조건을 확인해 봐야 한다.
SHOW VARIABLES LIKE 'log_bin_trust_function_creators'; -- ON(1) 이어야 한다.
SET GLOBAL log_bin_trust_function_creators = 1;
-- SET GLOBAL log_bin_trust_function_creators = 0;

-- employees 테이블에 INSERT 하는 예제인데, emp_no가 이미 있는 숫자라 이 함수를 호출할 때마다 -1이 표시돼야 한다.
-- 만약, 10001 emp_no를 지우면 1이 화면에 표시되고, 해당 값이 INSERT 된다.
DELIMITER //
CREATE FUNCTION sf_testfunc()
    RETURNS BIGINT
BEGIN
    DECLARE dup_key CONDITION FOR 1062;
    DECLARE EXIT HANDLER FOR dup_key
        BEGIN
            RETURN -1;
        END;

    INSERT INTO employees VALUES (10001, now(), 'test', 'test', 1, now());
    RETURN 1;
END//
DELIMITER ;
SELECT sf_testfunc(); # employess 테이블의 empno가 10001인 값은 이미 존재하므로 -1이 나와야 된다.

#### 14.2.6.5 - 시그널을 이용한 예외 발생
-- 시그널(SIGNAL)을 사용해 예외를 발생시킬 수 있다. 프로그래밍 언어에서 보자면 핸들러는 catch 구문, 시그널은 throw 구문으로 이해하면 된다.
-- 시그널 구문은 5.5 버전부터 지원된 기능이다. 이 전에는 존재하지 않는 테이블을 SELECT 하는 식으로 에러를 한들었다.

-- 나눗셈 연산의 제수가 0이거나 NULL이면 에러를 전달하기 위한 예제
-- 5.5 버전 이전에서 존재하지 않는 스토어드 프로시저를 호출해 에러를 내는 상황 - 읽기 어렵다.
DELIMITER //
CREATE FUNCTION sf_divide_old_style (p_dividend INT, p_divisor INT)
    RETURNS INT
BEGIN
    IF p_divisor IS NULL THEN
        CALL __undef_procedure_divisor_is_null();
    ELSEIF p_divosor=0 THEN
        CALL __undef_procedure_divisor_is_0();
    ELSEIF p_dividend IS NULL THEN
        RETURN 0;
    END IF;
    RETURN FLOOR(p_dividend / p_divisor);
END//
SELECT sf_divide_old_style(1, NULL); -- undef_procedure_divisor_is_null 이 없다는 에러 발생

-- 5.5 버전 이후에서 위랑 같은 예제를 SIGNAL 로 구현하는 법
DELIMITER //
CREATE FUNCTION sf_divide_80_style (p_dividend INT, p_divisor INT)
    RETURNS INT
BEGIN
    DECLARE null_divisor CONDITION FOR SQLSTATE '45000';

    IF p_divisor IS NULL THEN
        SIGNAL null_divisor -- SIGNAL의 조건은 위에서 명시한 바와 같이 SQLSTATE로 정의되어 있어야 한다.
            SET MESSAGE_TEXT = 'Divisor can not be null', MYSQL_ERRNO = 9999;
    ELSEIF p_divisor=0 THEN
        SIGNAL SQLSTATE '45000' -- '45000'은 '정의되지 않은 사용자 오류' 정도의 의미를 가지는 값이다.
            SET MESSAGE_TEXT = 'Divisor can not be 0', MYSQL_ERRNO = 9998;
    ELSEIF p_dividend IS NULL THEN
        SIGNAL SQLSTATE '01000'
            SET MESSAGE_TEXT = 'Dividend is null, so regarding dividend as 0', MYSQL_ERRNO = 9997;
        RETURN 0;
    END IF;

    RETURN FLOOR(p_dividend / p_divisor);
END //
SELECT sf_divide_80_style(NULL, 1); -- 0 (경고)
show warnings;
SELECT sf_divide_80_style(2, 1); -- 2
SELECT sf_divide_80_style(2, NULL); -- Divisor can not be null 에러 메시지 출력
SELECT sf_divide_80_style(2, 0); -- Divisor can not be 0 에러 메시지 출력

##### 14.2.6.5.2 - 핸들러 코드에서 SIGNAL 사용
-- 핸들러는 SP에서 에러나 예외에 대한 처리를 담당하는데, 핸들러 코드에서 SIGNAL 명령을 사용해 에러를 다른 사용자 정의 예외로 변환해서 던지는 것도 가능하다.

-- employees 테이블에서 num을 입력 받고, 1개의 레코드도 삭제되지 않으면 에러 발생
-- 핸들러를 이용해 한 건도 삭제되지 않으면 에러를 발생시킨다. 핸들러에서 발생한 에러의 내용을 무시하고 SQLSTATE가 45000 에러를 다시 발생시킨다.
-- 삭제된 레코드의 건수가 한 건이 아니라면 시그널 명령으로 '45000'에러를 또 발생시킨다.
DELIMITER //
CREATE PROCEDURE sp_remove_user (IN p_userid INT)
BEGIN
    DECLARE v_affectedrowcount INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Can not remove user information', MYSQL_ERRNO = 9999;
        END ;
    -- 사용자 정보 삭제
    DELETE FROM employees WHERE emp_no = p_userid;
-- 위에서 실행된 DELETE 쿼리로 삭제된 레코드 건수 확인
    SELECT ROW_COUNT() INTO v_affectedrowcount;
-- 삭제된 레코드 건수가 1건이 아닌 경우 에러 발생
    IF v_affectedrowcount <> 1 THEN
        SIGNAL SQLSTATE '45000';
    END IF;
END //
CALL sp_remove_user(12); -- Can not remove user informaion 에러

#### 14.2.6.6 - 커서
-- 일반적인 프로그래밍 언어에서 SELECT 쿼리의 결과를 사용하는 방법과 거의 흡사.
-- 스토어드 프로그램의 커서는 JDBC 프로그램에서 자주 사용하는 ResultSet이랑 비슷하다.
-- PHP 프로그램에서는 mysql_query() 함수로 반환되는 결과와 똑같다.
-- 하지만 SP에서의 커서는 프로그래밍 언어에서 사용하는 ResultSet에 비해 기능이 제약적이다.
/*
    SP 커서의 제약사항 두 가지

    - SP의 커서는 전 방향(전진) 읽기만 가능하다.
    - SP에서는 커서의 컬럼으 바로 업데이트 하는 것(Updateble ResultSet)이 불가능하다.
*/
/*
    DBMS의 커서는 센서티브 커서와 인센서티브 커서로 구분할 수 있다.

    센서티브(Sensitive) 커서 :
        - 일치하는 레코드에 대한 정보를 실제 레코드의 포인터만으로 유지하는 형태
        - 커서를 이용해 컬럼의 데이터를 변경하거나 삭제하는 것이 가능.
        - 컬럼의 값이 변경돼서 커서를 생성한 SELECT 쿼리의 조건에 더는 일치하지 않거나 레코드가 삭제되면 커서에서도 즉시 반영
        - 별도로 임시 테이블로 레코드를 복사하지 않기 때문에 커서의 오픈이 빠르다.

    인센서티브(Insensitive) 커서 :
        - 일치하는 레도르를 별도의 임시 테이블로 복사해서 가지고 있는 형태
        - SELECT 쿼리에 부합되는 결과를 우선적으로 임시 테이블로 복사해야 하기 때문에 느림
        - 이미 임시테이블로 복사된 데이터를 조회하는 것이라서 커서를 통해 값을 변경하거나 레코드를 삭제하는 작업이 불가능
        - 다른 트랜잭션과의 충돌은 발생하지 않는다.

    센서티브 인센서티브 혼용해서 사용하는 방식 - 어센서티브(asensivive) 라고 하는데, MySQL의 SP에서 정의되는 커서는 여기에 속한다.
    그래서, MySQL의 커서는 데이터가 임시 테이블로 복사될 수도 있고, 아닐 수도 있다.
    그렇다고 커서가 센서티브인지 인센서티브인지 알 수 없으며, 결론적으로 커서를 통해 컬럼을 삭제하거나 변경하는 것이 불가능하다.
*/
/*
    커서의 사용 방식

    1. SP에서 SELECT 쿼리 문장으로 커서를 정의
    2. 정의된 커서를 오픈(OPEN)하면 커서로 정의된 쿼리가 MySQL 서버에서 실행되고 결과를 가져온다.
    3. 오픈된 커서는 패치(FETCH) 명령으로 레코드 단위로 읽어서 사용할 수 있음.
    4. 사용이 완료된 후에 CLOSE 명령으로 커서를 닫으면 관련 자원이 모두 해제된다.
*/
DELIMITER &&
CREATE FUNCTION sf_emp_count(p_dept_no VARCHAR(10) CHARACTER SET utf8mb4)
    RETURNS BIGINT
BEGIN
    DECLARE v_total_count INT DEFAULT 0; -- 사원 번호가 20000보다 큰 사원의 수를 누적하기 위한 변수
    DECLARE v_no_more_date TINYINT DEFAULT 0; -- 커서에 더 읽어야 할 레코드가 남아 있는지 여부를 위한 플래그 변수
    DECLARE v_emp_no INTEGER; -- 커서를 통해 SELECT된 사원 번호를 임시로 담아 둘 변수
    DECLARE v_from_date DATE; -- 커서를 통해 SELECT된 사원의 입사 일자를 임시로 담아 둘 변수
    -- v_emp_list라는 이름으로 커서 정의
    DECLARE v_emp_list CURSOR FOR
        SELECT emp_no, from_date FROM dept_emp WHERE dept_no = p_dept_no;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_no_more_date = 1; -- 커서로부터 더 읽을 데이터가 있는지 플래그 변경을 위한 핸들러

    -- 정의된 v_emp_list 커서 오픈
    OPEN v_emp_list;
    REPEAT
        FETCH v_emp_list INTO v_emp_no, v_from_date; -- 커서로부터 레코드를 한 개씩 읽어서 변수에 저장
        IF v_emp_no > 20000 THEN
            SET v_total_count = v_total_count + 1;
        END IF;
    UNTIL v_no_more_date END REPEAT;

    -- v_emp_list 커서를 닫고 관련 자원을 반납
    CLOSE v_emp_list;

    RETURN v_total_count;
END &&
DELIMITER ;
drop function sf_emp_count;
SELECT sf_emp_count('d002');
-- 아래와 같은 에러가 나오는데, 이유를 모르겠다.
-- CURSOR를 생성할 때 dept_no = p_dept_no 이 부분에서 에러가 나는거 같은데, 왜 그렇지..? 문자 집합의 형식이 달라서 그런거 같은데, 어떻게 맞추지?
-- [HY000][1267] Illegal mix of collations (utf8mb4_general_ci,IMPLICIT) and (utf8mb4_0900_ai_ci,IMPLICIT) for operation '='

select * From dept_emp;
desc dept_emp;
select emp_no, from_date from dept_emp where dept_no = 'd002';
select count(*) from dept_emp where dept_no = 'd001' AND emp_no > 20000;
