# 11.7.3 - 테이블 스페이스 벽녕
-- MySQL 서버에는 전통적으로 테이블별로 전용의 테이블스페이스를 사용했었다.
/*
    InnoDB 스토리지 엔진의 시스템 테이블 스페이스(ibdata1 파일)만 제너럴 테이블스페이스(General Tablespace)를 사용했는데,
    제너럴 테이블스페이스는 여러 테이블의 데이터를 한꺼번에 저장하는 테이블스페이스를 의미한다.

    제너럴 테이블스페이스의 장단점
    - 장점
        - 제너럴 테이블스페이스를 사용하면 파일 핸들러를 최소화 할 수 있다.
        - 테이블스페이스 관리에 필요한 메모리 공간을 최소화 할 수 있다.
        - 사실 위 두 가지 장점은 테이블의 개수가 많은 경우에 유용하다. (아직 일반적진 장점은 없는거 같다)
    - 단점
        - 파티션 테이블은 제너럴 테이블스페이스를 사용하지 못한다.
        - 복제 소스와 레플리카 서버가 동일 호스트에서 실행되는 경우 ADD DATAFILE 문장은 사용 불가
        - 테이블 암호화(TDE)는 테이블스페이스 단위로 설정된다.
        - 테이블 압축 기능 여부는 테이블스페이스의 블록 사이즈와 InnoDB 페이지 사이즈에 의해 결정된다.
        - 특정 테이블을 삭제(DROP TABLE)해도 디스크 공간이 운영체제로 반납되지 않는다.
 */

