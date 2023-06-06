resource "aws_cloudformation_stack" "db" {
  name = "awsDbDockstoreStack"

   parameters = {
    ResourcePrefix = "${var.resource_prefix}"
    DBName = "${var.resource_prefix}"
    DBMasterUserPassword  = "/DeploymentConfig/${var.resource_prefix}/DBPostgresPassword"
    DBSnapshot = "${var.db_snapshot}"
    VpcId = data.aws_vpc.unity_vpc.id
    SubnetId1 = tolist(data.aws_subnets.unity_public_subnets.ids)[0]
    SubnetId2 = tolist(data.aws_subnets.unity_public_subnets.ids)[1]
    AvailabilityZone = "${var.availability_zone}"
  }

  template_body = file("${path.module}/database.yml")

  timeout_in_minutes = 60

}
