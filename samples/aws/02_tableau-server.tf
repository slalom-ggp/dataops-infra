module "tableau_server_on_aws" {
  source                = "../../catalog/tableau-server-on-aws"
  name_prefix           = local.name_prefix
  aws_region            = local.aws_region
  num_linux_instances   = 1
  num_windows_instances = 0
  ec2_instance_type     = "p3.8xlarge"
  # admin_cidr            = []
  # default_cidr          = ["0.0.0.0/0"]
  # ec2_instance_type     = "m4.4xlarge"
}
