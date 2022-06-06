# common variables to the project

locals { # inputs can't reference themselves, so we use locals first
  resourcetier = get_env("TF_VAR_resourcetier", "")

  # absolute project tags
  vpcname_rendervpc     = "${local.resourcetier}rendervpc"
  projectname_rendervpc = "firehawk-render-cluster" # A tag to recognise resources created in this project
  common_tags_rendervpc = {
    "environment" : get_env("TF_VAR_environment", ""),
    "resourcetier" : get_env("TF_VAR_resourcetier", ""),
    "conflictkey" : get_env("TF_VAR_conflictkey", ""),
    "pipelineid" : get_env("TF_VAR_pipelineid", ""),
    "accountid" : get_env("TF_VAR_account_id", ""),
    "owner" : get_env("TF_VAR_owner", ""),
    "region" : get_env("AWS_DEFAULT_REGION", ""),
    "vpcname" : local.vpcname_rendervpc,
    "projectname" : local.projectname_rendervpc,
    "terraform" : "true",
  }
  vpcname_vaultvpc     = "${local.resourcetier}vaultvpc"
  projectname_vaultvpc = "firehawk-main" # A tag to recognise resources created in this project
  common_tags_vaultvpc = {
    "environment" : get_env("TF_VAR_environment", ""),
    "resourcetier" : get_env("TF_VAR_resourcetier", ""),
    "conflictkey" : get_env("TF_VAR_conflictkey", ""),
    "pipelineid" : get_env("TF_VAR_pipelineid", ""),
    "accountid" : get_env("TF_VAR_account_id", ""),
    "owner" : get_env("TF_VAR_owner", ""),
    "region" : get_env("AWS_DEFAULT_REGION", ""),
    "vpcname" : local.vpcname_vaultvpc,
    "projectname" : local.projectname_vaultvpc,
    "terraform" : "true",
  }
  vpcname_deployervpc     = "${local.resourcetier}deployervpc"
  projectname_deployervpc = "firehawk-main" # A tag to recognise resources created in this project
  common_tags_deployervpc = {
    "environment" : get_env("TF_VAR_environment", ""),
    "resourcetier" : get_env("TF_VAR_resourcetier", ""),
    "conflictkey" : get_env("TF_VAR_conflictkey", ""),
    "pipelineid" : get_env("TF_VAR_pipelineid", ""),
    "accountid" : get_env("TF_VAR_account_id", ""),
    "owner" : get_env("TF_VAR_owner", ""),
    "region" : get_env("AWS_DEFAULT_REGION", ""),
    "vpcname" : local.vpcname_deployervpc,
    "projectname" : local.projectname_deployervpc,
    "terraform" : "true",
  }

  ### tags for this project ###
  vpcname     = local.vpcname_rendervpc
  projectname = local.projectname_rendervpc
  common_tags = local.common_tags_rendervpc
}

inputs = {
  resourcetier = local.resourcetier

  vpcname_rendervpc = local.vpcname_rendervpc
  projectname_rendervpc = local.projectname_rendervpc
  common_tags_rendervpc = local.common_tags_rendervpc

  vpcname_vaultvpc     = local.vpcname_vaultvpc
  projectname_vaultvpc = local.projectname_vaultvpc
  common_tags_vaultvpc = local.common_tags_vaultvpc

  vpcname_deployervpc     = local.vpcname_deployervpc
  projectname_deployervpc = local.projectname_deployervpc
  common_tags_deployervpc = local.common_tags_deployervpc
  # tags for this project
  vpcname     = local.vpcname
  projectname = local.projectname
  common_tags = local.common_tags
}
