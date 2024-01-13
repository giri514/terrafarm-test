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
}

##################################
#  Kadenair contactus           #
##################################
module "kadenair" {
  source              = "../../modules/kadenair" # Update with the correct path to your module#
  DomainName          = "torchtest.aress.net"
  DomainNameDashes    = "cf-dev-kadenair-web-com"
  Subject             = "Contact us email subject"
  ToEmailAddress      = "${var.ToEmailAddress}"
  FromEmailAddress    = "${var.FromEmailAddress}"
  ReplyToEmailAddress = "${var.ReplyToEmailAddress}"
  ReCaptchaSecret     = "6Lc1tTYpAAAAAKcb54fJttqZRpadRIRXJtM4grle"
  domain              = "torchtest.aress.net"
  certificatedomain   = "torchtest.aress.net"
  StackNameDashes     = "cf-dev-kadenair-web-com-contact-us"
  stage               = "dev"
}

