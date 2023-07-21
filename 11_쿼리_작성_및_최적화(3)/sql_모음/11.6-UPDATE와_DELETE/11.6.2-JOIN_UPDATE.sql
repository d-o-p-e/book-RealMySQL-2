# 11.6.2 - JOIN UPDATE
-- JOIN UPDATE 예제를 위한 테이블 생성
CREATE TABLE tb_test3 (
    emp_no  INT,
    first_name  VARCHAR(14),
    PRIMARY KEY (emp_no)
);
INSERT INTO tb_test3 VALUES (10001, NULL), (10002, NULL), (10003, NULL), (10004, NULL);
SELECT * FROM tb_test3;
-- 테이블의 조인 순서에 때라 UPDATE 문장의 성능이 달라질 수 있다. -> 사용하기 전에 실행 계획을 살펴보자
UPDATE tb_test3 t3, employees e
    SET t3.first_name = e.first_name
WHERE e.emp_no = t3.emp_no;
SELECT * FROM tb_test3;

-- GROUP BY가 포함된 JOIN UPDATE 에 대해 알아보자.
-- 테스트를 목적으로 departments 테이블에 emp_count 컬럼을 추가하자. (해당 부서에 소속된 사원의 수를 저장하기 위한 컬럼)
ALTER TABLE departments ADD emp_count INT;
-- JOIN UPDATE 를 사용할 경우 GROUP BY 나 ORDER BY 를 사용하지 못한다. 만약 사용하면 에러가 발생한다.
UPDATE departments d, dept_emp de
    SET d.emp_count = COUNT(*)
WHERE de.dept_no = d.dept_no
GROUP BY de.dept_no; -- JOIN UPDATE 사용 시 GROUP BY 사용 못함 에러 발생

-- 서브 쿼리를 활용해서 JOIN UPDATE 문장을 다시 작성하자
-- 서브쿼리로 dept_emp 테이블을 dept_no 로 그루핑하고, 그 결과를 파생 테이블로 저장한다.
-- 그리고 그 결과를 departments 테이블을 조인해 departments 테이블의 emp_count 컬럼에 업데이트 한 것이다.
-- 조인 파트에서 봤듯이 일반 테이블이 조인될 때는 임시 테이블이 드라이빙 테이블이 되는 것이 일반적으로 성능이 더 좋다.
EXPLAIN UPDATE departments d,
    (SELECT de.dept_no, COUNT(*) AS emp_count
     FROM dept_emp de
     GROUP BY de.dept_no) dc
  SET d.emp_count = dc.emp_count
WHERE dc.dept_no = d.dept_no;
SELECT * FROM departments;

-- 만약 조인의 방향을 정하고 싶다면 STRAIGHT_JOIN 이라는 키워드를 사용하면 된다.
-- STRAIGHT_JOIN 키워드 왼쪽에 명시된 테이블이 드라이빙 테이블이 되며, 오른쪽의 테이블은 드리븐 테이블이 된다.
EXPLAIN UPDATE (SELECT de.dept_no, COUNT(*) AS emp_count
        FROM dept_emp de
        GROUP BY de.dept_no) dc
STRAIGHT_JOIN departments d ON dc.dept_no = d.dept_no
  SET d.emp_count = dc.emp_count;
-- 또는, 8.0 에 추가된 JOIN_ORDER 옵티마이저 힌트를 사용하면 된다.
EXPLAIN UPDATE /** JOIN_ORDER (dc, d) */
  (SELECT de.dept_no, COUNT(*) AS emp_count
    FROM dept_emp de
    GROUP BY de.dept_no) dc
INNER JOIN departments d ON dc.dept_no = d.dept_no
  SET d.emp_count = dc.emp_count;

# GROUP BY 절을 가진 쿼리의 결과를 사용했지만 필요에 따라 래터럴 조인을 이용해 JOIN UPDATE 를 구현할 수도 있다.
-- 래터럴 조인을 이용해 JOIN UPDATE 구현하기
UPDATE departments d
  INNER JOIN LATERAL (
      SELECT de.dept_no, COUNT(*) AS emp_count
      FROM dept_emp de
      WHERE de.dept_no = d.dept_no
    ) dc ON dc.dept_no = d.dept_no
  SET d.emp_count = dc.emp_count;
