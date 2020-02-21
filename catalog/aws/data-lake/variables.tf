variable "name_prefix" { type = string }
variable "aws_region" { default = null }
variable "resource_tags" {
  type    = map
  default = {}
}
variable "lambda_python_source" {
  description = "Local path to a folder containing the lambda source code"
  type        = string
  default     = "resources/fn_log"
}
# variable "lambda_python_dependency_urls" {
#   type    = map(string)
#   default = {}
# }
variable "s3_triggers" {
  type = map(object({
    # function_name       = string
    triggering_path     = string
    function_handler    = string
    environment_vars    = map(string)
    environment_secrets = map(string)
  }))
  default = {
    "fn_log" = {
      # function_name       = "fn_log"
      triggering_path     = "*"
      function_handler    = "main.lambda_handler"
      environment_vars    = {}
      environment_secrets = {}
    }
  }
}
