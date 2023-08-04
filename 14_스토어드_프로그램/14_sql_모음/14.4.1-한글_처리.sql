## 14.4 - 스토어드 프로그램의 참고 및 주의사항
-- SP을 특수한 형태로 사용하는 방법, 주의사항 몇 가지를 살펴보자.

### 14.4.1 - 한글 처리
-- SP의 소스 코드에 한글 문자열 값을 사용해야 한다면 SP을 생성하는 클라이언트 프로그램이 어떤 문자 집합으로 MySQL 서버에 접속돼 있는지가 중요하다.
-- 한국어에 특화된 GUI 클라이언트라면 이런 부분을 자동으로 처리해주겠지만, 그래도 확인해 보면 좋다.

-- MySQL 클라이언트에서 현재 연결된 커네겻ㄴ과 데이터베이스 서버가 어떤 문자 집합을 사용하지는 세션 변수를 통해 확인하는 쿼리
SHOW VARIABLES LIKE 'character%';

-- 위 세션 변수들 중 SP을 생성하는 데 관여하는 부분은 character_set_connection, character_set_client 정도 이다.
-- 이 세션 변수는 특별히 설정하지 않으면 latin1을 기본값으로 값는다. latin1은 영어권 알파벳을 위한 문자 집합이라,
-- 한글을 포함한 아시아권의 멀티바이트를 사용하는 언어를 위한 문자 집합은 아니다. 따라서 utf8 또는 utf8md4로 변경하는 것이 좋다.
SET CHARACTER_SET_CLIENT = 'utf8mb4';
SET CHARACTER_SET_RESULTS = 'utf8mb4';
SET CHARACTER_SET_CONNECTION = 'utf8mb4';

-- 위 세 명령을 다음과 같이 한 번에 할 수도 있다.
SET NAMES utf8md4;

-- 스토어드 프로시저나 함수에서 값을 넘겨받을 때도 넘겨받는 값에 대해 문자 집합을 별도로 지정할 수 있다.
CREATE FUNCTION sf_getstring()
    RETURNS VARCHAR(20) CHARACTER SET utf8mb4
BEGIN
    RETURN '한글 테스트';
END;
SELECT sf_getstring(); -- 한글 테스트
