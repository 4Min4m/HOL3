# Node.js Kubernetes Lab with Terraform and Ansible

This project is a hands-on lab to deploy a Node.js application on Kubernetes using Terraform for infrastructure management, Ansible for environment setup, and GitHub Actions for CI/CD.

## Project Structure
- `node-app/`: Contains the Node.js application source code.
- `terraform/`: Terraform configurations for Kubernetes Deployment and Service.
- `ansible/`: Ansible playbook for setting up Minikube and Kubernetes.
- `.github/workflows/`: GitHub Actions workflow for CI/CD.

## Prerequisites
- [Docker](https://www.docker.com/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/)
- [Terraform](https://www.terraform.io/)
- [Ansible](https://www.ansible.com/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- A GitHub account with a Personal Access Token (PAT) for `ghcr.io`.

## Setup
1. **Clone the repository**:
   ```bash
   git clone https://github.com/4Min4m/<your-repo>.git
   cd <your-repo>
```
**Run Ansible Playbook**:
```bash
ansible-playbook ansible/playbook.yml -e "CR_PAT=<your-pat> EMAIL=<your-email>"
```
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
kubectl port-forward svc/node-app-service 8080:80
```
Open the URL in your browser (e.g., http://<codespace-url>:8080) to see "Hello, World!".

## CI/CD

The GitHub Actions workflow (.github/workflows/ci-cd.yml) automates:
Building and pushing the Docker image to ghcr.io.

Deploying to Kubernetes using Terraform.

Ensure the CR_PAT secret is set in GitHub Actions.

**Updating the Application**
Modify node-app/index.js (e.g., change the greeting).

Commit and push changes:

```bash
git add .
git commit -m "Update greeting"
git push
```
The CI/CD pipeline will rebuild, push, and redeploy the app.