#S3

#Bucket creation
resource "aws_s3_bucket" "bucket_test" {
  bucket = var.bucket
  tags = {
    project = var.project
  }
}

#Deneying public access to the bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.bucket_test.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#Defining bucket policy
data "aws_iam_policy_document" "allow_objects_access" {
  version = "2012-10-17"
  statement {
    sid    = "1"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "ArnEqualsIfExists"
      variable = "aws:SourceArn"

      values = [aws_cloudfront_distribution.s3_distribution.arn]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket_test.arn}/*"]
  }

  depends_on = [aws_s3_bucket_public_access_block.public_access]
}

#Providing bucket policy to allow access to objects
resource "aws_s3_bucket_policy" "allow_access_to_objects" {
  bucket = aws_s3_bucket.bucket_test.id
  policy = data.aws_iam_policy_document.allow_objects_access.json
}

/*
This method doesnt doesn't set metadata like content-type, and this metadata is important for things like HTTP access from the browser working correctly.
I'm aware of a module that helps with this matter (https://registry.terraform.io/modules/hashicorp/dir/template/latest) 

For the sake of simplicity, I decided to manually upload the files using the AWS console.

#Objects upload
resource "aws_s3_object" "upload" {
    bucket = aws_s3_bucket.bucket_test.id
    for_each = fileset("./cv_IaC_v1","**")
    key = "${each.key}"
    content_type = each.value == "index.html" ? "text/html" : null
    source = "./cv_IaC_v1/${each.value}"
    #https://www.reddit.com/r/Terraform/comments/x1m49t/help_understating_etag_option_from_aws_s3_object/
    etag = filemd5("./cv_IaC_v1/${each.value}")
}
*/

#CloudFront

#Creating CloudFront origin access control
resource "aws_cloudfront_origin_access_control" "demo_origin_access_control" {
  name                              = aws_s3_bucket.bucket_test.id
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

#Fetching certificate information
data "aws_acm_certificate" "issued" {
  #Specifiyng region where the certificate is
  provider = aws.us-east-1
  domain   = "thecodemango.com"
  statuses = ["ISSUED"]
  types    = ["AMAZON_ISSUED"]
}

#Creating CloudFront distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled = true

  origin {
    domain_name              = aws_s3_bucket.bucket_test.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.bucket_test.id
    origin_access_control_id = aws_cloudfront_origin_access_control.demo_origin_access_control.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.bucket_test.id
    #This line is important because of my JavaScript code
    #For details see https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-https-viewers-to-cloudfront.html
    viewer_protocol_policy = "redirect-to-https"

    #Using an aws managed cache policy
    #For more info read https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cache-key-understand-cache-policy.html
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  #Attaching certificate. Required in order to be able to use a custom domain name for the distribution
  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.issued.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  #Custom domain name
  aliases = ["iac.thecodemango.com"]

  is_ipv6_enabled = false

  #Object that you want CloudFront to return when an end user requests the root URL
  default_root_object = "index.html"

  tags = {
    project = var.project
  }
}

#Route53

#Fetching information of existing hosted zone
data "aws_route53_zone" "selected" {
  name = "thecodemango.com"
}

#Creating an A (Alias) record for the CloudFront distribution
resource "aws_route53_record" "iac_a_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "iac"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

#DynamoDB

#Creating table
resource "aws_dynamodb_table" "iac_table" {
  name         = "iac-counter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "countID"

  attribute {
    name = "countID"
    type = "N"
  }

  tags = {
    project = var.project
  }
}

# # Extra # #

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
    actions = ["dynamodb:DescribeTable", "dynamodb:GetItem",
    "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:DescribeContinuousBackups" ]
    resources = [data.aws_dynamodb_table.state-locking.arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["dynamodb:DescribeTable", "dynamodb:GetItem",
    "dynamodb:PutItem"]
    resources = [ aws_dynamodb_table.iac_table.arn ]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:GetRole"]
    resources = [ "*" ]
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

resource "aws_iam_role_policy_attachment" "github_perm_policy_attach" {
  role       = aws_iam_role.github_role.name
  policy_arn = aws_iam_policy.github_perm_policy.arn
}

output "TEST" {
  value = aws_s3_bucket.bucket_test.arn
}