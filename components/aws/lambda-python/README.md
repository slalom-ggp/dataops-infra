
# AWS Lambda-Python

`/components/aws/lambda-python`

## Overview


AWS Lambda is a platform which enables serverless execution of arbitrary functions. This module specifically focuses on the
Python implementatin of Lambda functions. Given a path to a folder of one or more python fyles, this module takes care of
packaging the python code into a zip and uploading to a new Lambda Function in AWS. The module can also be configured with
S3-based triggers, to run the function automatically whenever a file is landed in a specific S3 path.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| environment | Standard `environment` module input. | <pre>object({<br>    vpc_id          = string<br>    aws_region      = string<br>    public_subnets  = list(string)<br>    private_subnets = list(string)<br>  })</pre> | n/a | yes |
| functions | A map of function names to create and an object with properties describing the function.<br><br>Example:   functions = [     "fn\_log" = {       description = "Add an entry to the log whenever a file is created."       handler     = "main.lambda\_handler"       environment = {}       secrets     = {}     }   ] | <pre>map(object({<br>    description = string<br>    handler     = string<br>    environment = map(string)<br>    secrets     = map(string)<br>  }))</pre> | n/a | yes |
| name\_prefix | Standard `name_prefix` module input. | `string` | n/a | yes |
| resource\_tags | Standard `resource_tags` module input. | `map(string)` | n/a | yes |
| s3\_trigger\_bucket | The name of an S3 bucket which will trigger this Lambda function. | `string` | n/a | yes |
| s3\_triggers | A list of objects describing the S3 trigger action.<br><br>Example:   s3\_triggers = [     {       function\_name = "fn\_log"       s3\_bucket     = "\*"       s3\_path       = "\*"     }   ] | <pre>list(object({<br>    function_name = string<br>    s3_bucket     = string<br>    s3_path       = string<br>  }))</pre> | n/a | yes |
| upload\_to\_s3 | True to upload source code to S3, False to upload inline with the Lambda function. | `bool` | n/a | yes |
| upload\_to\_s3\_path | S3 Path to where the source code zip should be uploaded.<br>Use in combination with: `upload_to_s3 = true` | `string` | n/a | yes |
| lambda\_source\_folder | Local path to a folder containing the lambda source code. | `string` | `"resources/fn_log"` | no |
| pip\_path | The path to a local pip executable, used to package python dependencies. | `string` | `"pip3"` | no |
| runtime | The python runtime, e.g. `python3.8`. | `string` | `"python3.8"` | no |
| timeout\_seconds | The amount of time which can pass before the function will timeout and fail execution. | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| build\_temp\_dir | Full path to the local folder used to build the python package. |
| function\_ids | A map of function names to the unique function ID (ARN). |
| lambda\_iam\_role | The IAM role used by the lambda function to access resources. Can be used to grant<br>additional permissions to the role. |

---------------------

## Source Files

_Source code for this module is available using the links below._

* [iam.tf](https://github.com/slalom-ggp/dataops-infra/tree/master//components/aws/lambda-python/iam.tf)
* [main.tf](https://github.com/slalom-ggp/dataops-infra/tree/master//components/aws/lambda-python/main.tf)
* [outputs.tf](https://github.com/slalom-ggp/dataops-infra/tree/master//components/aws/lambda-python/outputs.tf)
* [python-zip.tf](https://github.com/slalom-ggp/dataops-infra/tree/master//components/aws/lambda-python/python-zip.tf)
* [variables.tf](https://github.com/slalom-ggp/dataops-infra/tree/master//components/aws/lambda-python/variables.tf)

---------------------

_**NOTE:** This documentation was auto-generated using
`terraform-docs` and `s-infra` from `slalom.dataops`.
Please do not attempt to manually update this file._
