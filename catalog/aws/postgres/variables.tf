##############################################
### Standard variables for all AWS modules ###
##############################################

variable "name_prefix" {
  description = "Standard `name_prefix` module input. (Prefix counts towards 64-character max length for certain resource types.)"
  type        = string
}
variable "environment" {
  description = "Standard `environment` module input."
  type = object({
    vpc_id          = string
    aws_region      = string
    public_subnets  = list(string)
    private_subnets = list(string)
  })
}
variable "resource_tags" {
  description = "Standard `resource_tags` module input."
  type        = map(string)
}

########################################
### Custom variables for this module ###
########################################


variable "admin_username" {
  description = "The initial admin username."
  type        = string
}
variable "admin_password" {
  description = "The initial admin password. Must be 8 characters long."
  type        = string
  default     = null
}
variable "database_name" {
  description = "The name of the initial database to be created."
  default     = "default_db"
}
variable "elastic_ip" {
  description = "Optional. An Elastic IP endpoint which will be used to for routing incoming traffic."
  type        = string
  default     = null
}
variable "identifier" {
  description = "The database name which will be used within connection strings and URLs."
  default     = "rds-postgres-db"
}
variable "instance_class" {
  description = "Enter the desired node type. The default and cheapest option is 'db.t3.micro' @ ~$0.018/hr, or ~$13/mo (https://aws.amazon.com/rds/mysql/pricing/ )"
  type        = string
  default     = "db.t3.micro"
}
variable "jdbc_port" {
  description = "Optional. Overrides the default JDBC port for incoming SQL connections."
  default     = 5432
}
variable "kms_key_id" {
  description = "Optional. The ARN for the KMS encryption key used in cluster encryption."
  type        = string
  default     = null
}
variable "postgres_version" {
  description = "Optional. Overrides the version of the Postres database engine."
  default     = "11.5"
}

variable "s3_logging_bucket" {
  description = "Optional. An S3 bucket to use for log collection."
  type        = string
  default     = null
}
variable "s3_logging_path" {
  description = "Required if `s3_logging_bucket` is set. The path within the S3 bucket to use for log storage."
  type        = string
  default     = null
}
variable "storage_size_in_gb" {
  description = "The allocated storage value is denoted in GB"
  type        = string
  default     = "10"
}
variable "skip_final_snapshot" {
  description = "If true, will allow terraform to destroy the RDS cluster without performing a final backup."
  default     = false
}

variable "jdbc_cidr" {
  description = "List of CIDR blocks which should be allowed to connect to the instance on the JDBC port."
  type        = list(string)
  default     = []
}
variable "whitelist_terraform_ip" {
  description = "True to allow the terraform user to connect to the DB instance."
  type        = bool
  default     = true
}
