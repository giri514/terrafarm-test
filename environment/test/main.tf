terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
 shared_credentials_files = [var.aws_credentials_file]
  profile                  = var.aws_credentials_profile
}

##################################
#  Kadenair contactus           #
##################################
module "kadenair" {
  source              = "../../modules/kadenair" # Update with the correct path to your module#
  DomainName          = "torchtest.aress.net"
  DomainNameDashes    = "cf-dev-kadenair-xxx-com"
  Subject             = "Contact us email subject"
  ToEmailAddress      = "${var.ToEmailAddress}"
  FromEmailAddress    = "${var.FromEmailAddress}"
  ReplyToEmailAddress = "${var.ReplyToEmailAddress}"
  ReCaptchaSecret     = "6Lc1tTYpAAAAAKcb54fJttqZRpadRIRXJtM4grle"
  environment        = local.environment
  domain              = "torchtest.aress.net"
  certificatedomain   = "torchtest.aress.net"
  StackNameDashes     = "cf-dev-kadenair-xxx-com-contact-us"
  stage               = "dev"
}

