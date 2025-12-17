#!/bin/bash

# GitFlow Testing Script
# Demonstrates complete GitFlow workflow with deployments

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Test GitFlow workflow
test_gitflow_workflow() {
    echo "🌊 GitFlow Workflow Testing"
    echo "=========================="
    echo ""
    
    # Step 1: Create feature branch
    print_step "Step 1: Creating feature branch"
    FEATURE_BRANCH="feature/test-deployment-$(date +%s)"
    git checkout develop
    git pull origin develop
    git checkout -b $FEATURE_BRANCH
    
    # Make a small change
    echo "# Test deployment $(date)" >> README.md
    git add README.md
    git commit -m "test: GitFlow deployment workflow"
    git push origin $FEATURE_BRANCH
    
    print_success "Feature branch created: $FEATURE_BRANCH"
    
    # Step 2: Merge to develop (triggers dev deployment)
    print_step "Step 2: Merging to develop (triggers dev deployment)"
    git checkout develop
    git merge $FEATURE_BRANCH --no-ff -m "feat: merge test deployment feature"
    git push origin develop
    
    print_success "Merged to develop - this triggers dev environment deployment"
    print_info "Check GitHub Actions: https://github.com/abdihakim-said/robot-shop-azure-platform/actions"
    
    # Step 3: Create release branch (triggers staging deployment)
    print_step "Step 3: Creating release branch (triggers staging deployment)"
    RELEASE_BRANCH="release/v$(date +%Y.%m.%d-%H%M%S)"
    git checkout -b $RELEASE_BRANCH
    git push origin $RELEASE_BRANCH
    
    print_success "Release branch created: $RELEASE_BRANCH"
    print_info "This triggers staging environment deployment"
    
    # Step 4: Merge to main (triggers production deployment)
    print_step "Step 4: Merging to main (triggers production deployment)"
    echo "This step requires manual approval in production"
    echo "Would you like to merge to main? (y/N):"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        git checkout main
        git pull origin main
        git merge $RELEASE_BRANCH --no-ff -m "release: deploy version $(date +%Y.%m.%d)"
        git push origin main
        
        print_success "Merged to main - this triggers production deployment (with manual approval)"
        print_info "Production deployment requires manual approval in GitHub Actions"
    else
        print_info "Skipping production deployment"
    fi
    
    # Cleanup
    print_step "Cleaning up feature branch"
    git branch -d $FEATURE_BRANCH
    git push origin --delete $FEATURE_BRANCH
    
    echo ""
    print_success "GitFlow workflow test completed!"
    echo ""
    echo "📊 Summary:"
    echo "- Feature branch: Created and merged"
    echo "- Develop: ✅ Auto-deploys to dev environment"
    echo "- Release: ✅ Auto-deploys to staging environment"
    echo "- Main: ⏸️ Manual approval for production deployment"
}

# Show current branch status
show_branch_status() {
    echo "🌳 Current Branch Status"
    echo "======================="
    echo ""
    
    print_info "Local branches:"
    git branch
    
    echo ""
    print_info "Remote branches:"
    git branch -r
    
    echo ""
    print_info "Recent commits:"
    git log --oneline -5
    
    echo ""
    print_info "GitFlow mapping:"
    echo "   develop     → dev environment"
    echo "   release/*   → staging environment"
    echo "   main        → production environment"
}

# Monitor deployments
monitor_deployments() {
    echo "📊 Monitoring Deployments"
    echo "========================"
    echo ""
    
    print_info "GitHub Actions workflows:"
    if command -v gh &> /dev/null; then
        gh run list --limit 5
    else
        echo "Install GitHub CLI (gh) to monitor workflows"
        echo "Visit: https://github.com/abdihakim-said/robot-shop-azure-platform/actions"
    fi
    
    echo ""
    print_info "To monitor specific environment:"
    echo "kubectl get pods -n robot-shop  # Check application pods"
    echo "kubectl get pods -n monitoring  # Check monitoring stack"
    echo "kubectl get ingress -n robot-shop  # Check ingress status"
}

# Main menu
main() {
    echo "🤖 Robot Shop - GitFlow Testing"
    echo "==============================="
    echo ""
    echo "Options:"
    echo "1. Test complete GitFlow workflow"
    echo "2. Show branch status"
    echo "3. Monitor deployments"
    echo "4. Exit"
    echo ""
    
    read -p "Select option (1-4): " choice
    
    case $choice in
        1)
            test_gitflow_workflow
            ;;
        2)
            show_branch_status
            ;;
        3)
            monitor_deployments
            ;;
        4)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option"
            exit 1
            ;;
    esac
}

main "$@"
