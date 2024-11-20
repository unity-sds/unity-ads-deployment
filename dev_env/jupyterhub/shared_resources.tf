data "aws_efs_file_system" "dev_support_fs" {
  tags = {
    Name = "${var.efs_identifier}"
  }
}

# Extract out access point id that has the /shared root directory path
data "aws_efs_access_points" "fs_access_point_ids" {
  file_system_id = data.aws_efs_file_system.dev_support_fs.id
}

data "aws_efs_access_point" "fs_access_point_info" {
  for_each = toset(data.aws_efs_access_points.fs_access_point_ids.ids)
  access_point_id = each.value
}

locals {
  dev_support_shared_ap_id = [ for ap in data.aws_efs_access_point.fs_access_point_info : ap.id if ap.root_directory[0].path == "/shared" ][0]
}
