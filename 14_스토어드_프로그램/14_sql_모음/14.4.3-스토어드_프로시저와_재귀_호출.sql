### 14.4.3 - 스토어드 프로시저와 재귀 호출
-- SP에서 재구 ㅣ호출을 사용할 수 있는데, 이는 스토어드 프로시저에서만 사용 가능하다. (함수, 트리거, 이벤트에서 사용 불가)
-- 재귀 호출 스택이 있어 너무 많이 반복해서 호출되면 메모리 공간이 부족해 오류가 발생한다.
-- 이러한 재귀 호출의 문제를 막기 위해 최대 몇 번까지 재귀 호출을 허용할지 설정하는 max_sp_recursion_depth 라는 시스템 변수가 있다.
-- max_sp_recursion_depth의 기본 값은 0이므로 사용하려면 변경한 다음 사용해야 한다.
-- 아니면 필요한 설정값을 프로시저 내부에서 변경하는 것도 오류를 막는 방법이다.
SELECT @@max_sp_recursion_depth; -- 0

DELIMITER //
CREATE PROCEDURE sp_getfactorial(IN p_max INT, OUT p_sum INT)
BEGIN
    SET MAX_SP_RECURSION_DEPTH = 50; -- 최대 재귀 호출 횟수 50으로 지정
    SET p_sum = 1;

    IF p_max > 1 THEN
        CALL sp_decreaseandmultiply(p_max, p_sum);
    END IF;
END//

CREATE PROCEDURE sp_decreaseandmultiply(IN p_current INT, INOUT p_sum INT)
BEGIN
    SET p_sum = p_sum * p_current;
    if p_current > 1 THEN
        CALL sp_decreaseandmultiply(p_current - 1, p_sum);
    END IF;
END//
DELIMITER;

CALL sp_getfactorial(10, @factorial);
SELECT @factorial; -- 3628800 (책에선 120 이라고 나오는데, 잘 못 표기된거 같다.)
