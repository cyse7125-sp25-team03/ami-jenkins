packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0, <2.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_source_ami" {
  type = string
}

variable "ami_name" {
  type    = string
  default = "jenkins-ami"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "jenkins_admin_username" {
  type = string
}

variable "jenkins_admin_password" {
  type      = string
  sensitive = true
}

variable "github_username" {
  type = string
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "github_id" {
  type = string
}

variable "github_description" {
  type    = string
  default = "GitHub Personal Access Token"
}

variable "docker_username" {
  type = string
}

variable "docker_token" {
  type      = string
  sensitive = true
}

variable "docker_id" {
  type = string
}

variable "docker_description" {
  type    = string
  default = "Docker Personal Access Token"
}

source "amazon-ebs" "ubuntu" {
  ami_name        = "${var.ami_name}-${formatdate("YYYY_MM_DD_HHmmss", timestamp())}"
  instance_type   = var.instance_type
  region          = var.aws_region
  source_ami      = var.aws_source_ami
  ssh_username    = var.ssh_username
  ami_description = "AMI for setting up Jenkins"

  tags = {
    Name    = "Jenkins AMI"
    Builder = "Packer"
  }

  vpc_filter {
    filters = {
      "isDefault" : "true"
    }
  }

  ami_users = []
}

build {
  name = "jenkins-ami"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    inline = ["sudo mkdir -p /tmp/jenkins", "sudo chmod 777 /tmp/jenkins"]
  }


  provisioner "file" {
    source      = "./jenkins/"
    destination = "/tmp/jenkins"
  }

  provisioner "shell" {
    environment_vars = [
      "JENKINS_ADMIN_USERNAME=${var.jenkins_admin_username}",
      "JENKINS_ADMIN_PASSWORD=${var.jenkins_admin_password}",
      "GITHUB_USERNAME=${var.github_username}",
      "GITHUB_TOKEN=${var.github_token}",
      "GITHUB_ID=${var.github_id}",
      "GITHUB_DESCRIPTION=${var.github_description}",
      "DOCKER_USERNAME=${var.docker_username}",
      "DOCKER_TOKEN=${var.docker_token}",
      "DOCKER_ID=${var.docker_id}",
      "DOCKER_DESCRIPTION=${var.docker_description}"
    ]
    script = "scripts/setup.sh"
  }
}