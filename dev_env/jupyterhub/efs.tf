resource "aws_security_group" "dev_support_efs_jupyter_sg" {
   name = "${var.resource_prefix}-${var.deployment_name}-${var.venue}-efs-jupyter-sg"
   description= "Allows inbound EFS traffic from Jupyter cluster"
   vpc_id = data.aws_ssm_parameter.vpc_id.value

   ingress {
     security_groups = [ module.eks.node_security_group_id ]
     from_port = 2049
     to_port = 2049 
     protocol = "tcp"
   }     
        
   egress {
     security_groups = [ module.eks.node_security_group_id ]
     from_port = 0
     to_port = 0
     protocol = "-1"
   }
}

resource "aws_efs_mount_target" "dev_support_efs_mt_1" {
   file_system_id  = data.aws_efs_file_system.dev_support_fs.id
   subnet_id       = local.subnet_map["private"][0]
   security_groups = [aws_security_group.dev_support_efs_jupyter_sg.id]
}

resource "aws_efs_mount_target" "dev_support_efs_mt_2" {
   file_system_id  = data.aws_efs_file_system.dev_support_fs.id
   subnet_id       = local.subnet_map["private"][1]
   security_groups = [aws_security_group.dev_support_efs_jupyter_sg.id]
}

# Follows setup here:
# https://aws.amazon.com/blogs/storage/persistent-storage-for-kubernetes/

resource "kubernetes_storage_class" "efs_storage_class" {
  metadata {
    name = "efs"
  }
  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Delete"

  parameters = {
  }
}

# Documentation on how to set up volume_handle:
# https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/examples/kubernetes/access_points/README.md#create-access-points-in-efs
# See also:
# https://kubernetes.io/docs/concepts/storage/persistent-volumes/
resource "kubernetes_persistent_volume" "dev_support_shared_volume" {
  metadata {
    name = "${var.resource_prefix}-${var.deployment_name}-${var.venue}-dev-data"
  }

  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = "efs"

    capacity = {
      storage = "100Gi"
    }

    persistent_volume_reclaim_policy = "Delete"

    persistent_volume_source {
      csi {
        driver = "efs.csi.aws.com"
        volume_handle = "${data.aws_efs_file_system.dev_support_fs.id}::${local.dev_support_shared_ap_id}"
      }
    }

    mount_options = [ "iam" ]
  }

  # Prevents a cycle with eks_cluster.jupyter_hub
  depends_on = [ 
    kubernetes_storage_class.efs_storage_class,
    aws_efs_mount_target.dev_support_efs_mt_1,
    aws_efs_mount_target.dev_support_efs_mt_2,
    aws_eks_addon.efs-csi
  ]
}

resource "kubernetes_persistent_volume_claim" "dev_support_shared_volume_claim" {
  metadata {
    name = "${var.resource_prefix}-${var.deployment_name}-${var.venue}-dev-data"
    namespace = helm_release.jupyter_helm.namespace
  }

  spec {
    access_modes = ["ReadWriteMany"]

    storage_class_name = "efs"

    resources {
      requests = {
        storage = "100Gi"
      }
    }

    volume_name = "${kubernetes_persistent_volume.dev_support_shared_volume.metadata.0.name}"
  }

  # Prevents a cycle with eks_cluster.jupyter_hub
  depends_on = [ 
    kubernetes_persistent_volume.dev_support_shared_volume,
    aws_eks_addon.efs-csi
  ]
}
