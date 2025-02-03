#Crating OIDC provider for GitHub Actions
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

#Creating permissions policy
resource "aws_iam_policy" "github_perm_policy" {
  name        = "github_perm_policy"
  description = "Policy for GitHub Actions to acces terraform rsources (s3, dynamodb)"
  policy      = data.aws_iam_policy_document.github_perm_policy_doc.json
}

#Attaching trust policy to role for GitHub Actions
resource "aws_iam_role" "github_role" {
  name               = "GitHubAction-AssumeRoleWithAction"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

#Attaching permission policy to role for GitHub Actions
resource "aws_iam_role_policy_attachment" "github_perm_policy_attach" {
  role       = aws_iam_role.github_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}