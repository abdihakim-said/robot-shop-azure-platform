# Quick Deployment Reference

## Current Status
✅ **Monolithic deployment running** - All 12 services deployed via `helm install robot-shop ./helm`
✅ **Per-service charts ready** - 12 independent charts in `./helm-charts/`
✅ **CI/CD pipelines updated** - Use per-service charts

---

## Deploy Everything (Monolithic)

```bash
# Full application deployment
helm upgrade --install robot-shop ./helm \
  --namespace robot-shop \
  --create-namespace \
  --values ./helm/values-dev.yaml

# Check status
kubectl get pods -n robot-shop
```

---

## Deploy Single Service (Microservices)

```bash
# Deploy one service
helm upgrade --install cart ./helm-charts/cart \
  --namespace robot-shop \
  --create-namespace

# Update with new image
helm upgrade cart ./helm-charts/cart \
  --namespace robot-shop \
  --set image.tag=abc123

# Check status
kubectl get pods -l service=cart -n robot-shop
```

---

## Deploy All Services Independently

```bash
# Deploy each service separately
for service in web cart catalogue user payment shipping ratings dispatch mongodb mysql redis rabbitmq; do
  echo "Deploying $service..."
  helm upgrade --install $service ./helm-charts/$service \
    --namespace robot-shop \
    --create-namespace
done
```

---

## Switch from Monolithic to Per-Service

```bash
# 1. Delete monolithic deployment
helm uninstall robot-shop -n robot-shop

# 2. Deploy each service
for service in web cart catalogue user payment shipping ratings dispatch mongodb mysql redis rabbitmq; do
  helm install $service ./helm-charts/$service -n robot-shop
done

# 3. Verify
helm list -n robot-shop
kubectl get pods -n robot-shop
```

---

## Useful Commands

```bash
# List all Helm releases
helm list -n robot-shop

# Check specific service
kubectl get pods -l service=cart -n robot-shop

# View service logs
kubectl logs -l service=cart -n robot-shop

# Rollback a service
helm rollback cart -n robot-shop

# Delete a service
helm uninstall cart -n robot-shop
```

---

## For Your Interview

**Current setup:** "I have a monolithic Helm chart for quick deployments and per-service charts for production-grade microservices architecture."

**Best practice:** "In production, we'd use per-service charts with CI/CD pipelines for independent deployments."
