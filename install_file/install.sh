#!/bin/bash
set -e

echo "🔧 Updating system..."
sudo apt update -y

echo "🚀 Installing Java 17 for Jenkins..."
sudo apt install -y openjdk-17-jdk

echo "📦 Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update -y
sudo apt install -y jenkins
sudo systemctl enable --now jenkins
echo "Jenkins installed and running on port 8080."

echo "🐳 Installing Docker..."
sudo apt install -y docker.io
sudo usermod -aG docker $USER
newgrp docker
sudo chmod 666 /var/run/docker.sock
echo "Docker setup done."

echo "🔍 Installing Trivy..."
sudo apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
  https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" \
  | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install -y trivy
echo "Trivy installed."

echo "🧪 Starting SonarQube (container)..."
docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community
echo "SonarQube is available on port 9000."

echo "🔧 Installing kind (Kubernetes in Docker)..."
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
kind --version

echo "📦 Creating kind cluster with 2 workers..."
cat <<EOF | kind create cluster --name my_cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
  - role: worker
EOF

echo "✅ Setup complete!"
echo "- Jenkins → http://localhost:8080 (or server‑IP:8080)"
echo "- SonarQube → http://localhost:9000"
echo "- KIND cluster 'devsecops' with 1 control-plane + 2 workers"
echo "- Docker, Trivy are ready to use"
