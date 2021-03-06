module "core_lambda" {
  source        = "../../../components/aws/lambda-python"
  name_prefix   = "${var.name_prefix}core-"
  resource_tags = var.resource_tags
  environment   = var.environment

  runtime              = "python3.8"
  lambda_source_folder = "${path.module}/lambda-python/core-model"
  s3_upload_path       = "s3://${aws_s3_bucket.ml_bucket[0].id}/ml-lambda/"

  functions = {
    QueryTrainingStatus = {
      description = "Queries the SageMaker training job and return the results."
      handler     = "query_training_status.lambda_handler"
      environment = { "metadata_store_name" = aws_s3_bucket.ml_bucket[0].id }
      secrets     = {}
    }
    ExtractModelPath = {
      description = "Queries the SageMaker model to return the model path."
      handler     = "extract_model_path.lambda_handler"
      environment = {}
      secrets     = {}
    }
    CheckEndpointExists = {
      description = "Queries if endpoint exists to determine create or update job."
      handler     = "check_endpoint_exists.lambda_handler"
      environment = {}
      secrets     = {}
    }
    DataDriftMonitor = {
      description = "Monitor data drift on input data."
      handler     = "data_drift_monitor.lambda_handler"
      environment = {}
      secrets     = {}
    }
    ModelPerformanceMonitor = {
      description = "Monitor model performance for any degradation issues."
      handler     = "model_performance_monitor.lambda_handler"
      environment = {}
      secrets     = {}
    }
    UniqueJobName = {
      description = "Creates a unique identifier for the hyperparameter tuning job."
      handler     = "unique_job_name.lambda_handler"
      environment = {}
      secrets     = {}
    }
    RenameBatchOutput = {
      description = "Renames batch transform output to .csv extension for Athena connection."
      handler     = "rename_batch_output.lambda_handler"
      environment = {}
      secrets     = {}
    }
    RunGlueCrawler = {
      description = "Runs Glue Crawler to create table of batch transformation output for Athena."
      handler     = "run_glue_crawler.lambda_handler"
      environment = {}
      secrets     = {}
    }
  }
}

module "drift_detection_lambda" {
  source        = "../../../components/aws/lambda-python"
  name_prefix   = "${var.name_prefix}drift-"
  resource_tags = var.resource_tags
  environment   = var.environment

  runtime              = "python3.8"
  lambda_source_folder = "${path.module}/lambda-python/drift-detection"
  s3_upload_path       = "s3://${aws_s3_bucket.ml_bucket[0].id}/ml-lambda/"

  functions = {
    CloudWatchAlarm = {
      description = "Send developers an email alarm when the model is overfitting."
      handler     = "clodwatch_alarm.lambda_handler"
      environment = {}
      secrets     = {}
    }
    LoadPredDataDB = {
      description = "Load prediction outputs csv file to a selected database."
      handler     = "load_predoutput_db.lambda_handler"
      environment = {}
      secrets     = {}
    }
    ModelPerformanceMonitor = {
      description = "Monitor model performance for any degradation issues."
      handler     = "model_performance_monitor.lambda_handler"
      environment = {}
      secrets     = {}
    }
    ProblemType = {
      description = "Determine the type of machine learning problem."
      handler     = "determine_prob_type.lambda_handler"
      environment = {}
      secrets     = {}
    }
    SNSAlert = {
      description = "Send an SNS email to users notifying data drift being detected."
      handler     = "sns_alert.lambda_handler"
      environment = {}
      secrets     = {}
    }
    StopTraining = {
      description = "Stop the model training."
      handler     = "stop_training.lambda_handler"
      environment = {}
      secrets     = {}
    }
  }
}

module "triggered_lambda" {
  source        = "../../../components/aws/lambda-python"
  name_prefix   = "${var.name_prefix}s3-"
  resource_tags = var.resource_tags
  environment   = var.environment

  runtime              = "python3.8"
  lambda_source_folder = "${path.module}/lambda-python/s3-triggered"
  s3_upload_path       = "s3://${aws_s3_bucket.ml_bucket[0].id}/s3-triggered-lambda/"

  functions = {
    ExecuteStateMachine = {
      description = "Executes model training state machine when new training data lands in S3."
      handler     = "execute_state_machine.lambda_handler"
      environment = { "state_machine_arn" = module.training_workflow.state_machine_arn }
      secrets     = {}
    }
  }
  s3_triggers = [
    {
      function_name = "ExecuteStateMachine"
      s3_bucket     = var.ml_bucket_override != null ? data.aws_s3_bucket.ml_bucket_override[0].id : aws_s3_bucket.ml_bucket[0].id
      s3_path       = "data/train/*"
    }
  ]
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.name_prefix}lambda_policy"
  description = "Policy for Lambda functions"
  path        = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sagemaker:Describe*",
                "sagemaker:List*",
                "sagemaker:BatchGetMetrics",
                "sagemaker:GetSearchSuggestions",
                "sagemaker:Search",
                "s3:*",
                "rds-db:connect",
                "glue:StartCrawler"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_core" {
  role       = module.core_lambda.lambda_iam_role
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment_drift" {
  role       = module.drift_detection_lambda.lambda_iam_role
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_policy" "lambda_step_function_policy" {
  name        = "${var.name_prefix}lambda_sfn_access"
  description = "Policy for Lambda access to execute the training job Step Function"
  path        = "/"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "states:StartExecution",
            "Resource": ${jsonencode([module.training_workflow.state_machine_arn])}
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_step_functions_policy_attachment" {
  role       = module.triggered_lambda.lambda_iam_role
  policy_arn = aws_iam_policy.lambda_step_function_policy.arn
}
