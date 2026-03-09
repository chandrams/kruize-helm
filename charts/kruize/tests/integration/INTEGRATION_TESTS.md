# Kruize Helm Chart Integration Tests - Overview

## What Are Integration Tests?

Integration tests validate that the Kruize Helm chart deploys successfully to a real Kubernetes cluster and that all components work together correctly. Unlike unit tests that validate individual templates, integration tests:

- Deploy the actual chart to a live cluster
- Verify all resources are created and healthy
- Test inter-component communication
- Validate API endpoints and database connectivity
- Ensure the system works end-to-end

## Test Suite Components

### 1. Deployment Script (`deploy-test.sh`)
Automates the deployment process:
- Creates test namespace
- Deploys Helm chart with specified values
- Waits for all resources to be ready
- Runs validation tests
- Optionally cleans up after testing

### 2. Validation Script (`validate-deployment.sh`)
Comprehensive validation of deployed resources:
- ✅ Helm release status
- ✅ Namespace existence
- ✅ Deployment readiness (Kruize, DB, UI)
- ✅ Service availability
- ✅ ConfigMap creation
- ✅ PVC binding
- ✅ Pod health (restart counts)
- ✅ Database connectivity
- ✅ API health checks

### 3. Cleanup Script (`cleanup.sh`)
Safe resource cleanup:
- Uninstalls Helm release
- Removes PVCs and PVs
- Deletes remaining resources
- Optionally removes namespace
- Confirms before destructive operations

### 4. Test Configuration Files

#### `values-integration-test.yaml`
Optimized for standard Kubernetes clusters:
- Minimal resource requirements
- ClusterIP services
- Disabled monitoring and network policies
- Suitable for CI/CD environments

#### `values-minikube-integration-test.yaml`
Optimized for Minikube:
- No resource limits (flexible)
- NodePort services for easy access
- Network policies enabled
- Uses standard storage class

### 5. CI/CD Workflow (`.github/workflows/integration-test.yaml`)
Automated testing pipeline:
- Runs on push/PR to main branches
- Tests on Kind cluster
- Optional Minikube testing
- Includes lint, template, and unit tests
- Generates test reports

## Quick Start Examples

### Example 1: Basic Test
```bash
cd charts/kruize/tests/integration
./deploy-test.sh -v values-integration-test.yaml --cleanup
```

### Example 2: Minikube Test
```bash
minikube start --cpus=2 --memory=4096
cd charts/kruize/tests/integration
./deploy-test.sh -v values-minikube-integration-test.yaml
# Test manually, then cleanup
./cleanup.sh --all
```

### Example 3: Custom Namespace
```bash
./deploy-test.sh \
  -n my-test-namespace \
  -r my-release \
  -v values-integration-test.yaml \
  -t 10m \
  --cleanup
```

### Example 4: Test Custom Image Versions
```bash
# Test a specific Kruize version
./deploy-test.sh \
  -v values-integration-test.yaml \
  --kruize-image-tag 0.9 \
  --cleanup

# Test development builds
./deploy-test.sh \
  -v values-integration-test.yaml \
  --kruize-image-repo quay.io/myorg/kruize \
  --kruize-image-tag dev-branch-123 \
  --kruize-ui-image-repo quay.io/myorg/kruize-ui \
  --kruize-ui-image-tag dev-branch-456 \
  --cleanup
```

## Test Scenarios Covered

### Scenario 1: Standard Deployment
- **Purpose**: Verify basic deployment works
- **Configuration**: `values-integration-test.yaml`
- **Validates**: All core components deploy and start

### Scenario 2: Minikube Deployment
- **Purpose**: Verify local development setup
- **Configuration**: `values-minikube-integration-test.yaml`
- **Validates**: NodePort access, network policies

### Scenario 3: Resource Constraints
- **Purpose**: Test with minimal resources
- **Configuration**: Reduced CPU/memory in values
- **Validates**: System works under constraints

### Scenario 4: Database Persistence
- **Purpose**: Verify data persistence
- **Configuration**: PVC with specific storage class
- **Validates**: Data survives pod restarts

### Scenario 5: Multi-Instance
- **Purpose**: Test multiple releases in same cluster
- **Configuration**: Different release names
- **Validates**: No resource conflicts

### Scenario 6: Custom Image Versions
- **Purpose**: Test specific Kruize and UI versions
- **Configuration**: Image overrides via command-line flags
- **Validates**: Custom images deploy correctly
- **Use Cases**:
  - Testing development builds
  - Testing release candidates
  - Testing hotfixes
  - Testing custom forks

## Validation Checks

### Resource Validation
- [x] Deployments exist and are ready
- [x] Pods are running and not restarting
- [x] Services are created with correct types
- [x] ConfigMaps contain expected data
- [x] PVCs are bound to PVs
- [x] Service accounts exist (if enabled)

### Functional Validation
- [x] Database accepts connections
- [x] Kruize API responds to health checks
- [x] UI is accessible
- [x] Inter-service communication works
- [x] Environment variables are set correctly

### Performance Validation
- [x] Pods start within timeout
- [x] Services become ready quickly
- [x] No excessive resource usage
- [x] No memory leaks (restart counts)

## Test Results Interpretation

### Success Indicators
```
[SUCCESS] Helm release deployed successfully
[SUCCESS] All pods are ready
[PASS] Kruize deployment is ready (1/1 replicas)
[PASS] Database is accepting connections
[PASS] Kruize API health check passed
```

### Failure Indicators
```
[ERROR] Failed to deploy Helm chart
[FAIL] Kruize deployment not ready (0/1 replicas)
[FAIL] Database connectivity check failed
[WARNING] Pod 'kruize-xxx' has 5 restarts
```

## Troubleshooting Guide

### Issue: Pods Not Starting
**Symptoms**: Pods stuck in Pending or CrashLoopBackOff
**Solutions**:
1. Check resource availability: `kubectl describe node`
2. Check pod events: `kubectl describe pod <pod-name> -n <namespace>`
3. Check logs: `kubectl logs <pod-name> -n <namespace>`
4. Verify image pull: Check image repository and pull policy

### Issue: PVC Not Binding
**Symptoms**: PVC stuck in Pending state
**Solutions**:
1. Check storage class: `kubectl get storageclass`
2. For Minikube: Enable storage provisioner
3. Check PV availability: `kubectl get pv`
4. Verify access modes match

### Issue: Service Not Accessible
**Symptoms**: Cannot connect to services
**Solutions**:
1. Check service endpoints: `kubectl get endpoints -n <namespace>`
2. Verify pod labels match service selectors
3. Check network policies (if enabled)
4. For NodePort: Verify port is accessible

### Issue: Database Connection Failed
**Symptoms**: Kruize cannot connect to database
**Solutions**:
1. Check DB pod is running: `kubectl get pods -n <namespace>`
2. Verify DB service exists: `kubectl get svc -n <namespace>`
3. Check DB logs: `kubectl logs <db-pod> -n <namespace>`
4. Verify connection string in ConfigMap

## Best Practices

### Before Running Tests
1. ✅ Ensure cluster has sufficient resources
2. ✅ Verify kubectl is configured correctly
3. ✅ Check storage provisioner is available
4. ✅ Review values file for your environment
5. ✅ Ensure no conflicting resources exist

### During Tests
1. ✅ Monitor resource usage
2. ✅ Check logs for errors
3. ✅ Verify each component individually
4. ✅ Test incrementally (don't skip steps)
5. ✅ Document any issues encountered

### After Tests
1. ✅ Always run cleanup script
2. ✅ Verify all resources are deleted
3. ✅ Check for orphaned PVs
4. ✅ Review test results
5. ✅ Update documentation if needed

## CI/CD Integration

### GitHub Actions
The workflow automatically:
- Triggers on push/PR to main branches
- Creates Kind cluster
- Runs integration tests
- Generates test reports
- Cleans up resources

### Manual Trigger
```bash
# Trigger workflow manually
gh workflow run integration-test.yaml -f cluster_type=kind
```

### Local CI Testing
```bash
# Simulate CI environment locally
act -j integration-test-kind
```

## Performance Benchmarks

### Expected Deployment Times
- **Kind cluster**: 3-5 minutes
- **Minikube**: 4-6 minutes
- **Cloud clusters**: 5-8 minutes

### Resource Usage
- **Kruize**: ~512MB RAM, 0.5 CPU
- **Database**: ~100MB RAM, 0.2 CPU
- **UI**: ~50MB RAM, 0.1 CPU
- **Total**: ~700MB RAM, 1 CPU

### Test Duration
- **Deployment**: 2-3 minutes
- **Validation**: 1-2 minutes
- **Cleanup**: 1 minute
- **Total**: 4-6 minutes

## Extending the Tests

### Adding New Validation Checks
Edit `validate-deployment.sh`:
```bash
test_custom_feature() {
    log_info "Test: Checking custom feature..."
    # Add your test logic here
    if [ condition ]; then
        log_test_pass "Custom feature works"
        return 0
    else
        log_test_fail "Custom feature failed"
        return 1
    fi
}
```

### Adding New Test Scenarios
Create new values file:
```yaml
# values-custom-test.yaml
# Your custom configuration
```

Run with custom values:
```bash
./deploy-test.sh -v values-custom-test.yaml
```

### Adding New CI/CD Jobs
Edit `.github/workflows/integration-test.yaml`:
```yaml
custom-test:
  name: Custom Integration Test
  runs-on: ubuntu-latest
  steps:
    # Your custom test steps
```

## Metrics and Reporting

### Test Metrics Collected
- Deployment success rate
- Average deployment time
- Resource usage patterns
- Failure reasons
- Test coverage

### Viewing Test Results
```bash
# View deployment status
kubectl get all -n kruize-test

# View test logs
./validate-deployment.sh -n kruize-test

# Generate report
helm test kruize-test -n kruize-test
```

## Support and Resources

### Documentation
- [Main README](README.md) - Detailed usage guide
- [Kruize Docs](https://kruize.io) - Official documentation
- [Helm Docs](https://helm.sh/docs/) - Helm reference

### Getting Help
- GitHub Issues: Report bugs or request features
- Slack/Discord: Community support
- Email: Direct support contact

### Contributing
1. Fork the repository
2. Create feature branch
3. Add/modify tests
4. Run full test suite
5. Submit pull request

## Changelog

### v1.0.0 (Current)
- Initial integration test suite
- Support for Kind and Minikube
- Comprehensive validation checks
- CI/CD workflow integration
- Detailed documentation

### Future Enhancements
- [ ] Support for more cluster types (EKS, GKE, AKS)
- [ ] Performance testing integration
- [ ] Load testing scenarios
- [ ] Chaos engineering tests
- [ ] Multi-region testing
- [ ] Upgrade/rollback testing

## License

This integration test suite is part of the Kruize Helm Chart project and follows the same license terms.