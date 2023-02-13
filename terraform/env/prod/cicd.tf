module "CICD" {
  source              = "../../modules/CICD"
  enable_codebuild    = true
  enable_codedeploy   = true
  enable_codepipeline = true

  Name             = format("%s-%s-asg", local.Environment, local.Name)
  image            = local.image
  type             = local.type
  group_name       = local.group_name
  stream_name      = local.stream_name
  location         = local.location
  compute_platform = local.compute_platform
  pipeline_name    = local.pipeline_name
  output_artifacts = local.output_artifacts
  FullRepositoryId = local.FullRepositoryId
  BranchName       = local.BranchName
}

