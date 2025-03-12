#!/bin/bash
set -e

# Update and install dependencies
sudo apt-get update
sudo apt-get install -y openjdk-21-jdk

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y jenkins

# Install Nginx
sudo apt-get install -y nginx

# Install Certbot for Let's Encrypt
sudo apt-get install -y certbot python3-certbot-nginx

# Install nodejs
curl -fsSL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
sudo -E bash nodesource_setup.sh
sudo apt-get install -y nodejs

# Install helm
wget https://get.helm.sh/helm-v3.17.1-linux-amd64.tar.gz \
    && tar -zxvf helm-v3.17.1-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm

# Install semantic-release plugins
sudo npm install -g semantic-release @semantic-release/commit-analyzer @semantic-release/release-notes-generator @semantic-release/changelog @semantic-release/github @semantic-release/git
sudo npm install semantic-release-helm

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Create Jenkins init directory
sudo mkdir -p /var/lib/jenkins/init.groovy.d/
sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d/

# Stop Jenkins service before copying files
sudo systemctl stop jenkins

# Create a staging directory for initialization scripts
sudo mkdir -p /var/lib/jenkins/staged-init/
sudo chown -R jenkins:jenkins /var/lib/jenkins/staged-init/

# Copy configuration files to staging
sudo cp -r /tmp/jenkins/groovy/base-setup-jenkins.groovy /var/lib/jenkins/staged-init/base-setup-jenkins.groovy
sudo cp -r /tmp/jenkins/groovy/credentials.groovy /var/lib/jenkins/staged-init/credentials.groovy

# Seed job scripts
sudo cp -r /tmp/jenkins/groovy/tf-validate-seed-job.groovy /var/lib/jenkins/staged-init/tf-validate-seed-job.groovy
sudo cp -r /tmp/jenkins/groovy/static-site-publish-seed-job.groovy /var/lib/jenkins/staged-init/static-site-publish-seed-job.groovy
sudo cp -r /tmp/jenkins/groovy/webapp-publish-seed-job.groovy /var/lib/jenkins/staged-init/webapp-publish-seed-job.groovy
sudo cp -r /tmp/jenkins/groovy/db-webapp-publish-seed-job.groovy /var/lib/jenkins/staged-init/db-webapp-publish-seed-job.groovy
sudo cp -r /tmp/jenkins/groovy/api-server-seed-job.groovy /var/lib/jenkins/staged-init/api-server-seed-job.groovy
sudo cp -r /tmp/jenkins/groovy/api-server-prcheck-seed-job.groovy /var/lib/jenkins/staged-init/api-server-prcheck-seed-job.groovy
sudo cp -r /tmp/jenkins/groovy/db-trace-processor-prcheck-seed-job.groovy /var/lib/jenkins/staged-init/db-trace-processor-prcheck-seed-job.groovy
sudo cp -r /tmp/jenkins/groovy/db-trace-processor-publish-seed-job.groovy /var/lib/jenkins/staged-init/db-trace-processor-publish-seed-job.groovy

# Commitlint seed job scripts
sudo find /tmp/jenkins/groovy/ -name "commitlint-*.groovy" -exec sudo cp {} /var/lib/jenkins/staged-init/ \;

# Copy Jenkins configuration as code (JCasC) file
sudo cp /tmp/jenkins/jcasc.yaml /var/lib/jenkins/jcasc.yaml

# Create initialization script that will run on first boot
sudo tee /var/lib/jenkins/init-on-boot.sh << 'EOF'
#!/bin/bash

# Wait for Jenkins to be fully operational
while ! curl -s -I http://localhost:8080/login >/dev/null 2>&1; do
    sleep 5
done

# Move initialization scripts from staging to init.groovy.d
mv /var/lib/jenkins/staged-init/base-setup-jenkins.groovy /var/lib/jenkins/init.groovy.d/base-setup-jenkins.groovy
mv /var/lib/jenkins/staged-init/credentials.groovy /usr/local/credentials.groovy

# Seed job scripts
mv /var/lib/jenkins/staged-init/tf-validate-seed-job.groovy /usr/local/tf-validate-seed-job.groovy
mv /var/lib/jenkins/staged-init/static-site-publish-seed-job.groovy /usr/local/static-site-publish-seed-job.groovy
mv /var/lib/jenkins/staged-init/webapp-publish-seed-job.groovy /usr/local/webapp-publish-seed-job.groovy
mv /var/lib/jenkins/staged-init/db-webapp-publish-seed-job.groovy /usr/local/db-webapp-publish-seed-job.groovy
mv /var/lib/jenkins/staged-init/api-server-seed-job.groovy /usr/local/api-server-seed-job.groovy
mv /var/lib/jenkins/staged-init/api-server-prcheck-seed-job.groovy /usr/local/api-server-prcheck-seed-job.groovy
mv /var/lib/jenkins/staged-init/db-trace-processor-prcheck-seed-job.groovy /usr/local/db-trace-processor-prcheck-seed-job.groovy
mv /var/lib/jenkins/staged-init/db-trace-processor-publish-seed-job.groovy /usr/local/db-trace-processor-publish-seed-job.groovy

# Commitlint seed job scripts
find /var/lib/jenkins/staged-init/ -name "commitlint-*.groovy" -exec mv {} /usr/local/ \;

# Restart Jenkins to apply initialization scripts
systemctl restart jenkins
EOF

sudo chmod +x /var/lib/jenkins/init-on-boot.sh

# Create systemd service to run initialization on boot
sudo tee /etc/systemd/system/jenkins-init.service << EOF
[Unit]
Description=Jenkins First Boot Initialization
After=jenkins.service
ConditionPathExists=/var/lib/jenkins/staged-init

[Service]
Type=oneshot
ExecStart=/var/lib/jenkins/init-on-boot.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Set environment variables for Jenkins configuration
sudo tee /etc/default/jenkins << EOF
JENKINS_HOME=/var/lib/jenkins
JENKINS_ARGS="--httpPort=8080"
CASC_JENKINS_CONFIG=/var/lib/jenkins/jcasc.yaml
GITHUB_USERNAME=${GITHUB_USERNAME}
GITHUB_TOKEN=${GITHUB_TOKEN}
GITHUB_ID=${GITHUB_ID}
GITHUB_DESCRIPTION=${GITHUB_DESCRIPTION}
DOCKER_USERNAME=${DOCKER_USERNAME}
DOCKER_TOKEN=${DOCKER_TOKEN}
DOCKER_ID=${DOCKER_ID}
DOCKER_DESCRIPTION=${DOCKER_DESCRIPTION}
JENKINS_ADMIN_USERNAME=${JENKINS_ADMIN_USERNAME}
JENKINS_ADMIN_PASSWORD=${JENKINS_ADMIN_PASSWORD}
EOF

# Modify the Jenkins systemd service to load environment variables
sudo sed -i '/\[Service\]/a EnvironmentFile=-/etc/default/jenkins' /lib/systemd/system/jenkins.service
sudo sed -i 's/\(JAVA_OPTS=-Djava\.awt\.headless=true\)/\1 -Djenkins.install.runSetupWizard=false/' /lib/systemd/system/jenkins.service
sudo sed -i '/Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"/a Environment="CASC_JENKINS_CONFIG=/var/lib/jenkins/jcasc.yaml"' /lib/systemd/system/jenkins.service

# Reload systemd and restart services
sudo systemctl daemon-reload
sudo systemctl enable jenkins-init.service
sudo systemctl restart jenkins

# Install docker
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl enable docker
sudo systemctl start docker

# add jenkins to docker users
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
