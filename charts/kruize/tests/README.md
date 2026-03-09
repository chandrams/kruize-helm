# Kruize Helm Chart Tests

This directory contains unit tests for the Kruize Helm chart using the [helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin.

## Prerequisites

Install the helm-unittest plugin:

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest
```

## Running Tests

### Run OpenShift (default) Tests

```bash
helm unittest -f 'tests/*.yaml' charts/kruize
```

### Run Minikube-specific Tests

```bash
helm unittest -f 'tests/minikube/*.yaml' charts/kruize
```

### Run All Tests (default + minikube)

```bash
helm unittest charts/kruize
```

### Run a Specific Test File

```bash
helm unittest -f 'tests/kruize_deployment_test.yaml' charts/kruize
```

### Run Tests with Verbose Output

```bash
helm unittest -v charts/kruize
```

### Generate JUnit Test Report

```bash
helm unittest --output-type JUnit --output-file test-results.xml charts/kruize
```

## Directory Structure

Tests are organized under the `tests/` directory, with each test file corresponding to a template in the `templates/` directory:

```plaintext
kruize-helm/
├── charts
│   └── kruize
│       ├── Chart.yaml
│       ├── templates
│       │   ├── configmap_kruize.yaml
│       │   ├── configmap_nginx.yaml
│       │   ├── cronjobs.yaml
│       │   ├── kruize_db_deployment.yaml
│       │   ├── kruize_deployment.yaml
│       │   ├── kruize_service.yaml
│       │   ├── network_policy.yaml
│       │   └── ...
│       ├── tests
│       │   ├── configmap_test.yaml
│       │   ├── cronjobs_test.yaml
│       │   ├── kruize_db_deployment_test.yaml
│       │   ├── kruize_deployment_test.yaml
│       │   ├── kruize_service_test.yaml
│       │   ├── kruize_ui_test.yaml
│       │   ├── network_policy_test.yaml
│       │   ├── rbac_test.yaml
│       │   ├── service_monitor_test.yaml
│       │   ├── storage_test.yaml
│       │   └── minikube/
│       │       ├── configmap_minikube_test.yaml
│       │       ├── kruize_deployment_minikube_test.yaml
│       │       ├── kruize_service_minikube_test.yaml
│       │       ├── kruize_ui_minikube_test.yaml
│       │       ├── network_policy_minikube_test.yaml
│       │       ├── service_monitor_minikube_test.yaml
│       │       └── ...
│       ├── values.schema.json
│       └── values.yaml

```

## Environment-specific Tests

Tests in `tests/` use the default `values.yaml` (OpenShift deployment).

Tests in `tests/minikube/` use `values-minikube.yaml` on top of `values.yaml` via the `values:` field in each test suite. These tests validate minikube-specific behaviour such as:

- `serviceAccount.create: false` — uses the `default` service account
- `rbac.create: false` — skips OpenShift-specific ClusterRoleBindings
- `db.pgData: ""` — PGDATA env var is not set
- `db.volumeMountPath: /var/lib/postgresql/data` — minikube postgres path
- `db.pvc.accessModes: [ReadWriteOnce]` — minikube storage access mode
- `networkPolicy.enabled: true` — network policy is enabled on minikube
- Empty resource requests/limits — no resource constraints on minikube

## Test File Structure

Each test file follows the below style:

```yaml
suite: test <template-name>
templates:
  - <template-file>

tests:
  - it: should create a <Resource> with the correct default settings
    asserts:
      - hasDocuments:
          count: 1
      - equal:
          path: kind
          value: <Kind>
      - equal:
          path: metadata.name
          value: RELEASE-NAME-<name>
      # ... all default assertions grouped together

  - it: should create a <Resource> with the correct settings overrides
    set:
      some.value: override
    asserts:
      - equal:
          path: spec.someField
          value: override

  - it: should create a <Resource> in the release namespace
    release:
      namespace: custom-namespace
    asserts:
      - equal:
          path: metadata.namespace
          value: custom-namespace
```

## Common Assertions

- `equal` - Checks if a value equals the expected value
- `notEqual` - Checks if a value does not equal the expected value
- `exists` - Checks if a path exists
- `notExists` - Checks if a path does not exist
- `contains` - Checks if an array contains a specific element
- `hasDocuments` - Checks the number of documents in the output
- `matchRegex` - Checks if a value matches a regex pattern


## Adding New Tests

When adding new templates or modifying existing ones:

1. Create or update the corresponding test file in `charts/kruize/tests/`
2. Follow the naming convention: `<template-name>_test.yaml`
3. For minikube-specific behaviour, add a corresponding file in `charts/kruize/tests/minikube/` with `values: - ../../values-minikube.yaml`
4. Include tests for:
   - Default values (from `values.yaml`)
   - Settings overrides (using `set:`)
   - Conditional resource creation (enabled/disabled flags)
   - Namespace propagation (using `release.namespace`)
   - Label and selector validation

## Troubleshooting

### Plugin Not Found

```bash
helm plugin list
helm plugin install https://github.com/helm-unittest/helm-unittest
```

### Test Failures

Run with verbose output to see detailed failure information:
```bash
helm unittest -v charts/kruize
```

### Debugging Specific Tests

```bash
helm unittest -f 'tests/kruize_deployment_test.yaml' -v charts/kruize
```

## Resources

- [Helm Unittest Documentation](https://github.com/helm-unittest/helm-unittest/blob/main/DOCUMENT.md)
- [Helm Chart Testing Guide](https://helm.sh/docs/topics/chart_tests/)