# PostgreSQL backups to OVH Object Storage

The Flux manifests configure the CloudNativePG Barman Cloud plugin for
continuous WAL archiving and daily full backups. WAL alone is not a usable
backup; check that the initial full backup succeeds and test recovery.

The CloudNativePG chart currently pinned in the repository is 0.29.2 (operator
1.30.2). The plugin chart is 0.9.0 (plugin 0.16.0), which requires
CloudNativePG 1.30 or later and cert-manager. The plugin HelmRelease depends
on both existing HelmReleases and uses the operator's namespace.

## Object storage and credentials

Home Assistant uses `h3rmt-backups-pg-home-assistant` and Pocket ID uses
`h3rmt-backups-pg-pocket-id`, both through
`https://s3.de.io.cloud.ovh.net`. Each bucket contains both the base backups
and the WAL archive for its PostgreSQL cluster. Never bypass the plugin's
empty-archive safety check to reuse an old archive.

Each namespace has a SOPS-encrypted `postgres-backup-s3` Secret containing
`ACCESS_KEY_ID` and `ACCESS_SECRET_KEY`. Keys require list, read, write, and
delete permissions for backups, recovery, and retention. Preserve the S3
credentials and application/database secrets outside the cluster as part of the
disaster recovery plan. The `secret.raw.yaml` files are plaintext and ignored
by Git; do not commit them.

Uploads use HTTPS. These manifests do not explicitly configure encryption at
rest; verify the bucket's default encryption independently. Backup data is
sensitive.

The `apps` Flux Kustomization depends on `infrastructure`, which installs the
plugin. The app components add the plugin configuration to each `storage`
cluster, as well as an ObjectStore and ScheduledBackup. Their JSON patches
replace `/spec/plugins` if it already exists; revisit them before adding other
plugins. Enabling the plugin can roll database pods, so check cluster health
afterwards.

Each schedule requests an immediate backup, followed by a daily backup at
02:00 for Pocket ID and 02:30 for Home Assistant, in the controller's timezone
(normally UTC). Barman retains a 30-day recovery window, including the base
backup and WAL required for that window. CNPG prefers taking base backups from
a standby when one is available. The five-minute WAL archive timeout is the
CNPG default; successful uploads are necessary to achieve that recovery point.

## Verify

For each namespace (`pocket-id` and `home-assistant`), inspect:

```sh
kubectl -n operators get helmrelease barman-cloud
kubectl -n NAMESPACE get objectstore,scheduledbackup,backup
kubectl -n NAMESPACE describe cluster storage
kubectl -n NAMESPACE describe backup BACKUP_NAME
```

Confirm that the first backup reaches `completed`, WAL archiving succeeds,
and objects appear under the expected S3 prefix. Check the plugin and database
pod logs if they do not. Monitor both scheduled backups and WAL archiving; an
archive failure can also cause WAL to accumulate on the PostgreSQL volume.
Do not configure independent S3 lifecycle expiration to delete backup files or
WAL still needed by Barman's retention policy.

## Test recovery

Restore into a new, isolated CNPG cluster in the same namespace as the source
ObjectStore, without pointing any production application to it. The example
below restores Pocket ID to the latest available WAL. For Home Assistant, use
its namespace and a 15Gi volume. Keep a copy of the original application and
database Secrets separately; physical backups do not contain Kubernetes
Secrets.

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
      # For point-in-time recovery, add recoveryTarget.targetTime with an
      # explicit timezone, e.g. "2026-11-24T12:00:00Z".
  externalClusters:
    - name: original
      plugin:
        name: barman-cloud.cloudnative-pg.io
        parameters:
          barmanObjectName: postgres-backup
          serverName: storage
```

Inspect the restored data and measure recovery time. This example does not
enable archiving for the restored cluster; use a separate destination or unique
server name if it later needs its own backups. See the upstream
[plugin documentation](https://cloudnative-pg.io/plugin-barman-cloud/docs/usage/)
and [CNPG recovery guide](https://cloudnative-pg.io/docs/1.30/recovery/).
