#!/bin/bash

echo "🚀 Deploying SRE Incident Management Setup..."

# Apply payment service alerts
echo "📊 Applying payment service alerts..."
kubectl apply -f monitoring/alerts/payment-service-alerts.yaml

# Apply web service alerts
echo "🌐 Applying web service alerts..."
kubectl apply -f monitoring/alerts/web-service-alerts.yaml

# Apply cart service alerts
echo "🛒 Applying cart service alerts..."
kubectl apply -f monitoring/alerts/cart-service-alerts.yaml

# Apply AlertManager Slack configuration
echo "💬 Configuring Slack alerts..."
kubectl apply -f monitoring/alertmanager-slack-config.yaml

# Apply AlertManager Email configuration (if exists)
if [ -f "monitoring/alertmanager-email-config.yaml" ]; then
    echo "📧 Configuring email alerts..."
    kubectl apply -f monitoring/alertmanager-email-config.yaml
fi

# Restart payment service to pick up new metrics
echo "🔄 Restarting payment service with enhanced metrics..."
kubectl rollout restart deployment/payment -n robot-shop
kubectl rollout status deployment/payment -n robot-shop

# Import SRE dashboard to Grafana
echo "📈 Setting up SRE dashboard..."
kubectl create configmap sre-payment-dashboard \
  --from-file=monitoring/dashboards/sre-payment-dashboard.json \
  -n monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

# Verify setup
echo "✅ Verifying setup..."
echo "Checking payment service pods..."
kubectl get pods -n robot-shop -l app=payment

echo "Checking alerts are loaded..."
kubectl get prometheusrules -n monitoring payment-service-alerts

echo "🎉 SRE Incident Management setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Access Grafana: kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80"
echo "2. Import dashboard: monitoring/dashboards/sre-payment-dashboard.json"
echo "3. Test alerts: kubectl scale deployment payment --replicas=0 -n robot-shop"
echo "4. Configure Slack webhook in alertmanager-slack-config.yaml"
echo ""
echo "📚 Documentation:"
echo "- Runbooks: /runbooks/"
echo "- Incident Process: /docs/sre-incident-response-process.md"
