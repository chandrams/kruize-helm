# Kruize Helm Chart Tests

This directory contains unit tests for the Kruize Helm chart using the [helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin.

## Prerequisites

Install the helm-unittest plugin:

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest
```

## Running Tests

### Run All Tests (OpenShift/default values)

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

## Test Structure

```
tests/
├── configmap_test.yaml              # Tests for configmap_kruize.yaml and configmap_nginx.yaml
├── cronjobs_test.yaml               # Tests for cronjobs.yaml
├── kruize_db_deployment_test.yaml   # Tests for kruize_db_deployment.yaml
├── kruize_db_service_test.yaml      # Tests for kruize_db_service.yaml
├── kruize_deployment_test.yaml      # Tests for kruize_deployment.yaml
├── kruize_service_test.yaml         # Tests for kruize_service.yaml
├── kruize_ui_test.yaml              # Tests for kruize_ui_nginx_pod.yaml and kruize_ui_nginx_service.yaml
├── network_policy_test.yaml         # Tests for network_policy.yaml
├── rbac_test.yaml                   # Tests for service_account.yaml, role.yaml, rolebinding.yaml
├── service_monitor_test.yaml        # Tests for service_monitor.yaml
├── storage_test.yaml                # Tests for storage_pv.yaml and storage_pvc.yaml
└── minikube/
    ├── kruize_db_deployment_minikube_test.yaml  # DB deployment tests with values-minikube.yaml
    ├── kruize_deployment_minikube_test.yaml     # Kruize deployment tests with values-minikube.yaml
    ├── network_policy_minikube_test.yaml        # Network policy tests with values-minikube.yaml
    ├── rbac_minikube_test.yaml                  # RBAC tests with values-minikube.yaml
    └── storage_minikube_test.yaml               # Storage tests with values-minikube.yaml
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

Each test file follows the cryostat-helm style:

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

## Continuous Integration

```yaml
# Example GitHub Actions workflow
- name: Install Helm
  uses: azure/setup-helm@v3

- name: Install helm-unittest plugin
  run: helm plugin install https://github.com/helm-unittest/helm-unittest

- name: Run Helm tests (OpenShift)
  run: helm unittest -f 'tests/*.yaml' charts/kruize

- name: Run Helm tests (Minikube)
  run: helm unittest -f 'tests/minikube/*.yaml' charts/kruize
```

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