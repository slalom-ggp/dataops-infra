module "step-functions" {
  #source                  = "git::https://github.com/slalom-ggp/dataops-infra.git//catalog/aws/data-lake?ref=master"
  source                   = "../../../components/aws/step-functions"
  name_prefix              = var.name_prefix
  s3_bucket_name           = var.s3_bucket_name
  environment              = var.environment
  resource_tags            = var.resource_tags
  state_machine_definition = <<EOF
{
 "StartAt": "Generate Unique Job Name",
  "States": {
    "Generate Unique Job Name": {
      "Resource": "arn:aws:lambda:us-east-1:954496255132:function:UniqueJobName",
      "Parameters": {
        "JobName": "customerchurn"
      },
      "Type": "Task",
      "Next": "Hyperparameter Tuning"
    },
    "Hyperparameter Tuning": {
      "Resource": "arn:aws:states:::sagemaker:createHyperParameterTuningJob.sync",
      "Parameters": {
        "HyperParameterTuningJobName.$": "$.JobName",
        "HyperParameterTuningJobConfig": {
          "Strategy": "Bayesian",
          "HyperParameterTuningJobObjective": {
            "Type": "Minimize",
            "MetricName": "validation:error"
          },
          "ResourceLimits": {
            "MaxNumberOfTrainingJobs": 2,
            "MaxParallelTrainingJobs": 2
          },
          "ParameterRanges": {
            "ContinuousParameterRanges": [
              {
                "Name": "eta",
                "MinValue": "0.1",
                "MaxValue": "0.5",
                "ScalingType": "Auto"
              },
              {
                "Name": "min_child_weight",
                "MinValue": "5",
                "MaxValue": "100",
                "ScalingType": "Auto"
              },
              {
                "Name": "subsample",
                "MinValue": "0.1",
                "MaxValue": "0.5",
                "ScalingType": "Auto"
              },
              {
                "Name": "gamma",
                "MinValue": "0",
                "MaxValue": "5",
                "ScalingType": "Auto"
              }
            ],
            "IntegerParameterRanges": [
              {
                "Name": "max_depth",
                "MinValue": "0",
                "MaxValue": "10",
                "ScalingType": "Auto"
              }
            ]
          }
        },
        "TrainingJobDefinition": {
          "AlgorithmSpecification": {
            "TrainingImage": "811284229777.dkr.ecr.us-east-1.amazonaws.com/xgboost:1",
            "TrainingInputMode": "File"
          },
          "OutputDataConfig": {
            "S3OutputPath": "s3://${var.s3_bucket_name}/output"
          },
          "StoppingCondition": {
            "MaxRuntimeInSeconds": 86400
          },
          "ResourceConfig": {
            "InstanceCount": 1,
            "InstanceType": "ml.m5.xlarge",
            "VolumeSizeInGB": 30
          },
          "RoleArn": "arn:aws:iam::954496255132:role/StepFunctionsMLOpsRole",
          "InputDataConfig": [
            {
              "DataSource": {
                "S3DataSource": {
                  "S3DataDistributionType": "FullyReplicated",
                  "S3DataType": "S3Prefix",
                  "S3Uri": "s3://${var.s3_bucket_name}/data/train/train.csv"
                }
              },
              "ChannelName": "train",
              "ContentType": "csv"
            },
            {
              "DataSource": {
                "S3DataSource": {
                  "S3DataDistributionType": "FullyReplicated",
                  "S3DataType": "S3Prefix",
                  "S3Uri": "s3://${var.s3_bucket_name}/data/validation/validation.csv"
                }
              },
              "ChannelName": "validation",
              "ContentType": "csv"
            }
          ],
          "StaticHyperParameters": {
            "precision_dtype": "float32",
            "num_round": "100"
          }
        }
      },
      "Type": "Task",
      "Next": "Extract Best Model Path"
    },
    "Extract Best Model Path": {
      "Resource": "arn:aws:lambda:us-east-1:954496255132:function:ExtractModelPath",
      "Type": "Task",
      "Next": "Save Best Model"
    },
    "Save Best Model": {
      "Parameters": {
        "PrimaryContainer": {
          "Image": "811284229777.dkr.ecr.us-east-1.amazonaws.com/xgboost:1",
          "Environment": {},
          "ModelDataUrl.$": "$.modelDataUrl"
        },
        "ExecutionRoleArn": "arn:aws:iam::954496255132:role/StepFunctionsMLOpsRole",
        "ModelName.$": "$.bestTrainingJobName"
      },
      "Resource": "arn:aws:states:::sagemaker:createModel",
      "Type": "Task",
      "Next": "Extract Model Name"
    },
    "Extract Model Name": {
      "Resource": "arn:aws:lambda:us-east-1:954496255132:function:ExtractModelName",
      "Type": "Task",
      "Next": "Query Training Results"
    },
    "Query Training Results": {
      "Resource": "arn:aws:lambda:us-east-1:954496255132:function:QueryTrainingStatus",
      "Type": "Task",
      "Next": "Endpoint Rule"
    },
    "Endpoint Rule": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$['trainingMetrics'][0]['Value']",
          "NumericLessThan": 0.2,
          "Next": "Create Model Endpoint Config"
        }
      ],
      "Default": "Model Accuracy Too Low"
    },
    "Model Accuracy Too Low": {
      "Comment": "Validation accuracy lower than threshold",
      "Type": "Fail"
    },
    "Create Model Endpoint Config": {
      "Resource": "arn:aws:states:::sagemaker:createEndpointConfig",
      "Parameters": {
        "EndpointConfigName.$": "$.modelName",
        "ProductionVariants": [
          {
            "InitialInstanceCount": 1,
            "InstanceType": "ml.m4.xlarge",
            "ModelName.$": "$.modelName",
            "VariantName": "AllTraffic"
          }
        ]
      },
      "Type": "Task",
      "Next": "Extract Endpoint Config Name"
    },
    "Extract Endpoint Config Name": {
      "Resource": "arn:aws:lambda:us-east-1:954496255132:function:ExtractModelName",
      "Type": "Task",
      "Next": "Check Endpoint Exists"
    },
    "Check Endpoint Exists": {
      "Resource": "arn:aws:lambda:us-east-1:954496255132:function:CheckEndpointExists",
      "Parameters": {
        "EndpointConfig.$": "$.modelName",
        "EndpointName": "customerchurn-089-001-bf391ccb"
      },
      "Type": "Task",
      "Next": "Create or Update Endpoint"
    },
    "Create or Update Endpoint": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$['CreateOrUpdate']",
          "StringEquals": "Update",
          "Next": "Update Existing Model Endpoint"
        }
      ],
      "Default": "Create New Model Endpoint"
    },
    "Create New Model Endpoint": {
      "Resource": "arn:aws:states:::sagemaker:createEndpoint",
      "Parameters": {
        "EndpointConfigName.$": "$.endpointConfig",
        "EndpointName.$": "$.endpointName"
      },
      "Type": "Task",
      "End": true
    },
    "Update Existing Model Endpoint": {
      "Resource": "arn:aws:states:::sagemaker:updateEndpoint",
      "Parameters": {
        "EndpointConfigName.$": "$.endpointConfig",
        "EndpointName.$": "$.endpointName"
      },
      "Type": "Task",
      "End": true
    }
  }
}
EOF
}