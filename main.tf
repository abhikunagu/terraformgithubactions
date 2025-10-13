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
 cidr_block = "10.30.0.0/16"
}

resource "aws_instance" "devops_server" {
  ami           = "ami-04b4f1a9cf54c11d0"
  instance_type = "t2.micro"
  count         = 10

  tags = {
    Name = "DEVOPS"
  }
}
