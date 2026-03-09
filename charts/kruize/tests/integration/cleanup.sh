#!/bin/bash
################################################################################
# Kruize Helm Chart Integration Test - Cleanup Script
#
# This script cleans up all resources created during integration testing.
#
# Usage: ./cleanup.sh [OPTIONS]
#
# Options:
#   -n, --namespace NAMESPACE    Namespace to clean up (default: kruize-test)
#   -r, --release RELEASE        Helm release name (default: kruize-test)
#   -a, --all                    Delete namespace after cleanup
#   -f, --force                  Force cleanup without confirmation
#   -h, --help                   Show this help message
################################################################################

set -e

# Default values
NAMESPACE="kruize-test"
RELEASE_NAME="kruize-test"
DELETE_NAMESPACE=false
FORCE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
        -a|--all)
            DELETE_NAMESPACE=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
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

# Confirm cleanup
confirm_cleanup() {
    if [ "${FORCE}" = true ]; then
        return 0
    fi
    
    echo ""
    log_warning "This will clean up the following resources:"
    echo "  - Helm release: ${RELEASE_NAME}"
    echo "  - Namespace: ${NAMESPACE}"
    if [ "${DELETE_NAMESPACE}" = true ]; then
        echo "  - The namespace will be DELETED"
    fi
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Cleanup cancelled"
        exit 0
    fi
}

# Check if namespace exists
check_namespace() {
    if ! kubectl get namespace "${NAMESPACE}" &> /dev/null; then
        log_warning "Namespace '${NAMESPACE}' does not exist"
        return 1
    fi
    return 0
}

# Check if Helm release exists
check_helm_release() {
    if ! helm status "${RELEASE_NAME}" -n "${NAMESPACE}" &> /dev/null; then
        log_warning "Helm release '${RELEASE_NAME}' not found in namespace '${NAMESPACE}'"
        return 1
    fi
    return 0
}

# Uninstall Helm release
uninstall_helm_release() {
    log_info "Uninstalling Helm release: ${RELEASE_NAME}"
    
    if check_helm_release; then
        if helm uninstall "${RELEASE_NAME}" -n "${NAMESPACE}" --wait --timeout=5m; then
            log_success "Helm release uninstalled successfully"
        else
            log_error "Failed to uninstall Helm release"
            return 1
        fi
    else
        log_info "Helm release not found, skipping uninstall"
    fi
}

# Delete PVCs
delete_pvcs() {
    log_info "Deleting PVCs in namespace: ${NAMESPACE}"
    
    local pvcs=$(kubectl get pvc -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    
    if [ -z "${pvcs}" ]; then
        log_info "No PVCs found"
        return 0
    fi
    
    for pvc in ${pvcs}; do
        log_info "Deleting PVC: ${pvc}"
        kubectl delete pvc "${pvc}" -n "${NAMESPACE}" --timeout=60s || log_warning "Failed to delete PVC: ${pvc}"
    done
    
    log_success "PVCs deleted"
}

# Delete PVs (if they exist and are not bound)
delete_pvs() {
    log_info "Checking for orphaned PVs..."
    
    local pvs=$(kubectl get pv -o jsonpath='{.items[?(@.spec.claimRef.namespace=="'${NAMESPACE}'")].metadata.name}' 2>/dev/null)
    
    if [ -z "${pvs}" ]; then
        log_info "No PVs found for namespace"
        return 0
    fi
    
    for pv in ${pvs}; do
        local pv_status=$(kubectl get pv "${pv}" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
        if [ "${pv_status}" = "Released" ] || [ "${pv_status}" = "Failed" ]; then
            log_info "Deleting PV: ${pv} (status: ${pv_status})"
            kubectl delete pv "${pv}" --timeout=60s || log_warning "Failed to delete PV: ${pv}"
        else
            log_info "Skipping PV: ${pv} (status: ${pv_status})"
        fi
    done
}

# Delete remaining resources
delete_remaining_resources() {
    log_info "Checking for remaining resources..."
    
    local resources=$(kubectl get all -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" -o name 2>/dev/null)
    
    if [ -z "${resources}" ]; then
        log_info "No remaining resources found"
        return 0
    fi
    
    log_warning "Found remaining resources:"
    echo "${resources}"
    
    log_info "Deleting remaining resources..."
    kubectl delete all -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" --timeout=60s || log_warning "Some resources may not have been deleted"
}

# Delete ConfigMaps and Secrets
delete_config_resources() {
    log_info "Deleting ConfigMaps and Secrets..."
    
    kubectl delete configmap -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" --timeout=60s 2>/dev/null || true
    kubectl delete secret -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" --timeout=60s 2>/dev/null || true
    
    log_success "ConfigMaps and Secrets deleted"
}

# Delete namespace
delete_namespace() {
    if [ "${DELETE_NAMESPACE}" = true ]; then
        log_info "Deleting namespace: ${NAMESPACE}"
        
        if kubectl delete namespace "${NAMESPACE}" --timeout=120s; then
            log_success "Namespace deleted successfully"
        else
            log_error "Failed to delete namespace"
            log_info "You may need to manually delete the namespace"
            return 1
        fi
    else
        log_info "Namespace will not be deleted (use --all flag to delete)"
    fi
}

# Wait for resources to be deleted
wait_for_cleanup() {
    log_info "Waiting for resources to be fully cleaned up..."
    
    local max_wait=60
    local wait_time=0
    
    while [ ${wait_time} -lt ${max_wait} ]; do
        local pods=$(kubectl get pods -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}" -o name 2>/dev/null | wc -l)
        
        if [ ${pods} -eq 0 ]; then
            log_success "All pods have been terminated"
            return 0
        fi
        
        log_info "Waiting for ${pods} pod(s) to terminate... (${wait_time}s/${max_wait}s)"
        sleep 5
        wait_time=$((wait_time + 5))
    done
    
    log_warning "Timeout waiting for all pods to terminate"
    return 1
}

# Print cleanup summary
print_summary() {
    echo ""
    echo "=============================================="
    log_info "Cleanup Summary"
    echo "=============================================="
    echo "Release: ${RELEASE_NAME}"
    echo "Namespace: ${NAMESPACE}"
    if [ "${DELETE_NAMESPACE}" = true ]; then
        echo "Namespace deleted: Yes"
    else
        echo "Namespace deleted: No"
    fi
    echo "=============================================="
}

# Main execution
main() {
    log_info "Starting Kruize Integration Test Cleanup"
    log_info "=============================================="
    
    confirm_cleanup
    
    if ! check_namespace; then
        log_info "Nothing to clean up"
        exit 0
    fi
    
    uninstall_helm_release
    delete_remaining_resources
    delete_config_resources
    delete_pvcs
    delete_pvs
    wait_for_cleanup
    delete_namespace
    
    print_summary
    log_success "Cleanup completed successfully!"
}

# Trap errors
trap 'log_error "Cleanup failed!"; exit 1' ERR

# Run main function
main

# Made with Bob
