apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring-${environment}
  namespace: argocd
  labels:
    environment: ${environment}
    app: monitoring
    tier: infrastructure
spec:
  project: default
  
  source:
    repoURL: https://github.com/abdihakim-said/robot-shop-azure-platform
    targetRevision: ${branch}  # Environment-specific branch
    path: helm-charts/monitoring
    helm:
      valueFiles:
        - values.yaml
        - values-${environment}.yaml  # Environment-specific values
      parameters:
        - name: prometheus.enabled
          value: "true"
        - name: global.environment
          value: ${environment}
        - name: global.keyVault.name
          value: ${key_vault_name}
        - name: global.keyVault.tenantId
          value: ${tenant_id}
        - name: global.managedIdentity.clientId
          value: ${managed_identity_client_id}
        - name: global.grafanaWorkloadIdentity.clientId
          value: ${grafana_workload_identity_client_id}
        - name: kube-prometheus-stack.grafana.serviceAccount.annotations.azure\.workload\.identity/client-id
          value: ${grafana_workload_identity_client_id}
        - name: kube-prometheus-stack.grafana.podLabels.azure\.workload\.identity/use
          value: "true"
  
  destination:
    server: https://kubernetes.default.svc
    namespace: ${namespace}
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
    retry:
      limit: 10
      backoff:
        duration: 10s
        factor: 2
        maxDuration: 5m
