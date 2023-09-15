---

## Docker 실행하기

- docker-compose 파일이 있는 곳으로 이동 후 다음과 같이 실행한다.

```bash
docker-compose up -d
```

## 실행한 컨테이너 접속하기

```bash
docker exec -it {container name} bash   # 도커 컨테이너 접속

mysql -u root -p'1234'  # root 계정으로 접속 가능한지 테스트

SELECT user, host FROM mysql.user; # test 계정 잘 생성됐는지 확인
```

## 클러스터 설정 사전 준비

- 이유는 모르겠지만 `mysql shell` 을 따로 설치하지 않아도 접속이 가능하다. (아시는 분..)

```bash
# mysql shell 로 접속
mysql-dev1 > mysqlsh -u test -p'1234'

# 클러스터 구성을 위한 사전 확인을 위해 다음 쿼리 실행 (다른 컨테이너로 연결해야 됨)
# dba.checkInstanceConfiguration('계정명@{container name}:port')
# 실제 사용 쿼리
dev1-JS > dba.checkInstanceConfiguration('test@mysql-dev2:3306')
dev1-JS > Please provide the password for 'test@mysql-dev2:3306': 비밀번호_입력
# 접속할 비밀번호 저장할 것인지 여기에선 Y
dev1-JS > Save password for 'test@mysql-dev2:3306'? [Y]es/[N]o/Ne[v]er (default No): Y
Some variables need to be changed, but cannot be done dynamically on the server.
NOTE: Please use the dba.configureInstance() command to repair these issues.

{
    "config_errors": [
        {
            "action": "server_update",
            "current": "COMMIT_ORDER",
            "option": "binlog_transaction_dependency_tracking",
            "required": "WRITESET"
        },
        {
            "action": "server_update+restart",
            "current": "OFF",
            "option": "enforce_gtid_consistency",
            "required": "ON"
        },
        {
            "action": "server_update+restart",
            "current": "OFF",
            "option": "gtid_mode",
            "required": "ON"
        },
        {
            "action": "server_update+restart",
            "current": "1",
            "option": "server_id",
            "required": "<unique ID>"
        }
    ],
    "status": "error"
}

# 위와 똑같이 test@mysql-dev3:3306 도 진행보는데 제일 밑에 "status": "error" 만 확인하면 된다.
```

## 클러스터 설정

```bash
# mysql-dev1, mysql-dev2, mysql-dev3 중에서 메인으로 삼고 싶은 bash로 이동 (저는 dev1)
mysql-dev1 > mysqlsh -u test -p'1234'

# 각 컨테이너가 노드 역할을 할 수 있도록 클러스터 설정
# mysqlJS > dba.configureInstance("clusteradmin@{container name}:port")
dev1-JS > dba.configureInstance('test@mysql-dev2:3306')
Configuring MySQL instance at c3bec42a0dec:3306 for use in an InnoDB cluster...

This instance reports its own address as c3bec42a0dec:3306
Clients and other cluster members will communicate with it through this address by default. If this is not correct, the report_host MySQL system variable should be changed.

applierWorkerThreads will be set to the default value of 4.

NOTE: Some configuration options need to be fixed:
+----------------------------------------+---------------+----------------+--------------------------------------------------+
| Variable                               | Current Value | Required Value | Note                                             |
+----------------------------------------+---------------+----------------+--------------------------------------------------+
| binlog_transaction_dependency_tracking | COMMIT_ORDER  | WRITESET       | Update the server variable                       |
| enforce_gtid_consistency               | OFF           | ON             | Update read-only variable and restart the server |
| gtid_mode                              | OFF           | ON             | Update read-only variable and restart the server |
| server_id                              | 1             | <unique ID>    | Update read-only variable and restart the server |
+----------------------------------------+---------------+----------------+--------------------------------------------------+

Some variables need to be changed, but cannot be done dynamically on the server.
Do you want to perform the required configuration changes? [y/n]: y
Do you want to restart the instance after configuring it? [y/n]: y

# 도커 대시보드 보면 해당 컨테이너만 꺼져있다. 재시작 해야된다.

# mysql-dev3 에서도 configureInstance 등록
dev1-JS > dba.configureInstance('test@mysql-dev3:3306')
Configuring MySQL instance at be1609a3e203:3306 for use in an InnoDB cluster...

This instance reports its own address as be1609a3e203:3306
Clients and other cluster members will communicate with it through this address by default. If this is not correct, the report_host MySQL system variable should be changed.

applierWorkerThreads will be set to the default value of 4.

NOTE: Some configuration options need to be fixed:
+----------------------------------------+---------------+----------------+--------------------------------------------------+
| Variable                               | Current Value | Required Value | Note                                             |
+----------------------------------------+---------------+----------------+--------------------------------------------------+
| binlog_transaction_dependency_tracking | COMMIT_ORDER  | WRITESET       | Update the server variable                       |
| enforce_gtid_consistency               | OFF           | ON             | Update read-only variable and restart the server |
| gtid_mode                              | OFF           | ON             | Update read-only variable and restart the server |
| server_id                              | 1             | <unique ID>    | Update read-only variable and restart the server |
+----------------------------------------+---------------+----------------+--------------------------------------------------+

Some variables need to be changed, but cannot be done dynamically on the server.
Do you want to perform the required configuration changes? [y/n]: y
Do you want to restart the instance after configuring it? [y/n]: y
Configuring instance...
The instance 'be1609a3e203:3306' was configured to be used in an InnoDB cluster.
Restarting MySQL...
NOTE: MySQL server at be1609a3e203:3306 was restarted.
# 도커 대시보드 보면 해당 컨테이너만 꺼져있다. 재시작 해야된다.

# dev1 도 등록해줘야 한다. 이후 재시작한 다음 다시 접속해야 됨
dev1-JS > dba.configureInstance('test@mysql-dev1:3306')
Please provide the password for 'test@mysql-dev1:3306': ****
Save password for 'test@mysql-dev1:3306'? [Y]es/[N]o/Ne[v]er (default No): Y
Configuring local MySQL instance listening at port 3306 for use in an InnoDB cluster...

This instance reports its own address as 6a341bd29aec:3306
Clients and other cluster members will communicate with it through this address by default. If this is not correct, the report_host MySQL system variable should be changed.

applierWorkerThreads will be set to the default value of 4.

NOTE: Some configuration options need to be fixed:
+----------------------------------------+---------------+----------------+--------------------------------------------------+
| Variable                               | Current Value | Required Value | Note                                             |
+----------------------------------------+---------------+----------------+--------------------------------------------------+
| binlog_transaction_dependency_tracking | COMMIT_ORDER  | WRITESET       | Update the server variable                       |
| enforce_gtid_consistency               | OFF           | ON             | Update read-only variable and restart the server |
| gtid_mode                              | OFF           | ON             | Update read-only variable and restart the server |
| server_id                              | 1             | <unique ID>    | Update read-only variable and restart the server |
+----------------------------------------+---------------+----------------+--------------------------------------------------+

Some variables need to be changed, but cannot be done dynamically on the server.
Do you want to perform the required configuration changes? [y/n]: y
Do you want to restart the instance after configuring it? [y/n]: y
Configuring instance...
The instance '6a341bd29aec:3306' was configured to be used in an InnoDB cluster.
Restarting MySQL...
NOTE: MySQL server at 6a341bd29aec:3306 was restarted.
```

## Innodb 환경 잘 구성됐는지 테스트

```bash
mac > docker exec -it 폴더_위치_mysql-dev1_1 bash
mysql-dev1 > mysqlsh -u test -p'1234'

dev1-JS > dba.checkInstanceConfiguration('test@mysql-dev1:3306')
Validating local MySQL instance listening at port 3306 for use in an InnoDB cluster...

This instance reports its own address as 6a341bd29aec:3306
Clients and other cluster members will communicate with it through this address by default. If this is not correct, the report_host MySQL system variable should be changed.

Checking whether existing tables comply with Group Replication requirements...
No incompatible tables detected

Checking instance configuration...
Instance configuration is compatible with InnoDB cluster

The instance '6a341bd29aec:3306' is valid to be used in an InnoDB cluster.

{
    "status": "ok"
}

dev1-JS > dba.checkInstanceConfiguration('test@mysql-dev2:3306')
Validating MySQL instance at c3bec42a0dec:3306 for use in an InnoDB cluster...

This instance reports its own address as c3bec42a0dec:3306
Clients and other cluster members will communicate with it through this address by default. If this is not correct, the report_host MySQL system variable should be changed.

Checking whether existing tables comply with Group Replication requirements...
No incompatible tables detected

Checking instance configuration...
Instance configuration is compatible with InnoDB cluster

The instance 'c3bec42a0dec:3306' is valid to be used in an InnoDB cluster.

{
    "status": "ok"
}

# "status": "ok" 나오면 성공
# dev3 도 잘 되는지 확인
dev1-JS > dba.checkInstanceConfiguration('test@mysql-dev3:3306')
Validating MySQL instance at be1609a3e203:3306 for use in an InnoDB cluster...

This instance reports its own address as be1609a3e203:3306
Clients and other cluster members will communicate with it through this address by default. If this is not correct, the report_host MySQL system variable should be changed.

Checking whether existing tables comply with Group Replication requirements...
No incompatible tables detected

Checking instance configuration...
Instance configuration is compatible with InnoDB cluster

The instance 'be1609a3e203:3306' is valid to be used in an InnoDB cluster.

{
    "status": "ok"
}
```

## 클러스터 연결

```bash
# var cluster = dba.dba.createCluster("{cluster name}")

# 실제 사용 코드
dev1-JS > var cluster = dba.createCluster('dockercl')
A new InnoDB Cluster will be created on instance '6a341bd29aec:3306'.

Validating instance configuration at localhost:3306...

This instance reports its own address as 6a341bd29aec:3306

Instance configuration is suitable.
NOTE: Group Replication will communicate with other members using '6a341bd29aec:3306'. Use the localAddress option to override.

Creating InnoDB Cluster 'dockercl' on '6a341bd29aec:3306'...

Adding Seed Instance...
Cluster successfully created. Use Cluster.addInstance() to add MySQL instances.
At least 3 instances are needed for the cluster to be able to withstand up to
one server failure.

dev1-JS > cluster.status()
{
    "clusterName": "dockercl",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "6a341bd29aec:3306",
        "ssl": "REQUIRED",
        "status": "OK_NO_TOLERANCE",
        "statusText": "Cluster is NOT tolerant to any failures.",
        "topology": {
            "6a341bd29aec:3306": {
                "address": "6a341bd29aec:3306",
                "memberRole": "PRIMARY",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": "applier_queue_applied",
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.32"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "6a341bd29aec:3306"
}
# 이렇게 나오면 다 끝났다. 이제 인스턴스 추가만 하면 된다.
```

## 인스턴스 추가

```bash
# cluster.addInstance("clusteradmin@{container name}:{port}")

# 사용한 코드
dev1-JS > cluster.addInstance('test@mysql-dev2:3306')
NOTE: The target instance 'c3bec42a0dec:3306' has not been pre-provisioned (GTID set is empty). The Shell is unable to decide whether incremental state recovery can correctly provision it.
The safest and most convenient way to provision a new instance is through automatic clone provisioning, which will completely overwrite the state of 'c3bec42a0dec:3306' with a physical snapshot from an existing cluster member. To use this method by default, set the 'recoveryMethod' option to 'clone'.

The incremental state recovery may be safely used if you are sure all updates ever executed in the cluster were done with GTIDs enabled, there are no purged transactions and the new instance contains the same GTID set as the cluster or a subset of it. To use this method by default, set the 'recoveryMethod' option to 'incremental'.

Please select a recovery method [C]lone/[I]ncremental recovery/[A]bort (default Clone): C
Validating instance configuration at mysql-dev2:3306...

This instance reports its own address as c3bec42a0dec:3306

Instance configuration is suitable.
NOTE: Group Replication will communicate with other members using 'c3bec42a0dec:3306'. Use the localAddress option to override.

A new instance will be added to the InnoDB Cluster. Depending on the amount of
data on the cluster this might take from a few seconds to several hours.

Adding instance to the cluster...

Monitoring recovery process of the new cluster member. Press ^C to stop monitoring and let it continue in background.
Clone based state recovery is now in progress.

NOTE: A server restart is expected to happen as part of the clone process. If the
server does not support the RESTART command or does not come back after a
while, you may need to manually start it back.

* Waiting for clone to finish...
NOTE: c3bec42a0dec:3306 is being cloned from 6a341bd29aec:3306
** Stage DROP DATA: Completed
** Clone Transfer
    FILE COPY  ############################################################  100%  Complete    PAGE COPY  ############################################################  100%  Complete    REDO COPY  ############################################################  100%  Completed
NOTE: c3bec42a0dec:3306 is shutting down...

* Waiting for server restart... ready # 여기서 재시작 해줘야 한다.
* c3bec42a0dec:3306 has restarted, waiting for clone to finish...
** Stage RESTART: Completed
* Clone process has finished: 78.90 MB transferred in about 1 second (~78.90 MB/s)

State recovery already finished for 'c3bec42a0dec:3306'

The instance 'c3bec42a0dec:3306' was successfully added to the cluster.
```

- 중간에 `Waiting for …` 나올 때 **해당 도커 컨테이너** 재시작 해줘야 한다. (모든 컨테이너 X)
- 위는 `dev2`를 `Clone` 방식으로 클러스터 구성

```bash
# 위랑 같은 방법으로 dev3 도 인스턴스 추가
dev1-JS > cluster.addInstance('test@mysql-dev3:3306')
NOTE: The target instance 'be1609a3e203:3306' has not been pre-provisioned (GTID set is empty). The Shell is unable to decide whether incremental state recovery can correctly provision it.
The safest and most convenient way to provision a new instance is through automatic clone provisioning, which will completely overwrite the state of 'be1609a3e203:3306' with a physical snapshot from an existing cluster member. To use this method by default, set the 'recoveryMethod' option to 'clone'.

The incremental state recovery may be safely used if you are sure all updates ever executed in the cluster were done with GTIDs enabled, there are no purged transactions and the new instance contains the same GTID set as the cluster or a subset of it. To use this method by default, set the 'recoveryMethod' option to 'incremental'.

Please select a recovery method [C]lone/[I]ncremental recovery/[A]bort (default Clone): C
Validating instance configuration at mysql-dev3:3306...

This instance reports its own address as be1609a3e203:3306

Instance configuration is suitable.
NOTE: Group Replication will communicate with other members using 'be1609a3e203:3306'. Use the localAddress option to override.

A new instance will be added to the InnoDB Cluster. Depending on the amount of
data on the cluster this might take from a few seconds to several hours.

Adding instance to the cluster...

Monitoring recovery process of the new cluster member. Press ^C to stop monitoring and let it continue in background.
Clone based state recovery is now in progress.

NOTE: A server restart is expected to happen as part of the clone process. If the
server does not support the RESTART command or does not come back after a
while, you may need to manually start it back.

* Waiting for clone to finish...
NOTE: be1609a3e203:3306 is being cloned from 6a341bd29aec:3306
** Stage DROP DATA: Completed
** Clone Transfer
    FILE COPY  ############################################################  100%  Complete    PAGE COPY  ############################################################  100%  Complete    REDO COPY  ############################################################  100%  Completed
NOTE: be1609a3e203:3306 is shutting down...

* Waiting for server restart... ready # 재시작 해줘야 한다.
* be1609a3e203:3306 has restarted, waiting for clone to finish...
** Stage RESTART: Completed
* Clone process has finished: 78.90 MB transferred in about 1 second (~78.90 MB/s)

State recovery already finished for 'be1609a3e203:3306'

The instance 'be1609a3e203:3306' was successfully added to the cluster.
```

- 위랑 같이 재시작해줘야 하는 부분이 있다. 똑같이 `Clone` 방식으로 구성

## 상태 확인

```bash
dev1-JS > cluster.status()
{
    "clusterName": "dockercl",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "6a341bd29aec:3306",
        "ssl": "REQUIRED",
        "status": "OK",
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.",
        "topology": {
            "6a341bd29aec:3306": {
                "address": "6a341bd29aec:3306",
                "memberRole": "PRIMARY",
                "mode": "R/W",
                "readReplicas": {},
                "replicationLag": "applier_queue_applied",
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.32"
            },
            "be1609a3e203:3306": {
                "address": "be1609a3e203:3306",
                "memberRole": "SECONDARY",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": "applier_queue_applied",
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.32"
            },
            "c3bec42a0dec:3306": {
                "address": "c3bec42a0dec:3306",
                "memberRole": "SECONDARY",
                "mode": "R/O",
                "readReplicas": {},
                "replicationLag": "applier_queue_applied",
                "role": "HA",
                "status": "ONLINE",
                "version": "8.0.32"
            }
        },
        "topologyMode": "Single-Primary"
    },
    "groupInformationSourceMember": "6a341bd29aec:3306"
}
```

- 이렇게 나온다면 끝났다.

## 이제 위에 설정한 컨테이너를 돌아다니면서 테스트 할 수 있다.

- 단, `Single-Primary` 로 구성되어 있으므로 **메인에서만 쓰기가 가능**하고, **다른 노드들은 읽기**만 된다.

## 만약 도커를 껐다 켰을 때 안되면

```sql
dev1-JS > var cluster = dba.getCluster()
cluster.rescan()

-- 클러스터 목록 확인하는 쿼리
SELECT cluster_name from mysql_innodb_cluster_metadata.clusters;

-- 도커 컨테이너를 모두 종료 후 재시작 하면 getCluster가 안 먹힌다.
-- 이럴때 클러스터 리부팅을 해야 한다.
-- 클러스터 리부팅 방법
dba.rebootClusterFromCompleteOutage();
```

- 클러스터가 완전히 중단된 경우 dba.rebootClusterFromCompleteOutage()를 사용하여 클러스터를 재구성할 수 있습니다. \
 이 작업을 통해 클러스터의 MySQL 인스턴스 중 하나에 연결하고 해당 메타데이터를 사용하여 클러스터를 복구할 수 있습니다. [[MySQL 공식 문서](https://dev.mysql.com/doc/mysql-shell/8.0/en/reboot-outage.html)]
- 8.0.34 버전 이후로 mysql shell이 내장되어 사용할 수 있는거 같다. (다시 테스트했을 땐 `8.0.32`도 가능)

## 참고

- https://diptochakrabarty.medium.com/setting-mysql-cluster-using-docker-f0e405d03762
- https://dev.mysql.com/doc/dev/mysqlsh-api-javascript/8.0/classmysqlsh_1_1dba_1_1_dba.html
  - dba 관련 함수 무엇이 있는지