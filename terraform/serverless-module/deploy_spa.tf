resource "null_resource" "deploySPAApp" {
  triggers = {
    always_run = "${timestamp()}"
  }
  
  provisioner "local-exec" {
    command = lower("cd ../ && npm run build && aws s3 sync dist/ s3://${data.aws_caller_identity.current.account_id}-${var.project_name}-spa && aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.dashboard-cf.id} --paths '/*'")
  }
}