/*
* This module securely deploys Matillion data tranformation tool.
* For admin reference, please see [this link](https://redshift-support.matillion.com/s/article/2487955).
*
* Supported features:
*
* * Auto-upload SSL certificate for HTTPS support.
* * Admin CIDR defaults to only allow traffic from terraform user's IP address (override using `admin_cidr` variable).
* * Automatically turns itself off to reduce costs by not running outside provided weekday or weekend uptime schedule.
*
* EULA: https://d7umqicpi7263.cloudfront.net/eula/product/137a4305-1a46-436b-bc3b-d40cf4a27637/07f63528-ab83-4294-837c-7ec628bba6ce.txt
*/

locals {
  name_prefix = "${var.name_prefix}Matillion-"
  admin_cidr  = var.admin_cidr
  app_cidr    = length(var.app_cidr) == 0 ? local.admin_cidr : var.app_cidr
  admin_ports = combine(
    var.allow_http ? { "HTTP" : "80" } : {},
    var.allow_https ? { "HTTPS" : "443" } : {}
  )

  # # TODO: Delete or reuse:
  #   ec2_files = flatten([
  #     fileset(path.module, "resources/win/*"),
  #     fileset(path.module, "resources/*"),
  #     ["${var.registration_file}:registration.json"]
  #   ])
  #   ssh_key_dir              = pathexpand("~/.ssh")
  #   ssh_public_key_filepath  = "${local.ssh_key_dir}/${lower(local.name_prefix)}prod-ec2keypair.pub"
  #   ssh_private_key_filepath = "${local.ssh_key_dir}/${lower(local.name_prefix)}prod-ec2keypair.pem"
}

# TODO: Delete or reuse:
# resource "aws_key_pair" "mykey" {
#   key_name   = "${local.name_prefix}ec2-keypair"
#   public_key = file(local.ssh_public_key_filepath)
# }

module "matillion_ec2" {
  source        = "../../../components/aws/ec2"
  name_prefix   = "${local.name_prefix}"
  environment   = var.environment
  resource_tags = var.resource_tags

  num_instances       = 1
  instance_type       = var.ec2_instance_type
  instance_storage_gb = var.ec2_instance_storage_gb
  ami_id              = local.ami_per_region[var.environment.aws_region]
  admin_ports         = local.admin_ports
  app_ports           = {}
  #   ssh_key_name             = aws_key_pair.mykey.key_name
  #   ssh_private_key_filepath = local.ssh_private_key_filepath
}