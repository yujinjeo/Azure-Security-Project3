# DB Data-in Replication (Terraform Resource)

## 목적

`terraform apply` 시 On-Prem MySQL을 Source로 사용하여 KRC/JPE Azure Database for MySQL Flexible Server를 각각 초기 seed한 뒤 Data-in Replication을 시작한다.

```
On-Prem MySQL (Source)
  ├─> KRC Azure MySQL (Data-in Replica)
  └─> JPE Azure MySQL (Data-in Replica)
```

## 왜 azurerm_mysql_flexible_server의 Replica 모드를 사용하지 않는가

`azurerm_mysql_flexible_server`의 `create_mode = "Replica"`는 Azure Flexible Server를 source로 하는 Azure-native replica 기능이다. 외부/온프레미스 MySQL을 source로 하는 Data-in Replication과는 다른 기능이다.

Azure MySQL Flexible Server의 외부 Data-in Replication은 대상 서버 안에서 다음 저장 프로시저로 구성한다.

- `mysql.az_replication_change_master(...)`
- `mysql.az_replication_start`

따라서 이 프로젝트에서는 Terraform built-in resource인 `terraform_data`가 KRC/JPE MGMT VM에서 이 전체 절차를 실행하도록 구성하였다.

## 하드코딩하지 않는 값

binlog file/position은 기존 실습에서 얻은 값을 사용하지 않는다. 각 리전 bootstrap 시점에 source DB에 대해 `mysqldump --source-data=2`를 실행하고 dump 안에서 현재 binlog file/position을 자동 추출한다.

## Source 계정 요구 권한

`onprem_db_sync_user`는 최소한 다음 작업이 가능해야 한다.

- 동기화 대상 DB SELECT
- SHOW VIEW / TRIGGER (해당 객체가 있을 경우)
- `REPLICATION SLAVE`
- `REPLICATION CLIENT`
- mysqldump `--source-data`에 필요한 source 권한

## 입력 변수 예시

`terraform.tfvars` 또는 CLI 변수로 비밀번호를 주입한다.

```hcl
enable_db_data_in_replication = true
onprem_db_sync_user           = "team3"
onprem_db_sync_password       = "<source-password>"
```

비밀번호는 Git에 저장하지 않는 것을 권장한다.

## 재초기화

일반 `terraform apply`에서는 replication bootstrap resource가 다시 실행되지 않는다.
Source 기준으로 KRC/JPE DB를 다시 초기 seed해야 할 때만 아래 값을 증가시킨다.

```hcl
db_replication_generation = 2
```

이 값이 변경되면 Terraform이 KRC/JPE replication resource를 replace하고 target DB를 source dump 기준으로 다시 seed한다.

## 실행 흐름

각 리전 resource는 다음 순서로 실행한다.

1. Source `server_id`, `log_bin`, `binlog_format` 검사
2. `mysqldump --single-transaction --source-data=2` 생성
3. dump에서 현재 binlog file/position 자동 추출
4. 기존 Data-in 관계가 있으면 stop/remove
5. 대상 Azure DB 초기 seed
6. `mysql.az_replication_change_master()` 실행
7. `mysql.az_replication_start` 실행
8. `SHOW REPLICA STATUS`에서 IO/SQL thread가 모두 `Yes`인지 확인

## 주의

이 구조는 On-Prem -> Azure 단방향 비동기 복제다. On-Prem 장애 중 Azure DB에 쓰기가 발생하면 On-Prem 복구 시 자동 역동기화되지 않는다. 장기 운영에서는 별도의 failback/reseed 절차가 필요하다.

## Failover / Failback

For outage-period writes and controlled synchronization back to On-Prem, see `DB_FAILOVER_FAILBACK.md` and `06_db_failover_failback.tf`.
