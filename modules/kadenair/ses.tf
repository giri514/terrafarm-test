# SES domain
resource "aws_ses_domain_identity" "ms" {
  domain = var.domain
}

resource "aws_ses_email_identity" "email" {
  email = var.FromEmailAddress
}
resource "aws_ses_email_identity" "Toemail" {
  email = var.ToEmailAddress
}

data "aws_iam_policy_document" "policy_for_email" {
  statement {
    actions   = ["SES:SendEmail", "SES:SendRawEmail"]
    resources = [aws_ses_email_identity.email.arn]
      principals {
      identifiers = [
        join("", ["arn:aws:sts::", data.aws_caller_identity.current.account_id, ":assumed-role/", aws_iam_role.IamRoleLambdaExecution.name, "/", aws_lambda_function.ContactUsFunction.function_name])
      ]

      type        = "AWS"
    }
}
}

data "aws_iam_policy_document" "policy_for_Toemail" {
  statement {
    actions   = ["SES:SendEmail", "SES:SendRawEmail"]
    resources = [aws_ses_email_identity.Toemail.arn]
      principals {
      identifiers = [
        join("", ["arn:aws:sts::", data.aws_caller_identity.current.account_id, ":assumed-role/", aws_iam_role.IamRoleLambdaExecution.name, "/", aws_lambda_function.ContactUsFunction.function_name])
      ]

      type        = "AWS"
    }
}
}

resource "aws_ses_identity_policy" "authorizationpolicy_for_email" {
  identity = aws_ses_email_identity.email.arn
  name     = "PolicyForEmail"
  policy   = data.aws_iam_policy_document.policy_for_email.json
}

resource "aws_ses_identity_policy" "authorizationpolicy_for_Toemail" {
  identity = aws_ses_email_identity.Toemail.arn
  name     = "PolicyForToemail"
  policy   = data.aws_iam_policy_document.policy_for_Toemail.json
}
