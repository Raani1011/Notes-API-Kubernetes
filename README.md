# Notes API — Kubernetes Deployment

A Flask REST API for managing notes, containerized with Docker and deployed to production on AWS EKS with full observability, CI/CD automation, and HTTPS.

## Overview

This project demonstrates a complete cloud-native deployment workflow — from application code to a production-grade, self-healing, monitored, and secured deployment on AWS EKS. Built as part of a 30-day Cloud/DevOps learning sprint.

## Tech Stack

- **Backend:** Python, Flask, SQLAlchemy
- **Database:** PostgreSQL (persistent storage via EBS)
- **Containerization:** Docker
- **Orchestration:** Kubernetes (AWS EKS)
- **CI/CD:** GitHub Actions with OIDC federation (secretless AWS authentication)
- **Monitoring:** Prometheus, Grafana
- **Alerting:** Alertmanager (Slack integration)
- **Logging:** Loki + Promtail
- **Networking/TLS:** AWS Load Balancer Controller, AWS Certificate Manager
- **DNS:** Custom domain with HTTPS (notesapi-raani.online)

## Features

- `GET /notes` — Retrieve all notes
- `POST /notes` — Create a new note
- `GET /health` — Health check endpoint

## Architecture Highlights

- **Auto-deploy pipeline:** every push to `main` builds a Docker image, pushes it to Docker Hub, and automatically deploys to EKS — authenticated via GitHub OIDC, no stored AWS credentials
- **Full observability stack:** Prometheus scrapes cluster and application metrics, Grafana visualizes them, Alertmanager routes alerts to Slack, and Loki centralizes logs — all queryable from one Grafana instance
- **Production HTTPS:** real, publicly trusted TLS certificate via AWS Certificate Manager, terminated at an internet-facing Application Load Balancer

## Running Locally (Docker + minikube)

docker build -t notes-api:v1 .
minikube image load notes-api:v1
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get pods
minikube service notes-api-service --url


## Deploying to AWS EKS

eksctl create cluster --name notes-api-cluster --region ap-south-1 --node-type t3.medium --nodes 2 --managed
kubectl apply -f postgres-secret.yaml
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml


## Verification

curl https://notesapi-raani.online/health

Response: {"status": "ok"}

## CI/CD

Every push to `main` triggers `.github/workflows/ci-cd.yml`, which:
1. Builds and pushes a Docker image to Docker Hub, tagged with the commit SHA
2. Authenticates to AWS via OIDC (no stored credentials)
3. Deploys the new image directly to the live EKS cluster

## Author

Raani — [GitHub](https://github.com/Raani1011)

30-day Cloud/DevOps learning sprint — Day 9 of 30.
