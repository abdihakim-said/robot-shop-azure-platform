# Azure DevOps pipeline

`azure-pipelines.yml` runs the platform checks and the dev infrastructure deployment as
Azure DevOps stages. It mirrors the GitHub Actions workflows, so either CI system can run the repo.

| Stage | When | What it does |
|---|---|---|
| Validate | Every push and PR to `main`/`develop` touching `terraform/` or `helm-charts/` | `terraform fmt` and `validate` for each layer, Helm lint and render for dev, Checkov report published to the Tests tab. No Azure credentials. |
| Plan | Run manually with **deploy = true** | Blocking Checkov gate, then `terraform plan` for dev. The plan is saved as an artifact. |
| Apply | After Plan, `main` only | Deployment job on the `robot-shop-dev` environment. Its approvals run before the saved plan is applied. |

## Setup

1. **Project and pipeline.** In Azure DevOps, create a project, then *Pipelines → New pipeline → GitHub* and choose this repo. Azure DevOps finds `azure-pipelines.yml`.
2. **Service connection.** *Project settings → Service connections → Azure Resource Manager → Workload identity federation (automatic)*, scoped to the subscription. Name it `robot-shop-azure`, or pass another name in the `serviceConnection` parameter. This uses short-lived federated tokens, with no client secret stored.
3. **Environment and approval.** *Pipelines → Environments → New environment* named `robot-shop-dev`, then *Approvals and checks → Approvals*.
4. **State backend.** Plan expects the bootstrap layer's storage account in `robot-shop-tfstate-rg` (created by `terraform/bootstrap`). The service connection identity needs *Contributor* on the subscription and permission to list storage account keys in that resource group.

Validate needs only step 1: it runs with no service connection. Plan and Apply stay out of the run unless you queue it with **deploy = true**.

## Design notes

- **Credential-free by default.** The Plan and Apply stages are only added to the run at compile time when `deploy` is true, the same idea as `DEPLOY_ENABLED` in the GitHub workflows.
- **Plan once, apply that plan.** Apply uses the saved `tfplan` artifact, so what was approved is what gets applied.
- **Checkov.** Validate reports findings without failing. The Plan stage blocks on any new finding. All 100 findings from October 2026 are resolved: 55 fixed, and 44 suppressed in the Terraform with a `#checkov:skip` reason (see README, known limitations).
