#!/bin/bash

# Unosquare Interview Demo Script
# Showcases Azure Cloud Engineering capabilities

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}🚀 $1${NC}"
    echo "=============================================="
}

print_demo() {
    echo -e "${GREEN}📋 $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Demo script for Unosquare interview
unosquare_demo() {
    print_header "UNOSQUARE AZURE CLOUD ENGINEERING DEMO"
    
    echo "This demo showcases enterprise Azure capabilities for AI-driven, compliant projects"
    echo ""
    
    # 1. Architecture Overview
    print_demo "1. AZURE LANDING ZONE ARCHITECTURE"
    echo "Multi-environment setup with compliance controls:"
    echo "  • Development: Cost-optimized, rapid iteration"
    echo "  • Staging: Production-like security testing"
    echo "  • Production: Full compliance, HA configuration"
    echo ""
    
    if az account show &> /dev/null; then
        echo "Current Azure subscription:"
        az account show --query "{name: name, state: state}" --output table
        echo ""
        
        echo "Resource groups (landing zones):"
        az group list --query "[].{Name:name, Location:location, Status:properties.provisioningState}" --output table
    else
        print_info "Azure CLI not logged in - would show resource groups here"
    fi
    
    echo ""
    
    # 2. Compliance & Security
    print_demo "2. COMPLIANCE & SECURITY IMPLEMENTATION"
    echo "DevSecOps pipeline with 3-layer security scanning:"
    echo "  • TruffleHog: Secret detection (API keys, passwords)"
    echo "  • Trivy: Vulnerability scanning (CVE detection)"
    echo "  • Semgrep: SAST code analysis (OWASP Top 10)"
    echo ""
    echo "Security gates block CRITICAL vulnerabilities automatically"
    echo "Achievement: Reduced 16 CRITICAL CVEs to zero"
    echo ""
    
    # 3. GitOps Workflow
    print_demo "3. DEVELOPER SELF-SERVICE (GitOps)"
    echo "Automated deployment workflow:"
    echo "  Feature Branch → Develop → Release → Production"
    echo "       ↓             ↓         ↓         ↓"
    echo "   PR Tests    Auto-Deploy  Auto-Stage Manual-Prod"
    echo ""
    echo "Deployment speed: 3-5 minutes from code to running service"
    echo ""
    
    # 4. Monitoring & SLOs
    print_demo "4. OBSERVABILITY & SLO MONITORING"
    echo "Enterprise monitoring stack:"
    echo "  • Infrastructure: Azure Monitor + Application Insights"
    echo "  • Applications: Prometheus + Grafana"
    echo "  • SLOs: 99.9% availability, <0.1% error rate, <200ms latency"
    echo ""
    
    if kubectl cluster-info &> /dev/null; then
        echo "Current cluster status:"
        kubectl get nodes --no-headers 2>/dev/null | wc -l | xargs echo "  Nodes:"
        kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l | xargs echo "  Pods:"
    else
        print_info "Kubernetes cluster not accessible - would show live metrics here"
    fi
    
    echo ""
    
    # 5. Cost Optimization
    print_demo "5. COST OPTIMIZATION & RESOURCE MANAGEMENT"
    echo "Achieved results:"
    echo "  • 37.5% cost savings through resource optimization"
    echo "  • Auto-scaling: Horizontal and vertical pod autoscaling"
    echo "  • Resource quotas: Preventing resource sprawl"
    echo "  • Right-sizing: CPU/memory utilization monitoring"
    echo ""
    
    # 6. AI/Manufacturing Relevance
    print_demo "6. AI/MANUFACTURING WORKFLOW READINESS"
    echo "Architecture supports AI-driven parts catalogue:"
    echo "  • Scalable container orchestration for ML workloads"
    echo "  • Blob storage for 3D models and CAD files"
    echo "  • API gateways for 3D printer integration"
    echo "  • Real-time data pipelines for manufacturing workflows"
    echo ""
    
    # 7. Compliance Frameworks
    print_demo "7. COMPLIANCE FRAMEWORK ALIGNMENT"
    echo "ISO 27001 controls implemented:"
    echo "  • A.9 Access control: RBAC and service principals"
    echo "  • A.10 Cryptography: Encryption at rest and in transit"
    echo "  • A.12 Operations security: Monitoring and incident response"
    echo "  • A.13 Communications security: Network segmentation"
    echo "  • A.14 System acquisition: Secure development lifecycle"
    echo ""
    
    # 8. Technical Highlights
    print_demo "8. TECHNICAL IMPLEMENTATION HIGHLIGHTS"
    echo "Infrastructure as Code (Terraform):"
    echo "  • Modular design: AKS, networking, storage, monitoring"
    echo "  • Multi-environment: Dev, staging, production"
    echo "  • Security by default: Policies and compliance built-in"
    echo ""
    echo "CI/CD Pipeline:"
    echo "  • Security scanning → Infrastructure → Build → Deploy"
    echo "  • Environment-specific configurations"
    echo "  • Automated rollback capabilities"
    echo ""
    
    print_header "DEMO COMPLETE - READY FOR UNOSQUARE INTERVIEW"
    
    echo "Key talking points:"
    echo "✅ Greenfield Azure platform built from scratch"
    echo "✅ Compliance through automation (security by default)"
    echo "✅ Developer self-service with safety guardrails"
    echo "✅ Cost optimization while maintaining performance"
    echo "✅ Ready for AI/manufacturing workloads"
    echo ""
    echo "Questions to ask Unosquare:"
    echo "• What specific compliance frameworks for the AI catalogue?"
    echo "• How will 3D printing workflows integrate with the platform?"
    echo "• Preferred approach to multi-cloud architecture?"
    echo "• Balance between developer velocity and compliance?"
    echo "• AI/ML workload patterns to consider?"
    echo ""
    echo "🎯 This project demonstrates exactly what Unosquare needs!"
}

# Show project metrics
show_metrics() {
    print_header "PROJECT METRICS & ACHIEVEMENTS"
    
    echo "📊 Scale & Complexity:"
    echo "  • 12 microservices across 5 programming languages"
    echo "  • 3 environments with compliance controls"
    echo "  • 80+ commits with GitFlow workflow"
    echo ""
    
    echo "🔒 Security & Compliance:"
    echo "  • Zero CRITICAL vulnerabilities (resolved 16 CVEs)"
    echo "  • 3-layer security scanning in CI/CD"
    echo "  • SARIF reports to GitHub Security Dashboard"
    echo "  • SBOM generation for supply chain security"
    echo ""
    
    echo "📈 Performance & Reliability:"
    echo "  • 99.9% availability SLO target"
    echo "  • <200ms latency (95th percentile)"
    echo "  • Auto-scaling infrastructure"
    echo "  • Multi-AZ deployment ready"
    echo ""
    
    echo "💰 Cost Optimization:"
    echo "  • 37.5% cost savings achieved"
    echo "  • Resource quotas and limits implemented"
    echo "  • Right-sizing recommendations"
    echo "  • Environment-specific resource allocation"
    echo ""
    
    echo "🚀 Developer Experience:"
    echo "  • 3-5 minute deployments"
    echo "  • Self-service GitOps workflow"
    echo "  • Environment parity (dev/staging/prod)"
    echo "  • Automated testing and validation"
}

# Main menu
main() {
    echo "🤖 Robot Shop - Unosquare Interview Preparation"
    echo "=============================================="
    echo ""
    echo "Options:"
    echo "1. 🎤 Run complete demo presentation"
    echo "2. 📊 Show project metrics & achievements"
    echo "3. 📋 View Unosquare showcase document"
    echo "4. 🔍 Check current infrastructure status"
    echo "5. ❌ Exit"
    echo ""
    
    read -p "Select option (1-5): " choice
    
    case $choice in
        1)
            unosquare_demo
            ;;
        2)
            show_metrics
            ;;
        3)
            if [ -f "UNOSQUARE-SHOWCASE.md" ]; then
                echo "Opening Unosquare showcase document..."
                cat UNOSQUARE-SHOWCASE.md | head -50
                echo ""
                echo "📄 Full document: UNOSQUARE-SHOWCASE.md"
            else
                echo "Showcase document not found"
            fi
            ;;
        4)
            echo "🔍 Current Infrastructure Status:"
            if az account show &> /dev/null; then
                az group list --output table
            else
                echo "Azure CLI not logged in"
            fi
            ;;
        5)
            echo "Good luck with your Unosquare interview! 🚀"
            exit 0
            ;;
        *)
            echo "Invalid option"
            exit 1
            ;;
    esac
}

main "$@"
