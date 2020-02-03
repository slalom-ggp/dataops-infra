# NOTE: Requires AWS policy 'AmazonRedshiftFullAccess' on the terraform account

module "redshift_dw" {
# source            = "git::https://github.com/slalom-ggp/dataops-infra.git//catalog/aws/redshift?ref=master"
  source            = "../../catalog/aws/redshift"
  name_prefix       = "${local.project_shortname}-"

  # CONFIGURE HERE:


  /*
  # OPTIONALLY, COPY-PASTE ADDITIONAL SETTINGS FROM BELOW:

  node_type         = "dc2.large"  # https://aws.amazon.com/redshift/pricing/
  num_nodes         = 2

  admin_password    = "asdfAS12"
  aws_region        = local.aws_region
  */
}

output "summary" { value = module.redshift_dw.summary }
