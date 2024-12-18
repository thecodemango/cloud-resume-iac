#Crating OIDC provider for github actions
resource "aws_iam_openid_connect_provider" "default" {
  url = "https://token.actions.githubusercontent.com"

  #Audience
  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = ["D89E3BD43D5D909B47A18977AA9D5CE36CEE184C"]

  tags = {
    project = var.project
  }
}

#Trsut policy for the role for the IdP (identity provider)
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.default.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = ["repo:thecodemango/cloud-resume-iac:ref:refs/heads/master"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = ["sts.amazonaws.com"]
    }
  }
}

#Fetching data about state-locking table
data "aws_dynamodb_table" "state-locking" {
  name = "state-locking"
}

#Fetching dta about state S3 bucket
data "aws_s3_bucket" "state_bucket" {
  bucket = "cloud-resume-tf-state-bucket"
}

#Defining permission policy for role for github actions
data "aws_iam_policy_document" "github_perm_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.bucket_test.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${data.aws_s3_bucket.state_bucket.arn}/v1/terraform.tfstate"]
  }
  
  statement {
    effect = "Allow"
    actions = ["dynamodb:*"]
    resources = [data.aws_dynamodb_table.state-locking.arn]
  }
  ##############################################################
  statement {
    effect    = "Allow"
    actions   = ["lambda:*", "cloudfront:*", "cloudwatch:*", "apigateway:*","acm:*"]
    resources = [ "*" ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/project"

      values = ["${var.project}"]
    }
  }
}

#Creating permissions policy
resource "aws_iam_policy" "github_perm_policy" {
  name        = "github_perm_policy"
  description = "Policy for github actions to acces terraform rsources (s3, dynamodb)"
  policy      = data.aws_iam_policy_document.github_perm_policy_doc.json
}

#Attaching trust policy to role for github Actions
resource "aws_iam_role" "github_role" {
  name               = "GitHubAction-AssumeRoleWithAction"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

#Attaching permission policy to role for github Actions
resource "aws_iam_role_policy_attachment" "github_perm_policy_attach" {
  role       = aws_iam_role.github_role.name
  policy_arn = aws_iam_policy.github_perm_policy.arn
}

output "TEST" {
  value = aws_s3_bucket.bucket_test.arn
}