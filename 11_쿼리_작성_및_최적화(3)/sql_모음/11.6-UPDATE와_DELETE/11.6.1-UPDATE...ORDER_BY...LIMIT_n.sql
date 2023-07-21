# 11.6.1 - UPDATE ... ORDER BY ... LIMIT n
-- 보통 UPDATE 와 DELETE 는 WHERE 조건절에 일치하는 모든 레코드를 업데이트 하는 것이 일반적이다.
/*
    MySQL 에서는 UPDATE 나 DELETE 문장에 ORDER BY 절과 LIMIT 절을 동시에 사용해
    특정 컬럼으로 정렬해서 상위 몇 건만 변경 | 삭제하는 것도 가능하다.
    단, 복제 서버에서 ORDER BY ... LIMIT 가 포함된 UPDATE 나 DELETE 문장을 실행하면 경고가 발생한다.
      - 바이너리 로그 포맷이 ROW 일 때는 문제가 되지 않는다. (STATEMENT 기반의 복제에서는 중의 필요)
      - 이유는 ORDER BY에 의해 정렬되더라도 중복된 값의 순서가 복제 소스 서버와 메인 서버에서 달라질 수 있기 때문이다.
        (프라이머리 키로 정렬하면 문제 없다.)
*/

SET binlog_format=STATEMENT;
DELETE FROM employees ORDER BY last_name LIMIT 10;
SHOW WARNINGS \G -- 경고 발생
