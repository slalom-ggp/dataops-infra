locals {
  function_name = "${var.name_prefix}${var.function_name}"
}

resource "aws_lambda_function" "python_lambda" {
  filename         = var.lambda_fn_zip
  function_name    = local.function_name
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "exports.test"
  runtime          = var.runtime
  source_code_hash = filebase64sha256(var.lambda_fn_zip)
  environment {
    variables = var.environment_vars
  }
  depends_on    = ["aws_iam_role_policy_attachment.lambda_logs", "aws_cloudwatch_log_group.example"]
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${local.function_name}"
  # retention_in_days = 14
}

resource "aws_lambda_layer_version" "python_requirements_layer" {
  filename            = "${var.name_prefix}requirements.zip"
  layer_name          = "${var.name_prefix}requirements"
  compatible_runtimes = [var.runtime]
}
