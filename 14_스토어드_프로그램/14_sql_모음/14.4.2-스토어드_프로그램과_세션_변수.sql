
### 14.4.2 - 스토어드 프로그램과 세션 변수
-- 스토어드 프로그램내에서 사용자 변수를 이용해 처리할 수도 있지만, 가능한 한 스토어드 프로그램의 로컬 변수를 사용하자.
-- 아래 예제에선 세션 변수를 이용해 스토어드 함수를 사용할 수 있다는 예제인데, 가능하 한 스토어드 함수 내에서 로컬 변수를 사용하자.
CREATE FUNCTION sf_getsum(p_arg1 INT, p_arg2 INT)
    RETURNS INT
BEGIN
    DECLARE v_sum INT DEFAULT 0;
    SET v_sum = p_arg1 + p_arg2;
    SET @V_sum = v_sum;

    return v_sum;
END;

SELECT sf_getsum(1, 2); -- 3
SELECT @v_sum; -- 3

-- SP에서 프리페어 스테이트먼트를 실행하려면 세션 변수를 사용할 수 밖에 없다. 이 경우를 제외하고 로컬 변수로 가자
