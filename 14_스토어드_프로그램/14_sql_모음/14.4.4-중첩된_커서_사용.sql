### 14.4.4 - 중첩된 커서 사용
-- 일반적으로 커서는 하나의 커서를 열고 사용이 긑나면 닫고 다시 새로운 커서를 열어서 사용하는 형태로 사용하지만,
-- 중첩된 루프 안에서 두 개의 커서를 동시에 열어서 사용해야 할 때도 있다.
-- 두 개의 커서를 동시에 열어서 사용할 때는 특별히 예외 핸들리에 주의해야 한다.

-- 아래 스토어드 프로시저를 예제를 살펴보자.
DELIMITER ;;
CREATE PROCEDURE sp_updateemployeehiredate()
BEGIN
    DECLARE v_dept_no CHAR(4); -- 첫 번째 커서로부터 읽은 부서 저장
    DECLARE v_emp_no INT; -- 두 번째 커서로부터 읽은 사원 번호 저장
    DECLARE v_no_more_rows BOOLEAN DEFAULT FALSE; -- 커서를 끝까지 읽었는지 여부를 체크하는 변수
    DECLARE v_dept_list CURSOR FOR SELECT dept_no FROM departments; -- 부서 정보를 읽는 첫 번째 커서
    -- 부서별 사원 1명을 읽는 두 번째 커서
    DECLARE v_emp_list CURSOR FOR SELECT emp_no
                                  FROM dept_emp
                                  WHERE dept_no = v_dept_no LIMIT 1;
    -- 커서의 레코드를 끝까지 다 읽은 경우에 대한 핸들러
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_no_more_rows := TRUE;

    OPEN v_dept_list;
    LOOP_OUTER: LOOP
        -- 외부 루프 시작
        FETCH v_dept_list INTO v_dept_no;
        IF v_no_more_rows THEN
            CLOSE v_dept_list;
            LEAVE loop_outer;
        END IF;

        OPEN v_dept_list;
        LOOP_INNER: LOOP
            FETCH v_emp_list INTO v_emp_no;
            -- 레코드를 모두 읽었으면 커서 종료 및 내부 루프를 종료
            IF v_no_more_rows THEN
                -- 반드시 no_more_rows를 FALSE로 변경, 그렇지 않으면 내부 루프 때문에 외부 루프까지 종료돼 버린다.
                SET v_no_more_rows := FALSE;
                CLOSE v_emp_list;
                LEAVE loop_inner;
            END IF;
        END LOOP loop_inner;
    END LOOP loop_outer;
END;;

-- 위의 스토어드 프로시저에서 각 커서에 대한 핸들러 처리가 보안된 스토어드 프로시저
CREATE PROCEDURE sp_updateEmployeeHiredate1()
BEGIN
    -- 첫 번째 커서로부터 읽은 부서 번호를 저장
    DECLARE v_dept_no CHAR(4);
    -- 커서를 끝까지 읽었는지를 나타내는 플래그를 저장
    DECLARE v_no_more_depts BOOLEAN DEFAULT FALSE;
    -- 부서 정보를 읽는 첫 번째 커서
    DECLARE v_dept_list CURSOR FOR SELECT dept_no FROM departments;
    -- 부서 커서의 레코드를 끝까지 다 읽은 경우에 대한 핸들러
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_no_more_depts := TRUE;

    OPEN v_dept_list;
    LOOP_OUTER: LOOP
        FETCH v_dept_list INTO v_dept_no;
        IF v_no_more_depts THEN
            -- 레코드를 모두 읽었으면 커서 종료 및 외부 루프 종료
            CLOSE v_dept_list;
            LEAVE loop_outer;
        END IF ;

        BLOCK_INNER: BEGIN -- 내부 프로시저 블록 시작
            -- 두 번째 커서로부터 읽은 사원 번호 저장
            DECLARE v_emp_no INT;
            -- 사원 커서를 끝가지 읽었는지 여부를 위한 플래그 저장
            DECLARE v_no_more_employees BOOLEAN DEFAULT FALSE;
            -- 부서별 사원 1명을 읽는 두 번째 커서
            DECLARE v_emp_list CURSOR FOR SELECT emp_no
                                          FROM dept_emp
                                          WHERE dept_no = v_dept_no LIMIT 1;
            -- 사원 커ㅓㅅ의 레코드를 끝까지 다 읽은 경우에 대한 핸들러
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_no_more_employees := TRUE;

            OPEN v_emp_list;
            LOOP_INNER: LOOP    -- 내부 루프 시작
                FETCH v_emp_list INTO v_emp_no;
                -- 레코드를 모두 읽었으면 커서 종료 및 내부 루프를 종료
                IF v_no_more_employees THEN
                    CLOSE v_emp_list;
                    LEAVE loop_inner;
                END IF ;
            END LOOP loop_inner;    -- 내부 루프 종료
            END block_inner;    -- 내부 프로시저 블록 종료
    END LOOP loop_outer;    -- 외부 루프 종료
END ;;
CALL sp_updateEmployeeHiredate1();
