terraform {
 required_providers {
  aws = {
   source = "hashicorp/aws"
  }
  docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
  }
  kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.7.0"
  }
 }
}
provider "aws" {
  region = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}
provider "kubernetes" {
  config_path = "~/.kube/config"  # Path to your Kubernetes configuration file
}
