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
