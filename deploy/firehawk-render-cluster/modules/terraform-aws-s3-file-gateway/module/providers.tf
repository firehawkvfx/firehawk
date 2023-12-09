terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # version = "~> 3.8"
      version = "~> 4.4.0" # previously aws = "~> 3.8
    }
  }

  required_version = ">= 1.1.7, <= 1.5.6"
}
