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
  type = string
}

variable "instance_type" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "ssh_username" {
  type = string
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
    script = "scripts/setup.sh"
  }
}