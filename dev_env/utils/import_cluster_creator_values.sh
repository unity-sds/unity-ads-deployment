#!/usr/bin/env bash

cluster_name=$(terraform output -raw eks_cluster_name)
principal_arn=$(aws eks list-access-entries --cluster-name ${cluster_name} | jq -r '.accessEntries[]' | grep mcp-tenantOperator | head -n 1)
policy_arn=$(aws eks list-associated-access-policies --cluster-name uads-venue-dev-jupyter --principal-arn ${principal_arn} | jq -r .associatedAccessPolicies[0].policyArn)

echo "cluster_name=${cluster_name}"
echo "principal_arn=${principal_arn}"
echo "policy_arn=${policy_arn}"

terraform import 'module.eks.aws_eks_access_entry.this["cluster_creator"]' "${cluster_name}:${principal_arn}"
terraform import 'module.eks.aws_eks_access_policy_association.this["cluster_creator_admin"]' "${cluster_name}#${principal_arn}#${policy_arn}"
