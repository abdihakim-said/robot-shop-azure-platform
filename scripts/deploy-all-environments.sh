#!/bin/bash

# Complete Multi-Environment Deployment Script
# Follows GitFlow branching strategy and tests all environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_section() {
    echo -e "${BLUE}🚀 $1${NC}"
    echo "=========================================="
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_section "CHECKING PREREQUISITES"
    
    # Check required tools
    for tool in az kubectl helm terraform git; do
        if command -v $tool &> /dev/null; then
            print_success "$tool is installed"
        else
            print_error "$tool is not installed"
            exit 1
        fi
    done
    
    # Check Azure login
    if az account show &> /dev/null; then
        print_success "Azure CLI logged in"
        echo "   Subscription: $(az account show --query name -o tsv)"
    else
        print_error "Please login to Azure: az login"
        exit 1
    fi
    
    # Check Git repository
    if git status &> /dev/null; then
        print_success "Git repository detected"
        echo "   Current branch: $(git branch --show-current)"
    else
        print_error "Not in a Git repository"
        exit 1
    fi
}

# Deploy infrastructure for environment
deploy_infrastructure() {
    local env=$1
    print_section "DEPLOYING INFRASTRUCTURE - $env"
    
    cd terraform/environments/$env
    
    # Initialize Terraform
    print_warning "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_warning "Planning infrastructure..."
    terraform plan -out=tfplan
    
    # Apply with confirmation
    echo -e "${YELLOW}Deploy infrastructure for $env environment? (y/N):${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        terraform apply tfplan
        print_success "Infrastructure deployed for $env"
    else
        print_warning "Skipping infrastructure deployment for $env"
    fi
    
    cd ../../..
}

# Deploy application using Helm
deploy_application() {
    local env=$1
    print_section "DEPLOYING APPLICATION - $env"
    
    # Get AKS credentials
    print_warning "Getting AKS credentials..."
    az aks get-credentials \
        --resource-group robot-shop-$env-rg \
        --name robot-shop-$env-aks \
        --overwrite-existing
    
    # Deploy monitoring first
    print_warning "Deploying monitoring stack..."
    ./scripts/deploy-monitoring.sh $env
    
    # Deploy application
    print_warning "Deploying Robot Shop application..."
    helm upgrade --install robot-shop ./helm-charts/robot-shop \
        --namespace robot-shop \
        --create-namespace \
        --values ./helm-charts/robot-shop/values-$env.yaml \
        --wait \
        --timeout 10m
    
    # Deploy SLO alerts
    print_warning "Deploying SLO alerts..."
    kubectl apply -f monitoring/slo-alerts.yaml
    
    # Deploy resource quotas
    print_warning "Deploying resource quotas..."
    kubectl apply -f k8s/resource-quotas.yaml
    
    print_success "Application deployed for $env"
}

# Test deployment
test_deployment() {
    local env=$1
    print_section "TESTING DEPLOYMENT - $env"
    
    # Check pods
    print_warning "Checking pod status..."
    kubectl get pods -n robot-shop
    
    # Check services
    print_warning "Checking services..."
    kubectl get svc -n robot-shop
    
    # Check ingress
    print_warning "Checking ingress..."
    kubectl get ingress -n robot-shop
    
    # Test application health
    print_warning "Testing application health..."
    if kubectl get pods -n robot-shop | grep -q "Running"; then
        print_success "All pods are running"
    else
        print_error "Some pods are not running"
    fi
    
    # Check monitoring
    print_warning "Checking monitoring..."
    kubectl get pods -n monitoring
    
    print_success "Deployment test completed for $env"
}

# GitFlow workflow demonstration
demonstrate_gitflow() {
    print_section "GITFLOW WORKFLOW DEMONSTRATION"
    
    # Show current branch structure
    print_warning "Current branch structure:"
    git branch -a
    
    echo ""
    print_warning "GitFlow Environment Mapping:"
    echo "   develop     → dev environment (auto-deploy)"
    echo "   release/*   → staging environment (auto-deploy)"
    echo "   main        → production environment (manual)"
    
    echo ""
    print_warning "To test GitFlow:"
    echo "1. Make changes on feature branch"
    echo "2. Merge to develop → triggers dev deployment"
    echo "3. Create release branch → triggers staging deployment"
    echo "4. Merge to main → triggers production deployment (manual approval)"
}

# Main deployment function
main() {
    echo "🤖 Robot Shop - Multi-Environment Deployment"
    echo "============================================="
    echo ""
    
    check_prerequisites
    
    echo ""
    echo "Available environments:"
    echo "1. dev       - Development environment"
    echo "2. staging   - Staging environment"
    echo "3. prod      - Production environment"
    echo "4. all       - Deploy all environments"
    echo "5. gitflow   - Demonstrate GitFlow workflow"
    echo ""
    
    read -p "Select deployment option (1-5): " choice
    
    case $choice in
        1)
            deploy_infrastructure "dev"
            deploy_application "dev"
            test_deployment "dev"
            ;;
        2)
            deploy_infrastructure "staging"
            deploy_application "staging"
            test_deployment "staging"
            ;;
        3)
            deploy_infrastructure "prod"
            deploy_application "prod"
            test_deployment "prod"
            ;;
        4)
            for env in dev staging prod; do
                deploy_infrastructure "$env"
                deploy_application "$env"
                test_deployment "$env"
                echo ""
            done
            ;;
        5)
            demonstrate_gitflow
            ;;
        *)
            print_error "Invalid option selected"
            exit 1
            ;;
    esac
    
    print_success "Deployment completed successfully!"
    echo ""
    echo "🎯 Next Steps:"
    echo "- Access applications via ingress"
    echo "- Monitor via Grafana dashboards"
    echo "- Test GitFlow with feature branches"
    echo "- Review SLO alerts and metrics"
}

# Run main function
main "$@"
