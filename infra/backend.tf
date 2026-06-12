terraform {
  backend "s3" {
    bucket         = "microsoft-project-tfstate-bucket"
    key            = "bluegreen/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}