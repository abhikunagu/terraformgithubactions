terraform {
 required_providers {
   aws = {
     source  = "hashicorp/aws"
     version = "5.50.0"
   }
  
  }
}


provider "aws" {
 region = "us-east-1"
}

resource "aws_vpc" "this" {
 cidr_block = "10.31.0.0/16"
}

resource "aws_instance" "devops_server" {
  ami           = "ami-04b4f1a9cf54c11d0"
  instance_type = "t2.micro"
  count         = 1

  tags = {
    Name = "DEVOPS"
  }
}

# AWS ECR Repository
resource "aws_ecr_repository" "devops_ecr" {
  name                 = "devops-ecr-repo1"
  image_tag_mutability = "MUTABLE"
  tags = {
    Environment = "DevOps"
  }
}

# AWS S3 Bucket
resource "aws_s3_bucket" "devuserbucket" {
  bucket = "my-tf-test-bucketnewone1"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

##############################################################################################

