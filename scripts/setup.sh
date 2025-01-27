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
