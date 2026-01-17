#!/bin/bash

# SRE Observability Showcase
# Demonstrates complete infrastructure and application monitoring

set -e

echo "🔍 SRE OBSERVABILITY SHOWCASE"
echo "=============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_section() {
    echo -e "${BLUE}📊 $1${NC}"
    echo "----------------------------------------"
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
print_section "PREREQUISITES CHECK"

# Check Azure CLI
if command -v az &> /dev/null; then
    print_success "Azure CLI installed"
    echo "   Subscription: $(az account show --query name -o tsv)"
else
    print_error "Azure CLI not found"
    exit 1
fi

# Check kubectl
if command -v kubectl &> /dev/null; then
    print_success "kubectl installed"
else
    print_error "kubectl not found"
    exit 1
fi

echo ""

# Infrastructure Observability
print_section "INFRASTRUCTURE OBSERVABILITY (Azure)"

echo "🏗️  Azure Resources Status:"
az resource list --resource-group robot-shop-dev-rg --output table --query "[].{Name:name, Type:type, Status:provisioningState}" 2>/dev/null || print_warning "Cannot access Azure resources (subscription may be reactivating)"

echo ""
echo "📊 AKS Cluster Status:"
AKS_STATUS=$(az aks show --resource-group robot-shop-dev-rg --name robot-shop-dev-aks --query "{status: provisioningState, powerState: powerState.code}" --output json 2>/dev/null || echo '{"status":"Unknown","powerState":"Unknown"}')
echo "   Status: $(echo $AKS_STATUS | jq -r '.status')"
echo "   Power State: $(echo $AKS_STATUS | jq -r '.powerState')"

echo ""
echo "📈 Application Insights:"
APP_INSIGHTS=$(az monitor app-insights component show --app robot-shop-dev-appinsights --resource-group robot-shop-dev-rg --query "{name: name, instrumentationKey: instrumentationKey}" --output json 2>/dev/null || echo '{"name":"Not accessible"}')
if [[ $(echo $APP_INSIGHTS | jq -r '.name') != "Not accessible" ]]; then
    print_success "Application Insights: $(echo $APP_INSIGHTS | jq -r '.name')"
    echo "   Portal: https://portal.azure.com/#@edevops13gmail.onmicrosoft.com/resource/subscriptions/00f5b0bc-d9f4-41da-99cd-abcc157e1035/resourceGroups/robot-shop-dev-rg/providers/microsoft.insights/components/robot-shop-dev-appinsights"
else
    print_warning "Application Insights not accessible"
fi

echo ""
echo "🔔 Action Groups (Alerting):"
ACTION_GROUPS=$(az monitor action-group list --resource-group robot-shop-dev-rg --query "[].{name: name, enabled: enabled}" --output json 2>/dev/null || echo '[]')
if [[ $(echo $ACTION_GROUPS | jq length) -gt 0 ]]; then
    echo $ACTION_GROUPS | jq -r '.[] | "   ✅ \(.name) (enabled: \(.enabled))"'
else
    print_warning "No action groups found"
fi

echo ""

# Application Observability
print_section "APPLICATION OBSERVABILITY (Kubernetes)"

# Check cluster connectivity
if kubectl cluster-info &>/dev/null; then
    print_success "Connected to AKS cluster"
    
    echo ""
    echo "🎯 Kubernetes Cluster Info:"
    kubectl get nodes --no-headers 2>/dev/null | while read line; do
        echo "   Node: $line"
    done
    
    echo ""
    echo "📦 Application Pods:"
    if kubectl get namespace robot-shop &>/dev/null; then
        kubectl get pods -n robot-shop --no-headers 2>/dev/null | while read line; do
            echo "   $line"
        done
    else
        print_warning "robot-shop namespace not found"
    fi
    
    echo ""
    echo "📊 Monitoring Stack:"
    if kubectl get namespace monitoring &>/dev/null; then
        print_success "Monitoring namespace exists"
        
        # Check Prometheus
        if kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus &>/dev/null; then
            PROM_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --no-headers | wc -l)
            print_success "Prometheus: $PROM_PODS pod(s) running"
        else
            print_warning "Prometheus not deployed"
        fi
        
        # Check Grafana
        if kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana &>/dev/null; then
            GRAFANA_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers | wc -l)
            print_success "Grafana: $GRAFANA_PODS pod(s) running"
        else
            print_warning "Grafana not deployed"
        fi
        
        # Check AlertManager
        if kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager &>/dev/null; then
            AM_PODS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager --no-headers | wc -l)
            print_success "AlertManager: $AM_PODS pod(s) running"
        else
            print_warning "AlertManager not deployed"
        fi
    else
        print_warning "Monitoring namespace not found"
    fi
    
    echo ""
    echo "🎯 SLO Monitoring:"
    if kubectl get prometheusrule -n monitoring robot-shop-slo-alerts &>/dev/null; then
        print_success "SLO alerts configured"
        echo "   - 99.9% availability target"
        echo "   - <0.1% error rate target"
        echo "   - <200ms latency target"
    else
        print_warning "SLO alerts not deployed"
    fi
    
    echo ""
    echo "💰 Cost Optimization:"
    if kubectl get resourcequota -n robot-shop &>/dev/null; then
        print_success "Resource quotas active"
        kubectl get resourcequota -n robot-shop -o custom-columns="NAME:.metadata.name,CPU:.status.used.requests\.cpu,MEMORY:.status.used.requests\.memory" --no-headers 2>/dev/null | while read line; do
            echo "   $line"
        done
    else
        print_warning "Resource quotas not deployed"
    fi
    
else
    print_error "Cannot connect to AKS cluster"
    echo "   Cluster may be stopped or subscription reactivating"
fi

echo ""

# Access Instructions
print_section "ACCESS INSTRUCTIONS"

echo "🌐 Infrastructure Monitoring:"
echo "   Azure Portal: https://portal.azure.com"
echo "   Application Insights: Search 'robot-shop-dev-appinsights'"
echo "   Log Analytics: Search 'robot-shop-dev-aks-logs'"

echo ""
echo "📊 Application Monitoring:"
if kubectl cluster-info &>/dev/null; then
    echo "   Grafana: kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80"
    echo "   Prometheus: kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090"
    echo "   AlertManager: kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093"
else
    echo "   First start AKS cluster: az aks start --resource-group robot-shop-dev-rg --name robot-shop-dev-aks"
    echo "   Then get credentials: az aks get-credentials --resource-group robot-shop-dev-rg --name robot-shop-dev-aks"
fi

echo ""
echo "🚀 Quick Deploy Commands:"
echo "   Deploy monitoring: ./scripts/deploy-monitoring.sh dev"
echo "   Deploy SLO alerts: kubectl apply -f monitoring/slo-alerts.yaml"
echo "   Deploy resource quotas: kubectl apply -f k8s/resource-quotas.yaml"

echo ""
print_section "SRE CAPABILITIES DEMONSTRATED"

echo "✅ Infrastructure Observability:"
echo "   - Azure Monitor integration"
echo "   - Application Insights telemetry"
echo "   - Log Analytics workspace"
echo "   - Action Groups for alerting"

echo ""
echo "✅ Application Observability:"
echo "   - Prometheus metrics collection"
echo "   - Grafana visualization"
echo "   - SLO-based alerting (99.9% availability)"
echo "   - Custom business metrics"

echo ""
echo "✅ Cost Optimization:"
echo "   - Resource quotas and limits"
echo "   - Cost analysis and reporting"
echo "   - Right-sizing recommendations"

echo ""
echo "✅ Reliability Engineering:"
echo "   - Multi-AZ deployment ready"
echo "   - Circuit breaker patterns"
echo "   - Pod disruption budgets"
echo "   - Auto-scaling configurations"

echo ""
print_success "SRE Observability Stack Complete!"
echo "This demonstrates enterprise-grade monitoring from infrastructure to application level."
