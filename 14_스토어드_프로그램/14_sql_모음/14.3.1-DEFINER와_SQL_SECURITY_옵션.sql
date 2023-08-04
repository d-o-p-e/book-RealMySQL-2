## 14.3 - 스토어드 프로그램의 보안 옵션
/*
    8.0 이전 버전까지는 SUPER라는 권한이 스토어드 프로그램의 생성, 변경, 삭제 권한과 많이 연결돼 있었다.
    하지만 8.0 버전부터는 SUPER 권한을 오브젝트별 권한으로 세분화했다.
    그래서 8.0 버전부터는 SP의 생성 및 변경 권한이 'CREATE ROUTINE', 'ALTER ROUTINE', 'EXECUTE'로 분리됐다.
    또한, 트리거나 이벤트의 경우 'TRIGGER', 'EVENT' 권한으로 분리됐다.
*/

### 14.3.1 - DEFINER와 SQL SECURITY 옵션
/*
    DEFINER는 SP이 기본적으로 가지는 옵션으로, 해당 스토어드 프로그램의 소유권과 같은 의미를 지닌다.
    또한, SQL SECURITY 옵션에 설정된 값에 따라 조금씩은 다르지만 스토어드 프로그램이 실행될 때의 권한으로 사용되기도 한다.

    SQL SECURITY 옵션은 스토어드 프로그램을 실행할 때 누구의 권한으로 실행할지 결정하는 옵션이다.
    INVOKER 또는 DEFINER 둘 중 하나로 선택할 수 있다.
    INVOKER는 SP를 호출(사용)한 사용자를 의미하고, DEFINER는 SP를 생성한 사용자를 의미한다.

    DEFINER는 모든 SP이 기본적으로 가지는 옵션이지만, SQL SECURITY 옵션은 스토어드 프로시저와 함수, 뷰만 가질 수 있다.
    SQL SECURITY 옵션을 가지지 않는 트리거나 이벤트는 자동으로 SQL SECURITY가 DEFINER로 설정되므로
    트리거나 이벤트는 DEFINER에 명시된 사용자의 권한으로 항상 실행되는 것이다.

    SP의 SQL SECURITY를 DEFINER로 설정하는 것은 유닉스 운영체제의 setUID 같은 기능이라고 생각하면 된다.
    MySQL 스토어드 프로그램도 보안 취약점이 될 수 있으므로 꼭 필요한 용도가 아니라면 SQL SECURITY를 INVOKER로 설정하는 것이 좋다.
    위에서 간략하게 적었듯이 INVOKER는 누가 생성했는지는 상관이 없고 항상 SP를 호출하는 사용자의 권한으로 실행된다.

    SP를 생성하면서 DEFINER 옵션을 부여하지 않으면 기본적으로 현재 사용자로 DEFINER가 자동 설정된다.
    하지만 DEFINER를 다른 사용자로 설정할 때는 SP을 생성하는 자용자가 SET_USER_ID 권한(또는 SUPER 권한)을 가지고 있어야 한다.
    SET_USER_ID 또는 SUPER 권한이 없는 사용자가 SP의 DEFINER를 관리자 계정으로 생성하는 것은 불가능하다.
    마찬가지로 위의 권한을 가진 사용자로 설정하려면 SET_USER_ID(또는 SUPER 권한) 권한과 함께 SYSTEM_USER 권한도 갖고 있어야 한다.
*/
