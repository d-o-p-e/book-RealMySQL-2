---

## 실행 환경

- 맥과 도커를 이용했습니다.
- Docker version 20.10.12

## mysql 이미지 만들기

```bash
docker pull mysql # 다른 버전을 사용하고 싶으면 mysql:사용하고_싶은_버전명 하면된다.
# 현재 MySQL 기본 버전은 8.1.0 입니다. 8.1.0 으로 테스트 했을때 잘 진행 됐습니다.
```

## 도커로 MySQL master 컨테이너 만들기

```bash
docker run --name mysql-master -e MYSQL_ROOT_PASSWORD=1234 -d mysql
docker exec -it mysql-master bash

# vim을 사용하려면 아래처럼 설치하면 되는데 단순히 테스트하고 싶으면 안해도 됩니다. echo로 가능
cat /etc/*-release # 했을 때
Oracle Linux Server release 8.8
NAME="Oracle Linux Server"
VERSION="8.8"
ID="ol"
ID_LIKE="fedora"
VARIANT="Server"
VARIANT_ID="server"
VERSION_ID="8.8"
PLATFORM_ID="platform:el8"
PRETTY_NAME="Oracle Linux Server 8.8"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:oracle:linux:8:8:server"
HOME_URL="https://linux.oracle.com/"
BUG_REPORT_URL="https://github.com/oracle/oracle-linux"

ORACLE_BUGZILLA_PRODUCT="Oracle Linux 8"
ORACLE_BUGZILLA_PRODUCT_VERSION=8.8
ORACLE_SUPPORT_PRODUCT="Oracle Linux"
ORACLE_SUPPORT_PRODUCT_VERSION=8.8
Red Hat Enterprise Linux release 8.8 (Ootpa)
Oracle Linux Server release 8.8
# 이렇게 나온다면 apt-get을 사용하지 못한다. microdnf 를 사용해야 한다.

# 우분투 일 경우
apt-get install vim -y 
# Oracle Linux 일 경우
microdnf install vim

# docker exec -it mysql-master bash 명령어로 도커 컨테이너 안으로 접속한 상황
$ ls
bin  boot  dev	docker-entrypoint-initdb.d  dump.sql  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
```

## MySQL 설정 파일 만들기

```bash
# 파일 경로는 다음과 같이 해야 됩니다.
# /etc/mysql/my.cnf

$ cd /etc/mysql
$ ls
conf.d
$ touch my.cnf # my.cnf 설정을 적용하기 위해 파일 생성
$ ls
conf.d	my.cnf
$ echo "[mysqld]" > my.cnf
$ echo "log-bin=mysql-bin" >> my.cnf
$ echo "server-id=1" >> my.cnf
$ cat my.cnf
[mysqld]
log-bin=mysql-bin
server-id=1

```

- `log-bin`
    - 업데이트 되는 모든 query를 binary log 파일에 기록한다는 의미
    - 기본적으론 MySQL의 data directory인 `/var/lib/mysql/` 에 `호스트명-bin.000001`, `호스트명-bin.000002` 형태로 생성된다.
    - `log-bin` 설정을 변경하면 binary log 파일의 경로와 파일명의 접두어를 변경할 수 있다. \
      위처럼 `mysql-bin` 으로 하면 `mysql-bin.000001`, `mysql-bin.000002` 이런 식으로 변경된다.
- `server-id`
    - 복제 설정에서 서버를 식별하기 위한 고유 ID 값이다.
    - 각 서버마다 고유한 값으로 설정해야 된다. 즉, master, slave 서로 서버 아이디가 달라야한다.

### 설정 파일이 잘 적용됐는지 확인

```bash
$ docker exec -it mysql-master bash
$ mysql -u root -p

mysql> SHOW MASTER STATUS\G
*************************** 1. row ***************************
             File: binlog.000002
         Position: 1961
     Binlog_Do_DB:
 Binlog_Ignore_DB:
Executed_Gtid_Set:
1 row in set (0.00 sec)
```

## master DB에 user 생성하기

- slave DB 에서 접근할 수 있도록 계정을 생성하고 `REPLICATION SLAVE` 권한을 부여

```bash
mysql> CREATE USER 'repl'@'%' IDENTIFIED BY '1234';
Query OK, 0 rows affected (0.01 sec)

mysql> ALTER USER 'repl'@'%' IDENTIFIED WITH mysql_native_password BY '1234'; # 이 부분은 안해도 됩니다.
Query OK, 0 rows affected (0.01 sec)

mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
Query OK, 0 rows affected (0.01 sec)
```

- 편의를 위해 복제 계정을 호스트 제한을 `%` 진행했지만 보안을 위해 꼭 필요한 IP 대역에서만 복제 연결이 가능하도록 `%` 말고 적절한 IP 대역을 설정해야 된다.

### 유저가 잘 생성됐는지 user 테이블 확인하기

```bash
mysql> SELECT user, host FROM mysql.user;
+------------------+-----------+
| user             | host      |
+------------------+-----------+
| repl             | %         |
| root             | %         |
| mysql.infoschema | localhost |
| mysql.session    | localhost |
| mysql.sys        | localhost |
| root             | localhost |
+------------------+-----------+
6 rows in set (0.01 sec)
```

## Replication 테스트를 위한 DB와 테이블 생성

```bash
mysql> CREATE DATABASE testdb;
Query OK, 1 row affected (0.01 sec)

mysql> USE testdb;
Database changed

mysql> CREATE TABLE test_tbl ( text varchar(20) );
Query OK, 0 rows affected (0.03 sec)

mysql> DESC test_tbl;
+-------+-------------+------+-----+---------+-------+
| Field | Type        | Null | Key | Default | Extra |
+-------+-------------+------+-----+---------+-------+
| text  | varchar(20) | YES  |     | NULL    |       |
+-------+-------------+------+-----+---------+-------+
1 row in set (0.01 sec)

mysql> INSERT INTO test_tbl VALUES ('test row');
Query OK, 1 row affected (0.01 sec)

mysql> SELECT * from test_tbl;
+----------+
| text     |
+----------+
| test row |
+----------+
1 row in set (0.00 sec)
```

## master DB dump

- slave DB에서 master DB를 연결하기 전에 master DB의 현재 DB 상태(table과 data)를 slave에 그대로 반영하기 위해 dump한다. (아무 데이터가 없다면 안해도 된다.)

```bash
$ docker exec -it mysql-master bash

$ mysqldump -u root -p testdb > dump.sql
```

### 도커로 dump 된 파일을 slave DB 컨테이너에 복사하기 위해 로컬 PC로 복사

```bash
# 이 과정에서 현재 터미널로 복사되므로 폴더나 파일들이 복잡해지는게 싫으면 테스트 환경으로 이동해야 된다.
# 저는 다음과 같은 위치에서 진행했습니다.
$ cd ~/Documents/playground/docker/mysql

$ docker cp mysql-master:dump.sql .

$ cat dump.sql
```

## 도커로 MySQL slave 컨테이너 생성하고 실행하기

```bash
$ docker run --name mysql-slave --link mysql-master -e MYSQL_ROOT_PASSWORD=1234 -d mysql
$ docker exec -it mysql-slave bash
```

### master 컨테이너에서 했듯이 cnf 파일 등록

```bash
# $ apt-get install vim -y 또는 
# 위에서 했던 방법으로 echo로 가능하다. vim이 편하면 위에서 얘기했듯이 각자의 버전의 맞게 설치하면 된다.
$ docker run --name mysql-slave --link mysql-master -e MYSQL_ROOT_PASSWORD=1234 -d mysql
$ docker exec -it mysql-slave bash

$ cd /etc/mysql
$ touch my.cnf # my.cnf 설정을 적용하기 위해 파일 생성
$ ls
conf.d	my.cnf
$ echo "[mysqld]" > my.cnf
$ echo "log-bin=mysql-bin" >> my.cnf
$ echo "server-id=2" >> my.cnf
$ cat my.cnf
[mysqld]
log-bin=mysql-bin
server-id=2
```

- 위에 `master` 컨테이너와는 다르게 `--link mysql-master` 를 적어줘야 한다.
- `--link`가 안되면 docker 로그인이 필요하다.

## slave DB에 dump 파일 적용

- 로컬 PC로 복사한 master DB의 dump 파일을 slave DB로 옮긴 후 반영하기

```bash
$ docker cp dump.sql mysql-slave:.
$ docker exec -it mysql-slave bash

$ mysql -u root -p
mysql> CREATE DATABASE testdb;
Query OK, 1 row affected (0.01 sec)

mysql> exit
Bye

$ mysql -u root -p testdb < dump.sql

mysql> USE testdb;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> SHOW TABLES;
+------------------+
| Tables_in_testdb |
+------------------+
| test_tbl         |
+------------------+
1 row in set (0.00 sec)

mysql> SELECT * FROM test_tbl;
+-----------+
| text      |
+-----------+
| test row  |
+-----------+
```

## slave DB에서 master DB 연동

- binary log 파일을 통해 master와 slave의 DB가 동기화 되므로 반드시 동일한 로그의 위치를 서로 참조하고 있어야 한다.

```bash
$ docker exec -it mysql-master bash
$ mysql -u root -p  

mysql> SHOW MASTER STATUS\G 
*************************** 1. row ***************************
             File: mysql-bin.000001
         Position: 1949
     Binlog_Do_DB:
 Binlog_Ignore_DB:
Executed_Gtid_Set:
1 row in set (0.00 sec)
```

- `File`과 `Position`의 값을 기억해야 한다.
- `File`은 바이너리 로그 파일명이고, `Position`은 현재 로그의 위치를 나타낸다.

### slave DB로 이동 후 `CHANGE MASTER TO` 쿼리를 실행해야 한다.

```bash
$ docker exec -it mysql-slave bash
$ mysql -u root -p  
mysql> CHANGE MASTER TO
		MASTER_HOST='mysql-master',
		MASTER_USER='repl',
		MASTER_PASSWORD='1234',
		MASTER_LOG_FILE='mysql-bin.000001',
		MASTER_LOG_POS=1949;
# realmysql 책에선 GET_MASTER_PUBLIC_KEY 정보도 있다.
		GET_MASTER_PUBLIC_KEY=1 # 이 예제에선 사용하지 않았다.

Query OK, 0 rows affected, 2 warnings (0.03 sec)

mysql> START SLAVE; # 또는 START REPLICA
Query OK, 0 rows affected (0.00 sec)

mysql> SHOW SLAVE STATUS\G
# 여기서 Replica_IO_Running: Yes
# Replica_SQL_Running: Yes
# Seconds_Behind_Source의 값이 0이 되면 소스 서버와 레플리카 서버의 데이터가 동기화가 잘 된 것이다.
	# 만약, START REPLICA 명령을 실행했는데도 위의 설정값들이 변경되지 않는다면
	# 소스 서버의 호스트명이나 MySQL의 포트 또는
	# 레플리카 서버에서 사용하는 복제용 접속 계정과 비밀번호가 절못 입력됐을 가능성이 상당히 높다.
	# 해당 정보가 제대로 입력됐는지 잘 확인해보고, 소스 서버와 레플리카 서버간에 네트워크상 문제가 없는지도 확인해보자.
```

- `MASTER_HOST`
    - master 서버의 호스트명
- `MASTER_USER`
    - master 서버의 mysql에서 `REPLICATION SLAVE` 권한을 가진 user 계정의 이름
    - 위에서 `repl` 로 생성한 계정을 생각하면 된다.
- `MASTER_PASSWORD`
    - master 서버의 mysql에서 `REPLICATION SLAVE` 권한을 가진 user 계정의 비밀번호
    - 위에서 `1234`로 설정했다.
- `MASTER_LOG_FILE`
    - master 서버의 바이너리 로그 파일명
    - `show master status\G` 에서 나온 `FILE` 의 값
- `MASTER_LOG_POS`
    - master 서버의 현재 로그의 위치
    - `show master status\G` 에서 나온 `Position` 의 값
- `GET_MASTER_PUBLIC_KEY`
    - RSA 키 기반 비밀번호 교환 방식의 통신을 위해 공개키를 소스 서버에 요청할 것인지 여부를 나타난다.

이제 복제가 끝났다. 테스트해보자.

```bash
$ docker exec -it mysql-master bash
$ mysql -u root -p

msater-db> use testdb;
mysql> INSERT INTO test_tbl VALUES ('test row2');
Query OK, 1 row affected (0.01 sec)

mysql> SELECT * FROM test_tbl;
+-----------+
| text      |
+-----------+
| test row  |
| test row2 |
+-----------+
2 rows in set (0.00 sec)
```

```bash
$ docker exec -it mysql-slave bash
$ mysql -u root -p

msater-db> use testdb;
mysql> SELECT * FROM test_tbl;
+-----------+
| text      |
+-----------+
| test row  |
| test row2 |
+-----------+
2 rows in set (0.00 sec)
```

복제 동기화 완료!

## 추가

- 위 상황에선 slave DB에서도 insert, update, delete 등등 가능하다. 근데, Master DB로 반영되진 않는다.
- 즉, 서로 다른 데이터들이 생길수도 있다. 이를 막고 싶으면 slave 쪽 my.cnf 파일에 super_read_only 옵션을 추가하면 된다.

```bash
$ docker exec -it mysql-slave bash
$ cd /etc/mysql
$ echo "super_read_only" >> my.cnf
```

- root를 제외한 계정의 SUPER 유저 권한 삭제
    - >UPDATE mysql.user SET super_priv='N' WHERE user <> 'root';
    - >FLUSH privileges;

### GTID 기반으로 구성하고 싶으면 my.cnf 파일만 GTID에 맞게 설정하면 됩니다.
- 테스트는 다 했는데, 문서로는 만들지 않아서 필요할 때 공유 드리겠습니다.

## 참고

- https://jongmin92.github.io/2019/11/13/Database/mysql-replication/
- https://jupiny.com/2017/11/07/docker-mysql-replicaiton/