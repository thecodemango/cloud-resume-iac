#I'm using this data source to get my account ID and use it in a policy document
data "aws_caller_identity" "current" {}

#Configuration for Lambda functions

#Trsut policy for the roles of both lambada functions
data "aws_iam_policy_document" "iac_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#Configuration for the lambda put_count function

#Creation of a role for the function and attaching the assume role policy (trust policy)
resource "aws_iam_role" "role_for_lambda_put" {
  name               = "iac_put_count_item_role"
  assume_role_policy = data.aws_iam_policy_document.iac_trust_policy.json
  tags = {
    project : var.project
  }
}

#Definition of the permission policy 
data "aws_iam_policy_document" "iac_put_policy_doc" {
  version = "2012-10-17"
  statement {
    sid       = "1"
    effect    = "Allow"
    actions   = ["dynamodb:PutItem", "dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.iac_table.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:ca-central-1:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.lambda_put_log.arn}:*"]
  }
}

#Creation of the permission policy
resource "aws_iam_policy" "iac_put_policy" {
  name   = "iac_put_policy"
  policy = data.aws_iam_policy_document.iac_put_policy_doc.json
}

#Attaching the permission policy to the role for the function
resource "aws_iam_role_policy_attachment" "put_attach" {
  role       = aws_iam_role.role_for_lambda_put.name
  policy_arn = aws_iam_policy.iac_put_policy.arn
}

#Packaging the python code for the function
data "archive_file" "lambda_put" {
  type        = "zip"
  source_file = "${path.module}/src/put_item.py"
  output_path = "lambda_put.zip"
}

#Creation of the function
resource "aws_lambda_function" "lambda_put" {
  filename      = data.archive_file.lambda_put.output_path
  function_name = "iac_put_count_item"
  role          = aws_iam_role.role_for_lambda_put.arn
  runtime       = "python3.11"
  handler       = "put_item.lambda_handler"
  tags = {
    project = var.project
  }
}

#Creation of CloudWatch log group. The python code for the function contains logging configuration
resource "aws_cloudwatch_log_group" "lambda_put_log" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_put.function_name}"
  retention_in_days = 0
  tags = {
    project = var.project
  }
}

#Configuration for the lambda put_item function

/** The configuration that follows is basically the same as the configuration for the put_item function but with
values modified to match the get_item function configuration including a different permission policy, different
python file and a different log group for CloudWatch **/

resource "aws_iam_role" "role_for_lambda_get" {
  name               = "iac_get_count_item_role"
  assume_role_policy = data.aws_iam_policy_document.iac_trust_policy.json
  tags = {
    project : var.project
  }
}

data "aws_iam_policy_document" "iac_get_policy_doc" {
  version = "2012-10-17"
  statement {
    sid       = "1"
    effect    = "Allow"
    actions   = ["dynamodb:BatchGetItem", "dynamodb:GetItem", "dynamodb:Query", "dynamodb:Scan"]
    resources = [aws_dynamodb_table.iac_table.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:ca-central-1:${data.aws_caller_identity.current.account_id}:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.lambda_get_log.arn}:*"]
  }
}

resource "aws_iam_policy" "iac_get_policy" {
  name   = "iac_get_policy"
  policy = data.aws_iam_policy_document.iac_get_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "get_attach" {
  role       = aws_iam_role.role_for_lambda_get.name
  policy_arn = aws_iam_policy.iac_get_policy.arn
}

data "archive_file" "lambda_get" {
  type        = "zip"
  source_file = "${path.module}/src/get_item.py"
  output_path = "lambda_get.zip"
}

resource "aws_lambda_function" "lambda_get" {
  filename      = data.archive_file.lambda_get.output_path
  function_name = "iac_get_count_item"
  role          = aws_iam_role.role_for_lambda_get.arn
  runtime       = "python3.11"
  handler       = "get_item.lambda_handler"
  tags = {
    project = var.project
  }
}

resource "aws_cloudwatch_log_group" "lambda_get_log" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_get.function_name}"
  retention_in_days = 0
  tags = {
    project = var.project
  }
}