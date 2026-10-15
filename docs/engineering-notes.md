# Engineering notes: problems I hit and how I fixed them

These are real issues from building and running this platform on AKS (Dec 2025 – Jan 2026), plus a CI clean-up in October 2026. They're written short: symptom → cause → fix → what I'd change.

---

## 1. Prometheus scraped nothing, and nothing looked broken

**Symptom.** kube-prometheus-stack was healthy, the ServiceMonitors matched the service labels and RBAC was correct, but no application targets appeared in Prometheus.

**Investigation.** I ruled out missing CRDs, RBAC and Azure Monitor integration one by one. Then I tested from inside the Prometheus pod: DNS for `cart.robot-shop.svc.cluster.local` resolved, but `wget http://cart...:8080/metrics` timed out.

**Cause.** The app namespace has a **default-deny NetworkPolicy**. Ingress was only allowed from the ingress controller, not from the `monitoring` namespace.

**Fix.** I added `allow-monitoring-networkpolicy.yaml` to the umbrella chart, which allows ingress from the `monitoring` namespace to the metrics ports.

**Lesson.** A default-deny policy fails silently. When you add a new consumer (monitoring, a mesh, an egress to a payment API), you need a matching allow rule and a test that exercises it.

## 2. One node-exporter pod stuck in Pending on AKS

**Symptom.** The node-exporter DaemonSet ran on 3 of 4 nodes. The 4th pod stayed `Pending` with `didn't satisfy NodeAffinity`.

**Cause.** There were two causes:
1. The system node pool uses `only_critical_addons_enabled`, which adds the `CriticalAddonsOnly` taint.
2. `values-dev.yaml` set `affinity: {}`, which *overrode* my `values.yaml` affinity and fell back to the chart default. That default includes EKS-specific terms.

**Fix.** I removed the empty override and added a `CriticalAddonsOnly` toleration for node-exporter.

**Lesson.** An empty map in a later values file is not "no change". It replaces the earlier value. Now I run `helm template` with each environment's values file in CI.

## 3. ArgoCD reported "Synced / Healthy" but the Ingress didn't exist

**Symptom.** All pods and services were running, but `kubectl get ingress -n robot-shop` returned nothing. ArgoCD showed the web ingress as *pruned*.

**Cause.** The umbrella chart had its own `templates/ingress.yaml`, and the packaged `web` subchart also rendered an ingress with the same name. On top of that, the umbrella template referenced a values path (`.Values.web.umbrella...`) that the subchart's values shadowed.

**Fix.** I kept a single ingress definition in the umbrella chart and fixed the values path. I verified the fix with `helm template . -f values-dev.yaml` before letting ArgoCD sync.

**Lesson.** Render the full chart locally before trusting GitOps status. "Synced" only means Git and the cluster agree, not that the thing you wanted exists.

## 4. MongoDB CrashLoopBackOff after an image bump

**Symptom.** The MongoDB pod restarted repeatedly with `OOMKilled`, exit code 137, during WiredTiger initialisation.

**Cause.** The memory limit was 128Mi, which was too small for the newer MongoDB version.

**Fix.** I raised the memory request to 256Mi and the limit to 512Mi in `values-dev.yaml`. I also found and merged duplicate `mongodb:` blocks in the values file that were hiding which setting actually applied.

**Lesson.** Resource limits need to be revisited on every major version bump of a stateful dependency.

## 5. 16 critical CVEs in the cart image

**Symptom.** The Trivy gate in `build-and-push.yml` blocked the cart service on CRITICAL findings.

**Cause.** The image used an old globally installed npm (6.x) that bundled vulnerable transitive dependencies (e.g. `form-data`).

**Fix.** I upgraded npm in the image and rebuilt. After that, Trivy reported 0 CRITICAL for that image.

**Lesson.** A blocking gate is only useful if the fix path is quick. `ignore-unfixed` keeps the gate focused on issues you can actually fix.

## 6. A failing Checkov gate hid four more problems

**Symptom.** The infrastructure pipeline had failed on `main` at Checkov on every run since January (100 findings). Nothing after the gate had run for nine months.

**Fix.** I worked through the 100 findings. I fixed 55 in Terraform: Key Vault secret expiry and content types, purge protection, the ACR admin user off, SSH to the kubectl VM only from the Bastion subnet, storage hardening, and an NSG on every subnet. I suppressed 44 in code with a written reason each, mostly Premium-SKU features and private networking that needs self-hosted runners first. One finding went with a `release/*` OIDC credential that could never match, because Entra ID has no wildcards.

**What the gate had been hiding.** Once Checkov passed, the next jobs ran for the first time and failed in turn:
1. **Terraform Validate** used Terraform 1.6.0, which can't verify current provider releases (`openpgp: key expired`). I moved it to 1.9.8, the same version as the Azure DevOps pipeline.
2. **Deploy Bootstrap** ran on every PR and failed at Azure login (`AADSTS5000225`: tenant blocked for inactivity). Deploys now need a push to the branch and the `DEPLOY_ENABLED` repository variable.
3. **`environments/staging`** no longer validated. It wasn't in the CI matrix, so it had drifted from the modules: a duplicate variable, a missing module argument, and an old databases interface. I fixed it and added staging to both validate matrices.
4. **Prod** would have failed at apply: the storage account name was 26 characters, over Azure's limit of 24.

**Lesson.** A gate that's always red hides everything behind it. Keep the pipeline green so new failures show up, and validate every environment in CI, not only the one you deploy.
