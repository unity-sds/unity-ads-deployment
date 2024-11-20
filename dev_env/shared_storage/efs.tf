resource "aws_kms_key" "efs_key" {
  description             = "KMS key for Jupyter ${var.deployment_name}-${var.venue} EFS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.resource_prefix}-EfsKmsKey-${var.deployment_name}-${var.venue}"
  }
}

resource "aws_kms_alias" "efs_key_alias" {
  name          = "alias/${var.resource_prefix}-${var.deployment_name}-${var.venue}-efs-key"
  target_key_id = aws_kms_key.efs_key.key_id
}

resource "aws_efs_file_system" "dev_support_efs" {
   creation_token   = "${var.resource_prefix}-${var.deployment_name}-${var.venue}-efs-token"
   performance_mode = "generalPurpose"
   encrypted        = true
   kms_key_id       = aws_kms_key.efs_key.arn

   tags = {
     Name = "${var.efs_identifier}"
   }
}

resource "aws_efs_access_point" "jupyter_shared" {
  file_system_id = aws_efs_file_system.dev_support_efs.id
  root_directory {
    path = "/shared"
    creation_info {
       owner_uid = 0
       owner_gid = 100
       permissions = 775
    }
  }
}
