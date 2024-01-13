variable "aws_credentials_file" {
  type        = string
  description = "The path to where the credentials are stored when running `aws configure`."
  default     = "$HOME/.aws/credentials"
}

variable "aws_credentials_profile" {
  type        = string
  description = "The profile configured when running `aws configure`."
  default     = "" # Leave blank. Terraform will use "default" unless a shell environment variable for AWS_PROFILE is set.
}

variable "ToEmailAddress"{
  type        = string
  description = "email addresses"
  default = "somnath.kadam@aress.com"
}

variable "FromEmailAddress"{
  type        = string
  description = "email addresses"
  default = "somnath.kadam@aress.com"
}


variable "ReplyToEmailAddress"{
  type        = string
  description = "email addresses"
  default = "somnath.kadam@aress.com"
}
