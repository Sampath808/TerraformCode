provider "aws" {
  region = "ap-south-1"
  profile = "terraform-user"
}

data "aws_s3_bucket" "lambda_bucket" {
  bucket = "lambda-jar-bucket-v1"
}

# IAM Role for Lambda execution
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"
  
  # Trust policy allowing Lambda service to assume this role
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

# IAM Role Policy to allow CloudWatch logging
resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id
  
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*"
      }
    ]
  }
  EOF
}


resource "aws_lambda_function" "spring_boot_lambda" {
  function_name = "mySecondFunction"
  handler       = "com.ecommerce.react_application_spring.handler.StreamLambdaHandler::handleRequest"
  runtime       = "java21"
  role          = aws_iam_role.lambda_role.arn
  s3_bucket     = data.aws_s3_bucket.lambda_bucket.bucket
  s3_key        = "react-application-spring-0.0.1-SNAPSHOT.jar"
  memory_size   = 512
  timeout       = 30
}
