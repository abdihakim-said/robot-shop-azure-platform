#!/bin/bash

echo "🧪 Real-Time Monitoring Test"
echo "═══════════════════════════════════════════════════════════"

# 1. Access Grafana
echo ""
echo "📊 Step 1: Access Grafana"
echo "Run this command in a new terminal:"
echo "  kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80"
echo ""
echo "Then open: http://localhost:3000"
echo "Default credentials: admin / prom-operator"
echo ""
read -p "Press Enter when Grafana is open..."

# 2. Access Prometheus
echo ""
echo "📈 Step 2: Access Prometheus"
echo "Run this command in another terminal:"
echo "  kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090"
echo ""
echo "Then open: http://localhost:9090"
echo ""
read -p "Press Enter when Prometheus is open..."

# 3. Check current metrics
echo ""
echo "📊 Step 3: Check Current Metrics"
echo "In Prometheus, try these queries:"
echo ""
echo "1. Service uptime:"
echo "   up{namespace=\"robot-shop\"}"
echo ""
echo "2. Pod CPU usage:"
echo "   rate(container_cpu_usage_seconds_total{namespace=\"robot-shop\"}[5m])"
echo ""
echo "3. Pod memory usage:"
echo "   container_memory_usage_bytes{namespace=\"robot-shop\"}"
echo ""
read -p "Press Enter to continue..."

# 4. Simulate an incident
echo ""
echo "🔥 Step 4: Simulate an Incident (Kill a pod)"
echo "Let's kill the cart service and watch it recover:"
echo ""
POD=$(kubectl get pods -n robot-shop -l app=cart -o jsonpath='{.items[0].metadata.name}')
echo "Current cart pod: $POD"
echo ""
read -p "Press Enter to delete the pod..."

kubectl delete pod $POD -n robot-shop
echo "Pod deleted! Watch it recover:"
kubectl get pods -n robot-shop -l app=cart -w &
WATCH_PID=$!
sleep 30
kill $WATCH_PID 2>/dev/null

# 5. Check pod restart count
echo ""
echo "📊 Step 5: Check Restart Count in Prometheus"
echo "Query: kube_pod_container_status_restarts_total{namespace=\"robot-shop\",pod=~\"cart.*\"}"
echo ""
read -p "Press Enter to continue..."

# 6. Test web service
echo ""
echo "🌐 Step 6: Test Web Service"
WEB_IP=$(kubectl get svc web -n robot-shop -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Web service IP: $WEB_IP"
echo "Testing health endpoint..."
curl -s http://$WEB_IP:8080/health || echo "Health check failed"
echo ""
echo "Open in browser: http://$WEB_IP:8080"
echo ""
read -p "Press Enter to continue..."

# 7. Generate some load
echo ""
echo "📈 Step 7: Generate Load (watch metrics change)"
echo "Sending 100 requests to web service..."
for i in {1..100}; do
  curl -s http://$WEB_IP:8080 > /dev/null &
done
wait
echo "Load generated! Check Prometheus for traffic spike."
echo ""
read -p "Press Enter to continue..."

# 8. Check AlertManager
echo ""
echo "🚨 Step 8: Check AlertManager"
echo "Run this command in another terminal:"
echo "  kubectl port-forward -n monitoring svc/alertmanager-monitoring-kube-prometheus-alertmanager 9093:9093"
echo ""
echo "Then open: http://localhost:9093"
echo "Check if any alerts are firing"
echo ""
read -p "Press Enter to continue..."

# 9. Summary
echo ""
echo "✅ Real-Time Testing Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "What you tested:"
echo "  ✅ Grafana dashboards"
echo "  ✅ Prometheus metrics"
echo "  ✅ Pod self-healing (killed cart pod)"
echo "  ✅ Service health checks"
echo "  ✅ Load generation"
echo "  ✅ AlertManager"
echo ""
echo "Next steps:"
echo "  1. Import Golden Signals dashboard to Grafana"
echo "  2. Create a test alert"
echo "  3. Document your findings"
echo ""
