# Kruize Helm Chart Integration Tests

This directory contains integration tests for the Kruize Helm chart that deploy the chart to an actual Kubernetes cluster and validate the deployment.

## Overview

Integration tests verify that:
- The Helm chart deploys successfully to a real cluster
- All Kubernetes resources are created correctly
- Pods start and become ready
- Services are accessible
- Database connectivity works
- API endpoints respond correctly

## Prerequisites

### Required Tools

- **kubectl** (v1.25+) - Kubernetes command-line tool
- **helm** (v3.0+) - Helm package manager
- **bash** (v4.0+) - Shell for running scripts

### Cluster Requirements

- A running Kubernetes cluster (Minikube, Kind, GKE, EKS, AKS, OpenShift, etc.)
- Sufficient resources:
  - At least 2 CPU cores available
  - At least 2GB RAM available
  - Storage provisioner for PVCs
- kubectl configured to access the cluster
- Appropriate permissions to create namespaces and deploy resources

### Optional

- **Prometheus** - For monitoring integration (if `monitoring.enabled: true`)
- **Storage Class** - For dynamic volume provisioning

## Quick Start

### 1. Basic Integration Test

Deploy and validate the chart with default settings:

```bash
cd charts/kruize/tests/integration
./deploy-test.sh
```

This will:
- Create a test namespace (`kruize-test`)
- Deploy the Helm chart
- Wait for all pods to be ready
- Run validation tests
- Display results

### 2. Test with Custom Values

Deploy with integration test values:

```bash
./deploy-test.sh -v values-integration-test.yaml
```

### 3. Test on Minikube

Deploy with Minikube-specific configuration:

```bash
./deploy-test.sh -v values-minikube-integration-test.yaml
```

### 4. Test with Cleanup

Deploy, test, and automatically clean up:

```bash
./deploy-test.sh -v values-integration-test.yaml --cleanup
```

### 5. Test with Custom Image Versions

Deploy with specific Kruize and Kruize UI image versions:

```bash
./deploy-test.sh \
  -v values-integration-test.yaml \
  --kruize-image-repo quay.io/kruize/autotune_operator \
  --kruize-image-tag 0.9 \
  --kruize-ui-image-repo quay.io/kruize/kruize-ui \
  --kruize-ui-image-tag latest
```

## Test Scripts

### deploy-test.sh

Main deployment and testing script.

**Usage:**
```bash
./deploy-test.sh [OPTIONS]
```

**Options:**
- `-n, --namespace NAMESPACE` - Namespace to deploy to (default: `kruize-test`)
- `-r, --release RELEASE` - Helm release name (default: `kruize-test`)
- `-v, --values VALUES_FILE` - Values file to use (default: `values.yaml`)
- `-t, --timeout TIMEOUT` - Timeout for deployment (default: `5m`)
- `-c, --cleanup` - Cleanup after test
- `--kruize-image-repo REPOSITORY` - Override Kruize image repository
- `--kruize-image-tag TAG` - Override Kruize image tag
- `--kruize-ui-image-repo REPOSITORY` - Override Kruize UI image repository
- `--kruize-ui-image-tag TAG` - Override Kruize UI image tag
- `-h, --help` - Show help message

**Examples:**

```bash
# Deploy to custom namespace
./deploy-test.sh -n my-test-namespace

# Deploy with custom release name
./deploy-test.sh -r my-release

# Deploy with 10-minute timeout
./deploy-test.sh -t 10m

# Deploy with custom values and cleanup
./deploy-test.sh -v values-integration-test.yaml --cleanup

# Deploy with custom Kruize image version
./deploy-test.sh \
  --kruize-image-repo quay.io/kruize/autotune_operator \
  --kruize-image-tag 0.9

# Deploy with custom Kruize UI image version
./deploy-test.sh \
  --kruize-ui-image-repo quay.io/kruize/kruize-ui \
  --kruize-ui-image-tag latest

# Deploy with both custom images
./deploy-test.sh \
  -v values-integration-test.yaml \
  --kruize-image-repo quay.io/myorg/kruize \
  --kruize-image-tag dev-123 \
  --kruize-ui-image-repo quay.io/myorg/kruize-ui \
  --kruize-ui-image-tag dev-456 \
  --cleanup
```

### validate-deployment.sh

Validates that the deployment is working correctly.

**Usage:**
```bash
./validate-deployment.sh [OPTIONS]
```

**Options:**
- `-n, --namespace NAMESPACE` - Namespace to validate (default: `kruize-test`)
- `-r, --release RELEASE` - Helm release name (default: `kruize-test`)
- `-t, --timeout TIMEOUT` - Timeout for checks (default: `5m`)
- `-h, --help` - Show help message

**Validation Tests:**
1. Namespace exists
2. Helm release is deployed
3. Kruize deployment is ready
4. Kruize DB deployment is ready
5. Kruize UI pod is running
6. All services exist
7. ConfigMaps are created
8. PVC is bound
9. Pods are not restarting excessively
10. Database connectivity works
11. Kruize API health check passes

**Examples:**

```bash
# Validate default deployment
./validate-deployment.sh

# Validate custom deployment
./validate-deployment.sh -n my-namespace -r my-release

# Run validation with extended timeout
./validate-deployment.sh -t 10m
```

### cleanup.sh

Cleans up test resources.

**Usage:**
```bash
./cleanup.sh [OPTIONS]
```

**Options:**
- `-n, --namespace NAMESPACE` - Namespace to clean up (default: `kruize-test`)
- `-r, --release RELEASE` - Helm release name (default: `kruize-test`)
- `-a, --all` - Delete namespace after cleanup
- `-f, --force` - Force cleanup without confirmation
- `-h, --help` - Show help message

**Examples:**

```bash
# Clean up with confirmation
./cleanup.sh

# Clean up and delete namespace
./cleanup.sh --all

# Force cleanup without confirmation
./cleanup.sh -f

# Clean up custom deployment
./cleanup.sh -n my-namespace -r my-release --all
```

## Test Configuration Files

### values-integration-test.yaml

Minimal configuration for integration testing on standard Kubernetes clusters.

**Key Features:**
- Reduced resource requirements
- ClusterIP services (not NodePort)
- Monitoring disabled
- Network policies disabled
- RBAC disabled (uses default service account)
- Single replica for all components

**Use Case:** Testing on resource-constrained clusters or CI/CD environments.

### values-minikube-integration-test.yaml

Configuration optimized for Minikube testing.

**Key Features:**
- No resource limits/requests (Minikube flexibility)
- NodePort services for easy access
- Network policies enabled
- Uses `standard` storage class
- Default service account
- RBAC disabled

**Use Case:** Local development and testing on Minikube.

## Testing Workflows

### Workflow 1: Quick Validation

Test that the chart deploys successfully:

```bash
# Deploy
./deploy-test.sh -v values-integration-test.yaml

# Validate (optional, already run by deploy-test.sh)
./validate-deployment.sh

# Cleanup
./cleanup.sh --all -f
```

### Workflow 2: Manual Testing

Deploy and keep running for manual testing:

```bash
# Deploy
./deploy-test.sh -v values-integration-test.yaml

# Access services
kubectl port-forward -n kruize-test svc/kruize-test-kruize 8080:8080
kubectl port-forward -n kruize-test svc/kruize-test-kruize-ui-nginx-service 8081:8080

# Test manually
curl http://localhost:8080/health
# Open browser to http://localhost:8081

# Cleanup when done
./cleanup.sh --all
```

### Workflow 3: Minikube Testing

Test on Minikube with NodePort access:

```bash
# Start Minikube (if not running)
minikube start --cpus=2 --memory=4096

# Deploy
./deploy-test.sh -v values-minikube-integration-test.yaml

# Get service URLs
minikube service kruize-test-kruize -n kruize-test --url
minikube service kruize-test-kruize-ui-nginx-service -n kruize-test --url

# Test the services
curl $(minikube service kruize-test-kruize -n kruize-test --url)/health

# Cleanup
./cleanup.sh --all -f
```

### Workflow 4: CI/CD Pipeline

Automated testing in CI/CD:

```bash
#!/bin/bash
set -e

# Deploy with timeout
./deploy-test.sh -v values-integration-test.yaml -t 10m

# Run additional custom tests here
# ...

# Always cleanup
./cleanup.sh --all -f
```

## Troubleshooting

### Pods Not Starting

Check pod status and logs:

```bash
kubectl get pods -n kruize-test
kubectl describe pod <pod-name> -n kruize-test
kubectl logs <pod-name> -n kruize-test
```

### PVC Not Binding

Check PVC and storage class:

```bash
kubectl get pvc -n kruize-test
kubectl get storageclass
kubectl describe pvc <pvc-name> -n kruize-test
```

For Minikube, ensure storage provisioner is enabled:

```bash
minikube addons enable storage-provisioner
minikube addons enable default-storageclass
```

### Service Not Accessible

Check service and endpoints:

```bash
kubectl get svc -n kruize-test
kubectl get endpoints -n kruize-test
kubectl describe svc <service-name> -n kruize-test
```

### Database Connection Issues

Check database pod and logs:

```bash
kubectl get pods -n kruize-test -l app.kubernetes.io/name=kruize-db
kubectl logs <db-pod-name> -n kruize-test
kubectl exec <db-pod-name> -n kruize-test -- pg_isready -U admin
```

### Validation Tests Failing

Run validation with verbose output:

```bash
./validate-deployment.sh -n kruize-test -r kruize-test
```

Check specific resources:

```bash
kubectl get all -n kruize-test
helm status kruize-test -n kruize-test
```

### Cleanup Issues

Force delete stuck resources:

```bash
kubectl delete namespace kruize-test --force --grace-period=0
```

## Best Practices

1. **Use Dedicated Namespaces**: Always use a dedicated namespace for testing to avoid conflicts
2. **Clean Up After Tests**: Always run cleanup after tests to free resources
3. **Monitor Resources**: Check cluster resources before running tests
4. **Use Appropriate Values**: Choose the right values file for your environment
5. **Check Prerequisites**: Ensure all prerequisites are met before running tests
6. **Review Logs**: Check logs if tests fail to understand the issue
7. **Test Incrementally**: Test individual components before full integration

## CI/CD Integration

### GitHub Actions Example

See `.github/workflows/integration-test.yaml` for a complete example.


## Advanced Usage

### Custom Validation

Add custom validation tests by modifying `validate-deployment.sh` or creating additional scripts:

```bash
# Custom test script
./my-custom-test.sh -n kruize-test -r kruize-test
```

### Performance Testing

Use the deployed instance for performance testing:

```bash
# Deploy
./deploy-test.sh -v values-integration-test.yaml

# Run performance tests
kubectl run -it --rm load-test --image=busybox --restart=Never -- \
  wget -O- http://kruize-test-kruize.kruize-test.svc.cluster.local:8080/health

# Cleanup
./cleanup.sh --all -f
```

### Multi-Environment Testing

Test across different environments:

```bash
# Test on Minikube
./deploy-test.sh -v values-minikube-integration-test.yaml -n kruize-minikube --cleanup

# Test on standard K8s
./deploy-test.sh -v values-integration-test.yaml -n kruize-k8s --cleanup
```

## Resources

- [Kruize Documentation](https://kruize.io)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Chart Testing Guide](https://helm.sh/docs/topics/chart_tests/)

## Contributing

When adding new integration tests:

1. Update test scripts to include new validation checks
2. Add new test scenarios to this README
3. Ensure tests are idempotent and can be run multiple times
4. Document any new prerequisites or requirements
5. Test on multiple Kubernetes distributions if possible

## Support

For issues or questions:
- Open an issue on [GitHub](https://github.com/kruize/kruize-helm/issues)
- Check existing [documentation](https://kruize.io)
- Review [troubleshooting](#troubleshooting) section above