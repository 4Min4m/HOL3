# Node.js Kubernetes Lab

This project is a hands-on lab to demonstrate deploying a Node.js application on Kubernetes using Terraform for infrastructure management and GitHub Actions for CI/CD.

## Project Structure
- `node-app/`: Contains the Node.js application source code.
- `terraform/`: Terraform configurations for Kubernetes Deployment and Service.
- `.github/workflows/`: GitHub Actions workflow for CI/CD.

## Prerequisites
- [Docker](https://www.docker.com/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [Terraform](https://www.terraform.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- A GitHub account with a Personal Access Token (PAT) for `ghcr.io`.

## Setup
1. **Clone the repository**:
   ```bash
   git clone https://github.com/4Min4m/<your-repo>.git
   cd <your-repo>
```
**Start Minikube**:
```bash
minikube start --driver=docker
```
**Create ImagePullSecret**:
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=4min4m \
  --docker-password=<your-pat> \
  --docker-email=<your-email>
```
**Apply Terraform**
```bash
cd terraform
terraform init
terraform apply
```
## Accessing the Application

Run:
```bash
minikube service node-app-service --url
```
Open the provided URL in your browser to see "Hello, World!".

## CI/CD

The GitHub Actions workflow (.github/workflows/ci-cd.yml) automates:
Building and pushing the Docker image to ghcr.io.

Deploying to Kubernetes using Terraform.

Ensure the CR_PAT secret is set in GitHub Actions.

Updating the Application
Modify node-app/index.js (e.g., change the greeting).

Commit and push changes:

```bash
git add .
git commit -m "Update greeting"
git push
```
The CI/CD pipeline will rebuild, push, and redeploy the app.