# Notes API — Kubernetes Deployment

A Flask REST API for managing notes, containerized with Docker and deployed to production on AWS EKS with full observability, CI/CD automation, HTTPS, GitOps-driven deployment, and multi-environment support.

## Overview

This project demonstrates a complete cloud-native deployment workflow — from application code to a production-grade, self-healing, monitored, and secured deployment on AWS EKS, with staging and production environments managed via Kustomize, Helm, Terraform, and ArgoCD-driven GitOps. Built over a 30-day Cloud/DevOps learning sprint, now complete.

## Tech Stack

- **Backend:** Python, Flask, SQLAlchemy
- **Database:** PostgreSQL (persistent storage via EBS)
- **Containerization:** Docker
- **Orchestration:** Kubernetes (AWS EKS)
- **Environment Management:** Kustomize (base + overlays), Helm (custom chart), Terraform (modular multi-environment IaC with remote state)
- **GitOps:** ArgoCD, ApplicationSets, self-healing sync, sync waves/hooks
- **Secrets Management:** External Secrets Operator + AWS Secrets Manager (via IRSA)
- **CI/CD:** GitHub Actions with OIDC federation (secretless AWS authentication) — separate pipelines for the application and for Terraform itself
- **Monitoring:** Prometheus, Grafana
- **Alerting:** Alertmanager (Slack integration)
- **Logging:** Loki + Promtail
- **Networking/TLS:** AWS Load Balancer Controller, AWS Certificate Manager
- **DNS:** Custom domain with HTTPS (notesapi-raani.online)

## Features

- `GET /notes` — Retrieve all notes
- `POST /notes` — Create a new note
- `GET /health` — Health check endpoint (returns current environment)

## Architecture Highlights

- **Auto-deploy pipeline:** every push to `main` builds a Docker image, pushes it to Docker Hub, and automatically deploys to EKS — authenticated via GitHub OIDC, no stored AWS credentials
- **Full observability stack:** Prometheus scrapes cluster and application metrics, Grafana visualizes them, Alertmanager routes alerts to Slack, and Loki centralizes logs — all queryable from one Grafana instance
- **Production HTTPS:** real, publicly trusted TLS certificate via AWS Certificate Manager, terminated at an internet-facing Application Load Balancer
- **Multi-environment support:** staging and production run as fully independent deployments, each configurable via Kustomize overlays, a Helm chart, or Terraform, with per-environment values
- **GitOps-driven deployment:** ArgoCD continuously reconciles the cluster to match this repository — deployments, rollbacks, and drift correction all happen through Git, not manual commands
- **Zero secrets in Git:** database credentials are never committed or stored in the cluster directly — they're pulled live from AWS Secrets Manager by External Secrets Operator

## Running Locally (Docker + minikube)

```bash
docker build -t notes-api:v1 .
minikube image load notes-api:v1
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get pods
minikube service notes-api-service --url
```

## Deploying to AWS EKS

```bash
eksctl create cluster --name notes-api-cluster --region ap-south-1 --node-type t3.medium --nodes 2 --managed
kubectl apply -f postgres-secret.yaml
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

## Multi-Environment Deployment

### Option 1: Kustomize (base + overlays)

```bash
kubectl create namespace staging
kubectl create namespace production
kubectl apply -k k8s/overlays/staging
kubectl apply -k k8s/overlays/production
```

### Option 2: Helm (custom chart)

```bash
helm install notes-api notes-api-chart -f values-staging.yaml -n staging
helm install notes-api notes-api-chart -f values-production.yaml -n production
```

Both approaches deploy from a single source of truth, with only environment-specific values (replica count, environment name) differing between staging and production.

### Option 3: GitOps (ArgoCD) — see below

## Infrastructure as Code (Terraform)

The EKS cluster, VPC, and full application stack are also fully managed via Terraform, as an alternative to the manual `eksctl`/`kubectl` approach above.

- **Structure**
  A shared reusable module (`terraform-eks/modules/eks`) is consumed by two independent environment configurations (`terraform-eks/environments/staging`, `terraform-eks/environments/production`), each with its own remote state file — genuinely separate, coexisting infrastructure, not shared state switched by variable files.

- **Remote state**
  S3 backend with versioning, DynamoDB for state locking.

- **Security**
  Database credentials are passed as a `sensitive = true` Terraform variable via environment variable at apply-time — never hardcoded or committed to version control.

- **State management**
  Hands-on with `terraform import` (bringing manually-created resources under Terraform control), `terraform state mv` (safely renaming resources without destroy/recreate), and drift detection via `terraform plan -refresh-only`.

- **for_each and dynamic blocks**
  Used to provision multiple resources, and multiple repeated nested blocks within a single resource, from one definition instead of duplicating code.

- **Lifecycle rules**
  `prevent_destroy` protects critical resources from accidental teardown, even when explicitly targeted.

- **Module versioning**
  The shared module is tagged in Git (e.g. `eks-module-v1.0.0`) and referenced via a version-pinned source URL, so environments consume a fixed version rather than a moving local path. Updating the module doesn't affect environments pinned to an older tag.

### Deploying via Terraform

```bash
cd terraform-eks/environments/staging   # or environments/production
terraform init
export TF_VAR_postgres_password="<your-password>"
terraform apply
```

### Terraform CI/CD

Terraform is also run through its own GitHub Actions pipeline, separate from the application's deploy pipeline: `terraform plan` runs automatically on every pull request, and `terraform apply` runs automatically on merge to `main` — authenticated via a dedicated IAM role (scoped for infrastructure management, distinct from the narrower role used for application deploys) using the same OIDC federation pattern.

## GitOps (ArgoCD)

The application can also be deployed and managed entirely through ArgoCD — the cluster continuously syncs itself to match this repository, so changes ship by committing to Git, not by running commands against the cluster.

- **ApplicationSet**
  One shared template auto-generates separate `Application` resources for staging and production (List generator), instead of maintaining two manifests by hand.

- **Self-healing**
  `selfHeal: true` detects manual, out-of-band changes made directly to the cluster and automatically reverts them to match Git.

- **Rollback via Git**
  Recovery from a bad deploy is a `git revert` + push — never a live cluster command. Git stays the single source of truth for every state the cluster has been in.

- **Sync waves & hooks**
  Deploy ordering is controlled via `argocd.argoproj.io/sync-wave` annotations. Lifecycle hooks (`PreSync`/`PostSync`) run one-off tasks tied to specific points in the sync process, separate from ordinary resource ordering.

- **Secrets in GitOps**
  Database credentials are never stored in Git or hardcoded into the cluster. [External Secrets Operator](https://external-secrets.io/) authenticates to AWS via IRSA (scoped to the cluster's own OIDC provider) and continuously syncs the real secret from AWS Secrets Manager into a native Kubernetes Secret.

### Deploying via ArgoCD

```bash
kubectl apply -f argocd-applicationset.yaml
```

This single command generates and syncs both the staging and production `Application` resources.

## Verification

```bash
curl https://notesapi-raani.online/health
# Response: {"status": "ok", "environment": "production"}
```

## CI/CD

Every push to `main` triggers `.github/workflows/ci-cd.yml`, which:
1. Builds and pushes a Docker image to Docker Hub, tagged with the commit SHA
2. Authenticates to AWS via OIDC (no stored credentials)
3. Deploys the new image directly to the live EKS cluster

A separate workflow, `.github/workflows/terraform.yml`, runs `terraform plan` on every pull request and `terraform apply` on merge to `main`.

## Author

Raani — [GitHub](https://github.com/Raani1011)

30-day Cloud/DevOps learning sprint — complete (Day 30 of 30).
