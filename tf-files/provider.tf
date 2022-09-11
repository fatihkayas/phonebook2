terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }

  }
}
 provider "aws" {
   
   region: = "us-esat-1"
 }


# Configure the GitHub Provider
provider "github" {
    token = "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"    
}