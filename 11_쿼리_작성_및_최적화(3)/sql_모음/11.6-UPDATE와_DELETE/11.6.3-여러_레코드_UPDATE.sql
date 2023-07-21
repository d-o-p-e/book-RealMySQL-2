# 11.6.3 - 여러 레코드 UPDATE
-- 하나의 UPDATE 문장으로 여러 개의 레코드를 업데이트하는 경우 모든 레코드를 동일한 값으로만 업데이트 할 수 있다.
UPDATE departments SET emp_count = 10;
UPDATE departments SET emp_count = emp_count + 10;

-- 8.0 버전부터는 레코드 생성(Row Constructor) 문법을 이용해 레코드별로 서로 다른 값을 업데이트 할 수 있다.
CREATE TABLE user_level (
    user_id     BIGINT NOT NULL,
    user_lv     INT NOT NULL,
    created_at  DATETIME NOT NULL,
    PRIMARY KEY (user_id)
);

UPDATE user_level ul
    INNER JOIN (VALUES ROW(1, 1),
                       ROW(2, 4)) new_user_level (user_id, user_lv)
                                  ON new_user_level.user_id = ul.user_id
    SET ul.user_lv = ul.user_lv + new_user_level.user_lv;
SELECT * FROM user_level;





