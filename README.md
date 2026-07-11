# Notes API — Kubernetes Deployment

A Flask REST API for managing notes, containerized with Docker and deployed to a Kubernetes cluster using minikube.

## Overview

This project demonstrates a complete containerization and orchestration workflow — from application code to a running, self-healing deployment on Kubernetes.

## Tech Stack

- **Backend:** Python, Flask, SQLAlchemy
- **Containerization:** Docker
- **Orchestration:** Kubernetes (minikube)
- **Environment:** WSL2 (Ubuntu 26.04)

## Features

- `GET /notes` — Retrieve all notes
- `POST /notes` — Create a new note
- `GET /health` — Health check endpoint

## Running Locally

```bash
docker build -t notes-api:v1 .
minikube image load notes-api:v1
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get pods
minikube service notes-api-service --url
```

## Verification

```bash
curl http://<service-url>/health
# Response: {"status": "ok"}
```

## Author

Raani — [GitHub](https://github.com/Raani1011)

---
*Day 1 of a 30-day Cloud/DevOps learning sprint.*
