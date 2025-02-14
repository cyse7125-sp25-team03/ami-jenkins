# Jenkins AMI Build and CI/CD with Packer and GitHub Actions

## Overview
This project outlines the process for creating a custom Amazon Machine Image (AMI) for Jenkins using Packer. The AMI will include all necessary components for Jenkins, including plugins, credentials, seed jobs and configuration. Additionally, the project implements a CI/CD pipeline using GitHub Actions to automate the AMI build and registration process upon repository updates.

## Project Structure
```
ami-jenkins/
│-- jenkins/
│   ├── groovy/
│   ├── jcasc.yaml
│-- packer/
│   ├── packer.pkr.hcl
│-- scripts/
│   ├── setup.sh
```

### 1. `jenkins/groovy/`
This directory contains Groovy scripts used for automating Jenkins job configurations and setup, credentials, and plugins.

### 2. `jenkins/jcasc.yaml`
This file contains Jenkins Configuration as Code (JCasC) settings for automated configuration management.

### 3. `packer/`
This directory contains the Packer configuration file used to build a Jenkins AMI.
- **`packer.pkr.hcl`** - Packer template defining the base image, provisioners, and build configuration for the Jenkins AMI.

### 4. `scripts/`
This directory contains general setup and configuration scripts.
- **`setup.sh`** - Script for setting up and configuring the Jenkins environment, installing dependencies, and additional configurations.

## Requirements

### AMI Build
1. **Source Image**: Use Ubuntu 24.04 LTS.
2. **Private AMI**: Ensure the AMI is private and accessible only to your team.
3. **ROOT AWS Account**: Perform all AMI builds in the root AWS account.
4. **Default VPC**: The AMI build should utilize the default VPC in your AWS account.
5. **Jenkins Setup**:
   - Install Jenkins.
   - Install necessary plugins.
6. **Reverse Proxy**:
   - Use Nginx as a reverse proxy for Jenkins.

### CI/CD Pipeline
1. **Trigger**: Any changes pushed to the repository should trigger the pipeline.
2. **Build**: Automate the Packer build process.
3. **Registration**: Register the newly built private AMI in the ROOT AWS account.

## Notes
- **Private AMI**: Use IAM policies to ensure AMI visibility is restricted to your team.
- **IAM Roles**: Attach required IAM roles to the GitHub Actions runner or local environment to allow AMI creation.

## Outputs
- A private AMI in the ROOT AWS account.
- Jenkins is fully set up and ready after launching an EC2 instance.

## References
- [Packer Documentation](https://www.packer.io/docs)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
