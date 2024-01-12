
variable "certificatedomain" {
  description = "Domain for SSL"
}

variable "DomainName" {
  description = "The website domain name CF is listening for"
}

variable "DomainNameDashes" {
  description = "The domain name with dashes instead of dots"
}

variable "LogRetention" {
  description = "The retention time for logs in days"
  default     = 14
}

variable "WAF" {
  description = "Enable Reece IP address whitelist WAF (WebACL to only allow whitelisted Reece IP addresses)"
  default     = "yes"
}

variable "StackNameDashes" {
  description = "The domain name with dashes instead of dots"
}

variable "Subject" {
  description = "Contact us email subject"
}

variable "ToEmailAddress" {
  description = "Email address you want contact form submissions to go to"
}

variable "FromEmailAddress" {
  description = "Email address you want contact form submissions to come from"
}

variable "ReplyToEmailAddress" {
  description = "Reply to email address"
}

variable "ReCaptchaSecret" {
  description = "Your Google reCAPTCHA secret"
}

variable "stage" {
  type        = string
  description = "Define API-Gateway stage"
}

variable "domain" {
  type        = string
  description = "Domain for the email addresses"
}

#variable "create_env_zone" {
#  type = bool
#  default = false
#}
