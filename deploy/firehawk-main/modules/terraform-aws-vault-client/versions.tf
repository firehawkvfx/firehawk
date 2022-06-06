terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.6.0"
    }
    null = {
      source = "hashicorp/null"
      version = "~> 3.0"
    }
  }
  required_version = ">= 0.13"
}
