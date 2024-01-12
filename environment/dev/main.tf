##################################
#  Kadenair contactus           #
##################################
module "kadenair" {
  source              = "../../modules/kadenair" # Update with the correct path to your module#
  DomainName          = "torchtest.aress.net"
  DomainNameDashes    = "cf-dev-kadenair-w-com"
  Subject             = "Contact us email subject"
  ToEmailAddress      = "${var.ToEmailAddress}"
  FromEmailAddress    = "${var.FromEmailAddress}"
  ReplyToEmailAddress = "${var.ReplyToEmailAddress}"
  ReCaptchaSecret     = "6Lc1tTYpAAAAAKcb54fJttqZRpadRIRXJtM4grle"
  domain              = "torchtest.aress.net"
  certificatedomain   = "torchtest.aress.net"
  StackNameDashes     = "cf-dev-kadenair-w-com-contact-us"
  stage               = "dev"
}
