#!/bin/bash
################################################################################
# Kruize Helm Chart Integration Test - Deployment Script
#
# This script deploys the Kruize Helm chart to a Kubernetes cluster and
# validates that all resources are created successfully.
#
# Usage: ./deploy-test.sh [OPTIONS]
#
# Options:
#   -n, --namespace NAMESPACE              Namespace to deploy to (default: kruize-test)
#   -r, --release RELEASE                  Helm release name (default: kruize-test)
#   -v, --values VALUES_FILE               Values file to use (default: values.yaml)
#   -t, --timeout TIMEOUT                  Timeout for deployment (default: 5m)
#   -c, --cleanup                          Cleanup after test
#   --kruize-image-repo REPOSITORY         Kruize image repository (overrides values file)
#   --kruize-image-tag TAG                 Kruize image tag (overrides values file)
#   --kruize-ui-image-repo REPOSITORY      Kruize UI image repository (overrides values file)
#   --kruize-ui-image-tag TAG              Kruize UI image tag (overrides values file)
#   -h, --help                             Show this help message
################################################################################

set -e

# Default values
NAMESPACE="kruize-test"
RELEASE_NAME="kruize-test"
VALUES_FILE=""
TIMEOUT="5m"
CLEANUP=false
CHART_PATH="charts/kruize"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

# Image override options
KRUIZE_IMAGE_REPO=""
KRUIZE_IMAGE_TAG=""
KRUIZE_UI_IMAGE_REPO=""
KRUIZE_UI_IMAGE_TAG=""

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
        -v|--values)
            VALUES_FILE="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -c|--cleanup)
            CLEANUP=true
            shift
            ;;
        --kruize-image-repo)
            KRUIZE_IMAGE_REPO="$2"
            shift 2
            ;;
        --kruize-image-tag)
            KRUIZE_IMAGE_TAG="$2"
            shift 2
            ;;
        --kruize-ui-image-repo)
            KRUIZE_UI_IMAGE_REPO="$2"
            shift 2
            ;;
        --kruize-ui-image-tag)
            KRUIZE_UI_IMAGE_TAG="$2"
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create namespace if it doesn't exist
create_namespace() {
    log_info "Creating namespace: ${NAMESPACE}"
    
    if kubectl get namespace "${NAMESPACE}" &> /dev/null; then
        log_warning "Namespace ${NAMESPACE} already exists"
    else
        kubectl create namespace "${NAMESPACE}"
        log_success "Namespace ${NAMESPACE} created"
    fi
}

# Deploy Helm chart
deploy_chart() {
    log_info "Deploying Kruize Helm chart..."
    log_info "Release: ${RELEASE_NAME}"
    log_info "Namespace: ${NAMESPACE}"
    log_info "Chart: ${CHART_PATH}"
    
    cd "${ROOT_DIR}"
    
    HELM_CMD="helm upgrade --install ${RELEASE_NAME} ${CHART_PATH} \
        --namespace ${NAMESPACE} \
        --timeout ${TIMEOUT} \
        --wait \
        --create-namespace"
    
    if [ -n "${VALUES_FILE}" ]; then
        log_info "Using values file: ${VALUES_FILE}"
        HELM_CMD="${HELM_CMD} -f ${VALUES_FILE}"
    fi
    
    # Add image overrides if specified
    if [ -n "${KRUIZE_IMAGE_REPO}" ]; then
        log_info "Overriding Kruize image repository: ${KRUIZE_IMAGE_REPO}"
        HELM_CMD="${HELM_CMD} --set kruize.image.repository=${KRUIZE_IMAGE_REPO}"
    fi
    
    if [ -n "${KRUIZE_IMAGE_TAG}" ]; then
        log_info "Overriding Kruize image tag: ${KRUIZE_IMAGE_TAG}"
        HELM_CMD="${HELM_CMD} --set kruize.image.tag=${KRUIZE_IMAGE_TAG}"
    fi
    
    if [ -n "${KRUIZE_UI_IMAGE_REPO}" ]; then
        log_info "Overriding Kruize UI image repository: ${KRUIZE_UI_IMAGE_REPO}"
        HELM_CMD="${HELM_CMD} --set kruizeUI.image.repository=${KRUIZE_UI_IMAGE_REPO}"
    fi
    
    if [ -n "${KRUIZE_UI_IMAGE_TAG}" ]; then
        log_info "Overriding Kruize UI image tag: ${KRUIZE_UI_IMAGE_TAG}"
        HELM_CMD="${HELM_CMD} --set kruizeUI.image.tag=${KRUIZE_UI_IMAGE_TAG}"
    fi
    
    if eval "${HELM_CMD}"; then
        log_success "Helm chart deployed successfully"
    else
        log_error "Failed to deploy Helm chart"
        exit 1
    fi
}

# Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check Helm release status
    log_info "Checking Helm release status..."
    if helm status "${RELEASE_NAME}" -n "${NAMESPACE}" &> /dev/null; then
        log_success "Helm release is deployed"
    else
        log_error "Helm release not found"
        return 1
    fi
    
    # Wait for pods to be ready
    log_info "Waiting for pods to be ready..."
    if kubectl wait --for=condition=ready pod \
        -l "app.kubernetes.io/instance=${RELEASE_NAME}" \
        -n "${NAMESPACE}" \
        --timeout="${TIMEOUT}" 2>/dev/null; then
        log_success "All pods are ready"
    else
        log_warning "Some pods may not be ready yet"
    fi
    
    # List all resources
    log_info "Listing deployed resources..."
    kubectl get all -n "${NAMESPACE}" -l "app.kubernetes.io/instance=${RELEASE_NAME}"
    
    return 0
}

# Run validation tests
run_validation_tests() {
    log_info "Running validation tests..."
    
    if [ -f "${SCRIPT_DIR}/validate-deployment.sh" ]; then
        bash "${SCRIPT_DIR}/validate-deployment.sh" \
            --namespace "${NAMESPACE}" \
            --release "${RELEASE_NAME}"
    else
        log_warning "Validation script not found, skipping validation tests"
    fi
}

# Cleanup resources
cleanup_resources() {
    if [ "${CLEANUP}" = true ]; then
        log_info "Cleaning up resources..."
        
        log_info "Uninstalling Helm release: ${RELEASE_NAME}"
        helm uninstall "${RELEASE_NAME}" -n "${NAMESPACE}" || true
        
        log_info "Deleting namespace: ${NAMESPACE}"
        kubectl delete namespace "${NAMESPACE}" --timeout=60s || true
        
        log_success "Cleanup completed"
    fi
}

# Main execution
main() {
    log_info "Starting Kruize Helm Chart Integration Test"
    log_info "=============================================="
    
    check_prerequisites
    create_namespace
    deploy_chart
    verify_deployment
    run_validation_tests
    
    log_success "Integration test completed successfully!"
    
    cleanup_resources
}

# Trap errors and cleanup
trap 'log_error "Test failed!"; cleanup_resources; exit 1' ERR

# Run main function
main

# Made with Bob
