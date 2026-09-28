# Engineering notes: problems I hit and how I fixed them

These are real issues from building and running this platform on AKS (Dec 2025 – Jan 2026). They're written short: symptom → cause → fix → what I'd change.

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
