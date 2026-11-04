# DB Failover / Failback workflow

## Architecture

Normal state:

```text
On-Prem MySQL (Primary / Source of Truth)
  ├─ async Data-in Replication -> KRC Azure MySQL
  └─ async Data-in Replication -> JPE Azure MySQL
```

On-Prem outage:

```text
HAProxy detects On-Prem DOWN
  -> regional Azure MySQL becomes application write target
```

Controlled failback:

```text
Azure temporary Primary
  -> full consistent snapshot
  -> restore snapshot to On-Prem
  -> Terraform re-runs On-Prem -> KRC/JPE Data-in Replication bootstrap
  -> verify replica IO/SQL threads
  -> release HAProxy back to normal On-Prem-first mode
```

## Why `db_proxy_force_standby` exists

HAProxy normally prefers `192.168.10.203` whenever it becomes healthy. That is desirable during ordinary operation, but dangerous during failback: if On-Prem MySQL starts before its data is synchronized, HAProxy would immediately send new writes to the stale database.

Set `db_proxy_force_standby=true` before bringing On-Prem back into service. In this mode the HAProxy config contains only the regional Azure MySQL backend. This guarantees that application writes stay on the failover database while the On-Prem database is restored.

## 1. Normal operation

```hcl
db_failover_generation  = 0
db_failback_generation  = 0
db_proxy_force_standby  = false
```

`05_db_data_in_replication.tf` continuously establishes:

```text
On-Prem -> KRC
On-Prem -> JPE
```

Terraform only bootstraps the relationship. After that MySQL replication threads continuously consume binlog changes.

## 2. On-Prem failure and Azure promotion

When On-Prem is down, HAProxy automatically uses its regional Azure backup. To make the active Azure database an explicit temporary Primary and prevent accidental resumption of the old replication channel, run:

```hcl
db_failover_region      = "krc" # or "jpe"
db_failover_generation  = 1
db_failover_confirmed   = true
```

Then:

```bash
terraform apply
```

`terraform_data.db_failover_promote` executes `az_replication_stop` and `az_replication_remove_master` on the selected Azure MySQL.

## 3. Prepare failback

Before On-Prem is made reachable again by HAProxy, force application writes to remain on Azure:

```hcl
db_proxy_force_standby = true
```

Apply this first:

```bash
terraform apply
```

The KRC/JPE DB proxy containers are recreated with an HAProxy configuration that uses only regional Azure MySQL.

At this point the On-Prem MySQL service may be started/repaired without receiving application traffic.

## 4. Copy Azure failover data back to On-Prem

Keep application writes in a short maintenance/freeze window while the failback snapshot is taken. Then set:

```hcl
db_failover_region       = "krc" # region that accepted writes during outage
db_failback_generation   = 1
db_failback_confirmed    = true
db_proxy_force_standby   = true

onprem_db_admin_user     = "team3"
onprem_db_admin_password = "<secret>"
```

Run:

```bash
terraform apply
```

`terraform_data.db_failback_to_onprem` performs:

1. Verify Azure temporary Primary and On-Prem connectivity.
2. Stop/remove any remaining Data-in channel on the Azure source.
3. Create a safety dump of the current On-Prem DB on the MGMT VM.
4. Create a consistent dump of the Azure temporary Primary.
5. Drop/recreate `team3db` on On-Prem and restore the Azure snapshot.
6. Print table inventory/row counts for comparison.
7. Finish with On-Prem containing the outage-period data.

## 5. Automatic replication rebuild

`db_failback_generation` is also a replacement trigger for both Data-in replication Terraform resources. After the failback restore completes, Terraform automatically re-runs:

```text
On-Prem dump + current binlog coordinates
  -> seed KRC
  -> start KRC Data-in Replication
  -> verify IO=Yes / SQL=Yes
  -> seed JPE
  -> start JPE Data-in Replication
  -> verify IO=Yes / SQL=Yes
```

Do not release application traffic to On-Prem until both resources complete successfully.

## 6. Return HAProxy to normal mode

After KRC/JPE replication reports healthy, set:

```hcl
db_proxy_force_standby = false
```

and run:

```bash
terraform apply
```

The normal HAProxy configuration is restored:

```text
mysql_active  = On-Prem 192.168.10.203
mysql_standby = regional Azure MySQL (backup)
```

## Operational safety

This is controlled Active/Passive failover, not permanent Active/Active replication. Never allow application writes to On-Prem and the Azure temporary Primary at the same time during failback. The failback resource intentionally requires explicit confirmation because it replaces the On-Prem application database with the selected Azure snapshot.
