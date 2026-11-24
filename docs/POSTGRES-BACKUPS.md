# PostgreSQL backups to OVH Object Storage

CloudNativePG's Barman Cloud plugin archives WAL continuously and takes daily
full backups, with a 30-day recovery window. The default WAL archive timeout is
five minutes. An initial full backup is requested immediately.

| Namespace | OVH S3 bucket | Daily backup* |
| --- | --- | --- |
| `pocket-id` | `h3rmt-backups-pg-pocket-id` | 02:00 |
| `home-assistant` | `h3rmt-backups-pg-home-assistant` | 02:30 |

\*Times use the controller's timezone, normally UTC. Both backup types use the
same bucket for each cluster, via `https://s3.de.io.cloud.ovh.net`.

Each namespace uses a SOPS-encrypted `postgres-backup-s3` Secret. Keep S3 and
database credentials backed up separately; `secret.raw.yaml` is plaintext and
ignored by Git. Uploads use HTTPS, but the manifests do not configure
encryption at rest; verify the OVH bucket settings. Do not let S3 lifecycle
rules delete objects needed by Barman's retention policy.

## Verify

For each namespace (`pocket-id` and `home-assistant`), inspect:

```sh
kubectl -n operators get helmrelease barman-cloud
kubectl -n NAMESPACE get objectstore,scheduledbackup,backup
kubectl -n NAMESPACE describe cluster storage
kubectl -n NAMESPACE describe backup BACKUP_NAME
```

Confirm that the first backup reaches `completed` and WAL archiving succeeds.
Monitor both: archive failures can cause WAL to accumulate on disk.

## Test recovery

Restore into a new, isolated cluster in the source ObjectStore's namespace.
This example restores Pocket ID to the latest available WAL; for Home Assistant,
use its namespace and a 15Gi volume.

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: storage-restore-test
  namespace: pocket-id
spec:
  instances: 1
  storage:
    storageClass: local-path
    size: 5Gi
  bootstrap:
    recovery:
      source: original
  externalClusters:
    - name: original
      plugin:
        name: barman-cloud.cloudnative-pg.io
        parameters:
          barmanObjectName: postgres-backup
          serverName: storage
```

Inspect the restored data and measure recovery time. The test cluster does not
archive WAL; use a separate destination if it needs backups. For point-in-time
recovery, see the [CNPG recovery guide](https://cloudnative-pg.io/docs/1.30/recovery/).
