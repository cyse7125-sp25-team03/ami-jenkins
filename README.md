# Jenkins AMI Build and CI/CD with Packer and GitHub Actions

![HashiCorp](https://img.shields.io/badge/HashiCorp-000000.svg?style=for-the-badge&logo=hashicorp&logoColor=white)
![Packer](https://img.shields.io/badge/Packer-02A8EF.svg?style=for-the-badge&logo=packer&logoColor=white)
![Amazon Web Services](https://img.shields.io/badge/Amazon%20Web%20Services-232F3E.svg?style=for-the-badge&logo=Amazon-Web-Services&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF.svg?style=for-the-badge&logo=github-actions&logoColor=white)
![Jenkins](https://img.shields.io/badge/Jenkins-D24939.svg?style=for-the-badge&logo=jenkins&logoColor=white)
![Groovy](https://img.shields.io/badge/Groovy-4298B8.svg?style=for-the-badge&logo=Apache-Groovy&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639.svg?style=for-the-badge&logo=nginx&logoColor=white)
![Let's Encrypt](https://img.shields.io/badge/Let's_Encrypt-003A70.svg?style=for-the-badge&logo=letsencrypt&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420.svg?style=for-the-badge&logo=ubuntu&logoColor=white)
![Shell Script](https://img.shields.io/badge/Shell_Script-121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

## Overview
This project outlines the process for creating a custom Amazon Machine Image (AMI) for Jenkins using Packer. The AMI will include all necessary components for Jenkins, including plugins, credentials, seed jobs and configuration. Additionally, the project implements a CI/CD pipeline using GitHub Actions to automate the AMI build and registration process upon repository updates.

The generated AMI is used by the [infra-jenkins](https://github.com/cyse7125-sp25-team03/infra-jenkins) Terraform project to deploy the Jenkins infrastructure.

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
│-- .github/
    ├── workflows/
        ├── build-jenkins-ami.yml
        ├── packer-check.yml
```

### 1. `jenkins/groovy/`
This directory contains Groovy scripts used for automating Jenkins job configurations and setup, credentials, and plugins.

### 2. `jenkins/jcasc.yaml`
This file contains Jenkins Configuration as Code (JCasC) settings for automated configuration management.

### 3. `packer/`
This directory contains the Packer configuration file used to build a Jenkins AMI.
- **`jenkins.pkr.hcl`** - Packer template defining the base image, provisioners, and build configuration for the Jenkins AMI.

### 4. `scripts/`
This directory contains general setup and configuration scripts.
- **`setup.sh`** - Script for setting up and configuring the Jenkins environment, installing dependencies, and additional configurations.

### 5. `.github/workflows/`
This directory contains GitHub Actions workflow files for CI/CD.
- **`packer-check.yml`** - Workflow that validates packer template on pull request.
- **`build-jenkins-ami.yml`** - Workflow that triggers on repository changes to build and register a new AMI.

## Prerequisites

- **AWS Account**: Access to an AWS account with permissions to create AMIs
- **AWS CLI**: Configured with appropriate credentials
- **Packer**: Version 1.8.0+ installed locally for development and testing
- **GitHub Repository**: Connected to GitHub Actions
- **IAM Role/User**: With permissions for:
  - EC2 instance creation
  - AMI registration
  - Security group management
  - Key pair management

## Setup and Usage

### Local Development

1. **Clone the Repository**
   ```sh
   git clone https://github.com/cyse7125-sp25-team03/ami-jenkins.git
   cd ami-jenkins
   ```

2. **Configure AWS Credentials**
   ```sh
   aws configure
   ```

3. **Validate Packer Template**
   ```sh
   cd packer
   packer validate jenkins.pkr.hcl
   ```

4. **Build AMI Locally (Optional)**
   ```sh
   packer build jenkins.pkr.hcl
   ```

### GitHub Actions Setup

1. **Configure AWS Credentials in GitHub Secrets**
   - Navigate to your GitHub repository
   - Go to Settings > Secrets and variables > Actions
   - Add the following secrets:
     - `AWS_ACCESS_KEY_ID`
     - `AWS_SECRET_ACCESS_KEY`
     - `AWS_REGION`

2. **Push Changes to Trigger Build**
   Any push to the main branch will automatically trigger the GitHub Actions workflow, which will:
   - Validate the Packer template
   - Build the AMI
   - Register the AMI in your AWS account
   - Tag the AMI with relevant metadata

## AMI Build Specifications

1. **Source Image**: Ubuntu 24.04 LTS
2. **Private AMI**: The AMI is configured to be private and accessible only to your team
3. **ROOT AWS Account**: All AMI builds are performed in the root AWS account
4. **Default VPC**: The AMI build utilizes the default VPC in your AWS account

## Installed Components

The AMI comes pre-installed with:

- **Jenkins**: Latest LTS version
- **Nginx**: Configured as a reverse proxy for Jenkins
- **Let's Encrypt**: For SSL certificate generation
- **Jenkins Plugins**: Core plugins for CI/CD operations
- **Configuration as Code**: Pre-configured Jenkins setup

## Outputs

- **AMI ID**: A private AMI ID is generated and can be used in Terraform deployments
- **Ready-to-Use**: EC2 instances launched from this AMI will have Jenkins fully configured and ready to use

## Troubleshooting

- **Packer Build Failures**: Check the Packer logs for specific error messages
- **GitHub Actions Failures**: Review the workflow run logs in the Actions tab
- **AMI Visibility Issues**: Verify IAM permissions and AMI sharing settings

## References
- [Packer Documentation](https://www.packer.io/docs)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Jenkins Configuration as Code](https://www.jenkins.io/projects/jcasc/)
- [Nginx Documentation](https://nginx.org/en/docs/)

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.