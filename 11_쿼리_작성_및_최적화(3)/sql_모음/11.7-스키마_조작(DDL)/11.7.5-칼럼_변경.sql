# 11.7.5 - 칼럼 변경

## 11.7.5.1 - 칼럼 추가
-- 8.0 버전부터 테이블의 컬럼 추가 작업은 대부분 INPLACE 알고리즘을 사용하는 온라인 DDL로 처리가 가능하다.
-- 뿐만 아니라 테이블의 제일 마지막 컬럼을 추가하는 경우에는 INSTANT 알고리즘으로 즉시 추가된다.

-- employees 테이블에서 제일 마지막 컬럼을 추가
ALTER TABLE employees ADD COLUMN emp_telno_1 VARCHAR(20),
    ALGORITHM = INSTANT;
DESC employees; -- 마지막에 emp_telno_1 가 추가되었다.

-- employees 테이블 중간에 새로운 컬럼을 추가
ALTER TABLE employees ADD COLUMN emp_telno_2 VARCHAR(20) AFTER emp_no,
    ALGORITHM = INPLACE, LOCK = NONE;
DESC employees; -- emp_no 컬럼 뒤에 emp_telno_2 컬럼이 추가되었다.

## 11.7.5.2 - 칼럼 삭제
-- 테이블의 컬럼 삭제는 테이블 리빌드를 필요로 하기 때문에 INPLACE 알고리즘으로만 컬럼을 삭제할 수 있다.
ALTER TABLE employees DROP COLUMN emp_telno_1, -- emp_telno_1 컬럼 삭제
    ALGORITHM = INPLACE, LOCK = NONE;
ALTER TABLE employees DROP emp_telno_2, -- emp_telno_@ 컬럼 삭제
    ALGORITHM = COPY, LOCK = SHARED;
DESC employees; -- emp_telno_1, 2 컬럼이 삭제되었다.

## 11.7.5.3 - 컬럼 이름 및 컬럼 타입 변경
-- 컬럼의 이름 변경
ALTER TABLE salaries CHANGE to_date end_date DATE NOT NULL,
    ALGORITHM = INSTANT; -- 컬럼의 이름만 변경하는 경우 INSTANT 알고리즘을 사용할 수 있다.
DESC salaries;

-- INT 컬럼의 타입을 VARCHAR 타입으로 변경
ALTER TABLE salaries MODIFY salary VARCHAR(20),
    ALGORITHM = INPLACE , LOCK = SHARED;
DESC salaries; -- salary 타입의 컬럼이 VARCHAR(20) 로 변경되었다.
-- 컬럼의 타입의 변경 중에선 읽기만 가능 쓰기 모두 대기하게 된다.
SELECT * from salaries; -- 현재 커넥션에선 대기 다른 커넥션에서 실행해보면 가능하다.
insert into salaries VALUES (4, 4, now(), now()); -- 현재, 다른 커넥션 모두 대기하게 된다.

-- VARCHAR 타입의 길이 확장
-- 현재 길이와 확장하는 길이의 관계에 따라 테이블 리빌드가 필요할 수도 있고 아닐수도 있다.
/*
    VARCHAR 나 VARBINARY 타입의 경우 컬럼의 최대 허용 사이즈는 메타데이터에 저장되지만 실제 컬럼이 가지는 값의 길이는 데이터 레코드의 컬럼 헤더에 저장된다.
    값의 길이를 위해서 사용하는 공간의 크기는 VARCHAR 컬럼의 최대 가질 수 있는 바이트 수만큼 필요하다.

    즉, 컬럼값의 길이 저장용 공간은 컬럼의 값이 최대 가질 수 있는 바이트 수가 칼럼의 값이 최대가질 수 있는 바이트 수가 255 이하인 경우 1 바이트
    256 이상인 경우 2바이트를 사용한다. (256 이상부터는 무조건 2바이트로 해결이 가능한가? 그 이상은 오버 플로우 페이지 라는 걸 사용하는 듯?)

    위의 상황과 같이 255 이하이면 테이블 리빌드가 필요하지 않고, 이 값이 변경되면 리빌드가 필요하다.
    계산하는 방법은 VARCHAR(10) 이면 4 * 10 = 40 bytes 가 필요하다. 이 값이 255만 안넘어가면 된다.
        - 4는 utf8mb4 에서 한 글자당 4바이트가 필요하다.
    즉, VARCHAR(10) 에서 VARCHAR(64) 로 변경하는 경우
        10 * 4 -> 64 * 4 ===> 40 -> 256 이므로 1바이트에서 2바이트로 변경된다.
    위와 같은 경우는 리빌드가 필요하다. 이걸 잘 계산한 뒤에 실행해야 겠다.
 */
ALTER TABLE employees MODIFY last_name VARCHAR(30) NOT NULL,
    ALGORITHM = INPLACE, LOCK = NONE;
DESC salaries;

-- VARCHAR 타입의 길이 축소
-- 길이를 축소하는 경우는 다른 타입으로 변경하는 경우와 같이 COPY 알고리즘을 사용해야 한다.
-- 스키마를 변경하는 중 해당 테이블의 변경은 허용되지 않으므로 LOCK은 SHARED 이상으로 사용해야 한다.
ALTER TABLE employees MODIFY last_name VARCHAR(10) NOT NULL,
    ALGORITHM = COPY, LOCK = SHARED;
DESC salaries;

-- 컬럼의 길이를 100에서 200으로 변경할 때 INPLACE 알고리즘이 사용 가능한지 확인하는 테스트
CREATE TABLE varchar_length_test (
    col_1       VARCHAR(100) CHARACTER SET 'utf8mb4',
    col_2       VARCHAR(10) CHARACTER SET 'utf8mb4'
) ENGINE = INNODB;
-- 256 이상인 컬럼에 대해선 INPLACE 알고리즘 적용 가능
ALTER TABLE varchar_length_test MODIFY col_1 VARCHAR(200),
    ALGORITHM = INPLACE, LOCK = NONE;
DESC varchar_length_test; -- col_1 VARCHAR(200) 으로 변경
-- ALGORITHM=INPLACE is not supported. Reason: Cannot change column type INPLACE. Try ALGORITHM=COPY. 에러 발생
ALTER TABLE varchar_length_test MODIFY col_2 VARCHAR(100),
    ALGORITHM = INPLACE, LOCK = NONE;



