terraform {
  backend "s3" {
    bucket         = "terrastatekade"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
