# Kruize Helm Chart

A Helm chart for deploying [Kruize](https://github.com/kruize/autotune) on Kubernetes/OpenShift clusters.

## Introduction

Kruize is an intelligent resource optimization platform that helps you optimize your Kubernetes workloads by providing recommendations for CPU and memory resources based on actual usage patterns.

## Prerequisites

- Kubernetes 1.19+ or OpenShift 4.x+
- Helm 3.0+

## Installing the Chart

To install the chart with the release name `kruize`:

```bash
helm install kruize ./charts/kruize
```

To install in a specific namespace:

```bash
helm install kruize ./charts/kruize --namespace kruize --create-namespace
```

## Uninstalling the Chart

To uninstall/delete the `kruize` deployment:

```bash
helm uninstall kruize
```

## Configuration

The following table lists the configurable parameters of the Kruize chart and their default values.

### Kruize Container Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kruize.image.repository` | Repository for Kruize container image | `quay.io/kruize/autotune_operator` |
| `kruize.image.pullPolicy` | Image pull policy for the Kruize container image | `Always` |
| `kruize.image.tag` | Image tag for Kruize container | `0.8.1` |
| `kruize.replicaCount` | Replica count for the Kruize container | `1` |
| `kruize.resources.requests.memory` | Memory resource request for the Kruize container | `768Mi` |
| `kruize.resources.requests.cpu` | CPU resource request for the Kruize container | `0.7` |
| `kruize.resources.limits.memory` | Memory resource limit for the Kruize container | `768Mi` |
| `kruize.resources.limits.cpu` | CPU resource limit for the Kruize container | `0.7` |
| `kruize.service.type` | Kruize service type | `NodePort` |
| `kruize.service.port` | Kruize service port | `8080` |

### Kruize Environment Variables

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kruize.env[].LOGGING_LEVEL` | Logging level for Kruize | `info` |
| `kruize.env[].ROOT_LOGGING_LEVEL` | Root logging level | `error` |
| `kruize.env[].DB_CONFIG_FILE` | Path to database configuration file | `/etc/config/dbconfigjson` |
| `kruize.env[].KRUIZE_CONFIG_FILE` | Path to Kruize configuration file | `/etc/config/kruizeconfigjson` |
| `kruize.env[].JAVA_TOOL_OPTIONS` | Java tool options | `-XX:MaxRAMPercentage=80` |
| `kruize.env[].KAFKA_BOOTSTRAP_SERVERS` | Kafka bootstrap servers | `kruize-kafka-cluster-kafka-bootstrap.kafka.svc.cluster.local:9092` |
| `kruize.env[].KAFKA_TOPICS` | Kafka topics | `recommendations-topic,error-topic,summary-topic` |
| `kruize.env[].KAFKA_RESPONSE_FILTER_INCLUDE` | Kafka response filter include patterns | `experiments\|status\|apis\|recommendations\|response\|status_history` |
| `kruize.env[].KAFKA_RESPONSE_FILTER_EXCLUDE` | Kafka response filter exclude patterns | `""` |

### Kruize Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kruize.config.clusterType` | Type of cluster | `kubernetes` |
| `kruize.config.k8sType` | Kubernetes distribution type | `openshift` |
| `kruize.config.authType` | Authentication type | `""` |
| `kruize.config.monitoringAgent` | Monitoring agent to use | `prometheus` |
| `kruize.config.monitoringService` | Monitoring service name | `prometheus-k8s` |
| `kruize.config.monitoringEndPoint` | Monitoring endpoint | `prometheus-k8s` |
| `kruize.config.saveToDB` | Enable saving data to database | `true` |
| `kruize.config.dbDriver` | Database driver | `jdbc:postgresql://` |
| `kruize.config.plots` | Enable plots generation | `true` |
| `kruize.config.isROSEnabled` | Enable ROS (Resource Optimization Service) | `false` |
| `kruize.config.local` | Run in local mode | `true` |
| `kruize.config.logAllHttpReqAndResp` | Log all HTTP requests and responses | `true` |
| `kruize.config.experimentNameFormat` | Format for experiment names | `%datasource%\|%clustername%\|%namespace%\|%workloadname%(%workloadtype%)\|%containername%` |
| `kruize.config.bulkapilimit` | Bulk API limit | `1000` |
| `kruize.config.isKafkaEnabled` | Enable Kafka integration | `false` |

### Kruize Hibernate Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kruize.config.hibernate.dialect` | Hibernate dialect | `org.hibernate.dialect.PostgreSQLDialect` |
| `kruize.config.hibernate.driver` | Hibernate driver | `org.postgresql.Driver` |
| `kruize.config.hibernate.c3p0minsize` | C3P0 minimum pool size | `5` |
| `kruize.config.hibernate.c3p0maxsize` | C3P0 maximum pool size | `10` |
| `kruize.config.hibernate.c3p0timeout` | C3P0 timeout | `300` |
| `kruize.config.hibernate.c3p0maxstatements` | C3P0 max statements | `100` |
| `kruize.config.hibernate.hbm2ddlauto` | Hibernate hbm2ddl.auto setting | `none` |
| `kruize.config.hibernate.showsql` | Show SQL queries | `false` |
| `kruize.config.hibernate.timezone` | Database timezone | `UTC` |

### Kruize Logging Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kruize.config.logging.cloudwatch.accessKeyId` | AWS CloudWatch access key ID | `""` |
| `kruize.config.logging.cloudwatch.logGroup` | CloudWatch log group | `kruize-logs` |
| `kruize.config.logging.cloudwatch.logStream` | CloudWatch log stream | `kruize-stream` |
| `kruize.config.logging.cloudwatch.region` | AWS region for CloudWatch | `""` |
| `kruize.config.logging.cloudwatch.secretAccessKey` | AWS CloudWatch secret access key | `""` |
| `kruize.config.logging.cloudwatch.logLevel` | CloudWatch log level | `INFO` |

### Kruize Datasource Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kruize.config.datasource[0].name` | Name of the first datasource | `prometheus-1` |
| `kruize.config.datasource[0].provider` | Provider type | `prometheus` |
| `kruize.config.datasource[0].serviceName` | Service name | `prometheus-k8s` |
| `kruize.config.datasource[0].namespace` | Namespace | `openshift-monitoring` |
| `kruize.config.datasource[0].url` | Datasource URL | `""` |
| `kruize.config.datasource[0].authentication.type` | Authentication type | `bearer` |
| `kruize.config.datasource[0].authentication.credentials.tokenFilePath` | Token file path | `/var/run/secrets/kubernetes.io/serviceaccount/token` |
| `kruize.config.datasource[1].name` | Name of the second datasource | `thanos-1` |
| `kruize.config.datasource[1].provider` | Provider type | `prometheus` |
| `kruize.config.datasource[1].serviceName` | Service name | `thanos-querier` |
| `kruize.config.datasource[1].namespace` | Namespace | `openshift-monitoring` |
| `kruize.config.datasource[1].url` | Datasource URL | `""` |
| `kruize.config.datasource[1].authentication.type` | Authentication type | `bearer` |
| `kruize.config.datasource[1].authentication.credentials.tokenFilePath` | Token file path | `/var/run/secrets/kubernetes.io/serviceaccount/token` |

### Kruize Database Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `db.image.repository` | Repository for Kruize DB container image | `quay.io/kruizehub/postgres` |
| `db.image.pullPolicy` | Image pull policy for the Kruize DB container image | `IfNotPresent` |
| `db.image.tag` | Image tag for Kruize DB container | `15.2` |
| `db.service.name` | Kruize DB service name | `kruize-db-service` |
| `db.service.type` | Kruize DB service type | `ClusterIP` |
| `db.service.port` | Kruize DB service port | `5432` |
| `db.resources.requests.memory` | Memory resource request for the Kruize DB container | `100Mi` |
| `db.resources.requests.cpu` | CPU resource request for the Kruize DB container | `0.5` |
| `db.resources.limits.memory` | Memory resource limit for the Kruize DB container | `100Mi` |
| `db.resources.limits.cpu` | CPU resource limit for the Kruize DB container | `0.5` |
| `db.pvc.storageClass` | Storage class for database PVC | `manual` |
| `db.pvc.storageSize` | Storage size for database PVC | `500Mi` |
| `db.pvc.hostPath` | Host path for database storage | `/mnt/data` |
| `db.pvc.accessModes` | Access modes for PVC | `[ReadWriteMany]` |
| `db.volumeMountPath` | Volume mount path for database data | `/var/lib/pgsql/data` |
| `db.pgData` | PGDATA environment variable value | `/var/lib/pg_data` |
| `db.user` | User for Kruize DB container | `admin` |
| `db.password` | Password for Kruize DB container | `admin` |
| `db.adminUser` | Admin user for Kruize DB container | `admin` |
| `db.adminPassword` | Admin password for Kruize DB container | `admin` |
| `db.name` | Name of the Kruize DB | `kruizeDB` |
| `db.sslMode` | SSL mode for database connection | `require` |

### Kruize UI Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kruizeUI.image.repository` | Repository for Kruize UI container image | `quay.io/kruize/kruize-ui` |
| `kruizeUI.image.pullPolicy` | Image pull policy for the Kruize UI container image | `Always` |
| `kruizeUI.image.tag` | Image tag for Kruize UI container | `0.0.8` |
| `kruizeUI.service.type` | Kruize UI service type | `NodePort` |
| `kruizeUI.service.port` | Kruize UI service port | `8080` |

### Monitoring Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `monitoring.enabled` | Enable ServiceMonitor for Prometheus Operator | `true` |
| `monitoring.interval` | Metrics scraping interval | `30s` |

### CronJob Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cronJob.deletePartitionsThreshold` | Threshold for deleting old partitions (days) | `15` |
| `cronJob.createSchedule` | Schedule for running the cron job | `0 0 25 * *` |

### Other Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Specifies whether a service account should be created | `true` |
| `serviceAccount.name` | The name of the service account to use | `""` |
| `rbac.create` | Specifies whether OpenShift-specific RBAC resources should be created | `true` |
| `nameOverride` | Overrides the name of this Chart | `""` |
| `fullnameOverride` | Overrides the fully qualified application name | `""` |
| `networkPolicy.enabled` | Enable NetworkPolicy resources | `false` |

## Example: Custom Values

Create a `custom-values.yaml` file:

```yaml
kruize:
  replicaCount: 2
  resources:
    requests:
      memory: "1Gi"
      cpu: "1"
    limits:
      memory: "1Gi"
      cpu: "1"
```

Install with custom values:

```bash
helm install kruize ./charts/kruize -f custom-values.yaml
```

