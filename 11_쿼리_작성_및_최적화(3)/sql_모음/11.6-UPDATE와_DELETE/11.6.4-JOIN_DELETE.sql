# 11.6.4 - JOIN DELETE
-- 일반적으로 하나의 테이블에서 레코드를 삭제할 때는 'DELETE FROM table ...' 쿼리를 작성하는데,
-- JOIN DELETE 문장에서는 DELETE 와 FROM 절 사이에 삭제할 테이블을 명시해야 한다.
DELETE e
FROM employees e, dept_emp de, departments d
WHERE e.emp_no = de.emp_no AND de.dept_no = d.dept_no AND d.dept_no = 'd001';

-- 여러 테이블의 레코드를 삭제하고 싶으면 e 자리에 다른 테이블의 이름도 명시하면 된다.
DELETE e, de
FROM employees e, dept_emp de, departments d
WHERE e.emp_no = de.emp_no AND de.dept_no = d.dept_no AND d.dept_no = 'd001';

DELETE e, de, d
FROM employees e, dept_emp de, departments d
WHERE e.emp_no = de.emp_no AND de.dept_no = d.dept_no AND d.dept_no = 'd001';

# JOIN 의 순서를 옵티마이저에게 지시하기
-- STRAIGHT_JOIN 키워드 사용
DELETE e, de, d
FROM departments d
    STRAIGHT_JOIN dept_emp de ON de.dept_no = d.dept_no
    STRAIGHT_JOIN employees e ON  e.emp_no = de.emp_no
WHERE d.dept_no = 'd001';
-- JOIN_ORDER 옵티아미저 힌드 사용
DELETE /** JOIN_ORDER (d, de, e) */ e, de, d
FROM departments d
    STRAIGHT_JOIN dept_emp de ON de.dept_no = d.dept_no
    STRAIGHT_JOIN employees e ON  e.emp_no = de.emp_no
WHERE d.dept_no = 'd001';

