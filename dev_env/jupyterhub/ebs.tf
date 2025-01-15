resource "kubernetes_storage_class" "ebs_storage_class" {

  metadata {
    name = "ebs"
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Retain"

  parameters = merge({
      fsType = "ext4"
      type = "gp2"
    }, 
    # How to add custom tags to ebs-csi deployed volumes
    # https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/tagging.md
    { for i, k in keys(local.cost_tags) : "tagSpecification_${i}" => "${k}=${local.cost_tags[k]}" })

  depends_on = [
    aws_eks_addon.ebs-csi
  ]
}
