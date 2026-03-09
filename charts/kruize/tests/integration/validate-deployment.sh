#!/bin/bash
################################################################################
# Kruize Helm Chart Integration Test - Validation Script
#
# This script validates that all Kruize resources are deployed correctly
# and are functioning as expected.
#
# Usage: ./validate-deployment.sh [OPTIONS]
#
# Options:
#   -n, --namespace NAMESPACE    Namespace to validate (default: kruize-test)
#   -r, --release RELEASE        Helm release name (default: kruize-test)
#   -t, --timeout TIMEOUT        Timeout for checks (default: 5m)
#   -h, --help                   Show this help message
################################################################################

set -e

# Default values
NAMESPACE="kruize-test"
RELEASE_NAME="kruize-test"
TIMEOUT="5m"
TIMEOUT_SECONDS=300

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
    ((TESTS_TOTAL++))
}

log_test_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
    ((TESTS_TOTAL++))
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -r|--release)
            RELEASE_NAME="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            TIMEOUT_SECONDS=$(echo "$TIMEOUT" | sed 's/[^0-9]*//g')
            shift 2
            ;;
        -h|--help)
            grep '^#' "$0" | grep -v '#!/bin/bash' | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Test: Helm release exists
test_helm_release() {
    log_info "Test: Checking Helm release exists..."
    
    if helm status "${RELEASE_NAME}" -n "${NAMESPACE}" &> /dev/null; then
        log_test_pass "Helm release '${RELEASE_NAME}' exists"
        return 0
    else
        log_test_fail "Helm release '${RELEASE_NAME}' not found"
        return 1
    fi
}

# Test: Namespace exists
test_namespace() {
    log_info "Test: Checking namespace exists..."
    
    if kubectl get namespace "${NAMESPACE}" &> /dev/null; then
        log_test_pass "Namespace '${NAMESPACE}' exists"
        return 0
    else
        log_test_fail "Namespace '${NAMESPACE}' not found"
        return 1
    fi
}

# Test: Kruize deployment exists and is ready
test_kruize_deployment() {
    log_info "Test: Checking Kruize deployment..."
    
    local deployment_name="${RELEASE_NAME}-kruize"
    
    if ! kubectl get deployment "${deployment_name}" -n "${NAMESPACE}" &> /dev/null; then
        log_test_fail "Kruize deployment '${deployment_name}' not found"
        return 1
    fi
    
    local ready_replicas=$(kubectl get deployment "${deployment_name}" -n "${NAMESPACE}" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local desired_replicas=$(kubectl get deployment "${deployment_name}" -n "${NAMESPACE}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
    
    if [ "${ready_replicas}" -eq "${desired_replicas}" ]; then
        log_test_pass "Kruize deployment is ready (${ready_replicas}/${desired_replicas} replicas)"
        return 0
    else
        log_test_fail "Kruize deployment not ready (${ready_replicas}/${desired_replicas} replicas)"
        return 1
    fi
}

# Test: Kruize DB deployment exists and is ready
test_kruize_db_deployment() {
    log_info "Test: Checking Kruize DB deployment..."
    
    local deployment_name="${RELEASE_NAME}-kruize-db"
    
    if ! kubectl get deployment "${deployment_name}" -n "${NAMESPACE}" &> /dev/null; then
        log_test_fail "Kruize DB deployment '${deployment_name}' not found"
        return 1
    fi
    
    local ready_replicas=$(kubectl get deployment "${deployment_name}" -n "${NAMESPACE}" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local desired_replicas=$(kubectl get deployment "${deployment_name}" -n "${NAMESPACE}" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
    
    if [ "${ready_replicas}" -eq "${desired_replicas}" ]; then
        log_test_pass "Kruize DB deployment is ready (${ready_replicas}/${desired_replicas} replicas)"
        return 0
    else
        log_test_fail "Kruize DB deployment not ready (${ready_replicas}/${desired_replicas} replicas)"
        return 1
    fi
}

# Test: Kruize UI pod exists and is ready
test_kruize_ui_pod() {
    log_info "Test: Checking Kruize UI pod..."
    
    local pod_name="${RELEASE_NAME}-kruize-ui-nginx-pod"
    
    if ! kubectl get pod "${pod_name}" -n "${NAMESPACE}" &> /dev/null; then
        log_test_fail "Kruize UI pod '${pod_name}' not found"
        return 1
    fi
    
    local pod_status=$(kubectl get pod "${pod_name}" -n "${NAMESPACE}" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
    
    if [ "${pod_status}" = "Running" ]; then
        log_test_pass "Kruize UI pod is running"
        return 0
    else
        log_test_fail "Kruize UI pod status: ${pod_status}"
        return 1
    fi
}

# Test: Kruize service exists
test_kruize_service() {
    log_info "Test: Checking Kruize service..."
    
    local service_name="${RELEASE_NAME}-kruize"
    
    if kubectl get service "${service_name}" -n "${NAMESPACE}" &> /dev/null; then
        log_test_pass "Kruize service '${service_name}' exists"
        return 0
    else
        log_test_fail "Kruize service '${service_name}' not found"
        return 1
    fi
}

# Test: Kruize DB service exists
test_kruize_db_service() {
    log_info "Test: Checking Kruize DB service..."
    
    local service_name="${RELEASE_NAME}-kruize-db-service"
    
    if kubectl get service "${service_name}" -n "${NAMESPACE}" &> /dev/null; then
        log_test_pass "Kruize DB service '${service_name}' exists"
        return 0
    else
        log_test_fail "Kruize DB service '${service_name}' not found"
        return 1
    fi
}

# Test: Kruize UI service exists
test_kruize_ui_service() {
    log_info "Test: Checking Kruize UI service..."
    
    local service_name="${RELEASE_NAME}-kruize-ui-nginx-service"
    
    if kubectl get service "${service_name}" -n "${NAMESPACE}" &> /dev/null; then
        log_test_pass "Kruize UI service '${service_name}' exists"
        return 0
    else
        log_test_fail "Kruize UI service '${service_name}' not found"
        return 1
    fi
}

# Test: ConfigMaps exist
test_configmaps() {
    log_info "Test: Checking ConfigMaps..."
    
    local kruize_cm="${RELEASE_NAME}-kruize-config"
    local nginx_cm="${RELEASE_NAME}-nginx-config"
    
    local cm_count=0
    
    if kubectl get configmap "${kruize_cm}" -n "${NAMESPACE}" &> /dev/null; then
        ((cm_count++))
    fi
    
    if kubectl get configmap "${nginx_cm}" -n "${NAMESPACE}" &> /dev/null; then
        ((cm_count++))
    fi
    
    if [ ${cm_count} -eq 2 ]; then
        log_test_pass "All ConfigMaps exist (${cm_count}/2)"
        return 0
    else
        log_test_fail "Some ConfigMaps missing (${cm_count}/2)"
        return 1
    fi
}

# Test: PVC exists and is bound
test_pvc() {
    log_info "Test: Checking PVC..."
    
    local pvc_name="${RELEASE_NAME}-kruize-db-pvc"
    
    if ! kubectl get pvc "${pvc_name}" -n "${NAMESPACE}" &> /dev/null; then
        log_test_fail "PVC '${pvc_name}' not found"
        return 1
    fi
    
    local pvc_status=$(kubectl get pvc "${pvc_name}" -n "${NAMESPACE}" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
    
    if [ "${pvc_status}" = "Bound" ]; then
        log_test_pass "PVC is bound"
        return 0
    else
        log_test_fail "PVC status: ${pvc_status}"
        return 1
    fi
}

# Test: Pods are not restarting excessively
test_pod_restarts() {
    log_info "Test: Checking pod restart counts..."
    
    local max_restarts=3
    local pods=$(kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    
    if [ -z "${pods}" ]; then
        log_test_fail "No pods found"
        return 1
    fi
    
    local high_restart_pods=0
    for pod in ${pods}; do
        local restarts=$(kubectl get pod "${pod}" -n "${NAMESPACE}" -o jsonpath='{.status.containerStatuses[*].restartCount}' 2>/dev/null | awk '{sum=0; for(i=1;i<=NF;i++) sum+=$i; print sum}')
        if [ "${restarts}" -gt "${max_restarts}" ]; then
            log_warning "Pod '${pod}' has ${restarts} restarts"
            ((high_restart_pods++))
        fi
    done
    
    if [ ${high_restart_pods} -eq 0 ]; then
        log_test_pass "No pods with excessive restarts"
        return 0
    else
        log_test_fail "${high_restart_pods} pod(s) with excessive restarts"
        return 1
    fi
}

# Test: Kruize API health check
test_kruize_api_health() {
    log_info "Test: Checking Kruize API health..."
    
    local service_name="${RELEASE_NAME}-kruize"
    local pod_name=$(kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/name=kruize,app.kubernetes.io/instance=${RELEASE_NAME}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "${pod_name}" ]; then
        log_test_fail "Kruize pod not found"
        return 1
    fi
    
    # Wait for pod to be ready
    if ! kubectl wait --for=condition=ready pod "${pod_name}" -n "${NAMESPACE}" --timeout=60s &> /dev/null; then
        log_test_fail "Kruize pod not ready"
        return 1
    fi
    
    # Try to access health endpoint
    local health_check=$(kubectl exec "${pod_name}" -n "${NAMESPACE}" -- curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null || echo "000")
    
    if [ "${health_check}" = "200" ]; then
        log_test_pass "Kruize API health check passed"
        return 0
    else
        log_test_fail "Kruize API health check failed (HTTP ${health_check})"
        return 1
    fi
}

# Test: Database connectivity
test_database_connectivity() {
    log_info "Test: Checking database connectivity..."
    
    local db_pod=$(kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/name=kruize-db,app.kubernetes.io/instance=${RELEASE_NAME}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "${db_pod}" ]; then
        log_test_fail "Database pod not found"
        return 1
    fi
    
    # Wait for pod to be ready
    if ! kubectl wait --for=condition=ready pod "${db_pod}" -n "${NAMESPACE}" --timeout=60s &> /dev/null; then
        log_test_fail "Database pod not ready"
        return 1
    fi
    
    # Check if PostgreSQL is accepting connections
    local db_check=$(kubectl exec "${db_pod}" -n "${NAMESPACE}" -- pg_isready -U admin 2>/dev/null || echo "failed")
    
    if echo "${db_check}" | grep -q "accepting connections"; then
        log_test_pass "Database is accepting connections"
        return 0
    else
        log_test_fail "Database connectivity check failed"
        return 1
    fi
}

# Print summary
print_summary() {
    echo ""
    echo "=============================================="
    log_info "Validation Summary"
    echo "=============================================="
    echo "Total Tests: ${TESTS_TOTAL}"
    echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
    echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
    echo "=============================================="
    
    if [ ${TESTS_FAILED} -eq 0 ]; then
        log_success "All validation tests passed!"
        return 0
    else
        log_error "Some validation tests failed!"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting Kruize Deployment Validation"
    log_info "Namespace: ${NAMESPACE}"
    log_info "Release: ${RELEASE_NAME}"
    log_info "=============================================="
    echo ""
    
    # Run all tests
    test_namespace || true
    test_helm_release || true
    test_kruize_deployment || true
    test_kruize_db_deployment || true
    test_kruize_ui_pod || true
    test_kruize_service || true
    test_kruize_db_service || true
    test_kruize_ui_service || true
    test_configmaps || true
    test_pvc || true
    test_pod_restarts || true
    test_database_connectivity || true
    test_kruize_api_health || true
    
    # Print summary and exit with appropriate code
    print_summary
}

# Run main function
main
exit $?

# Made with Bob
