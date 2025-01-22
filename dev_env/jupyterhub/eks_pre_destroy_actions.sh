#!/bin/bash
set -e

# remove finalizers from EFS PVCs
kubectl get pvc --all-namespaces --no-headers | grep ' efs ' | while read line; do
  namespace=$(echo $line | awk '{print $1}')
  pvc_name=$(echo $line | awk '{print $2}')
  kubectl patch pvc ${pvc_name} -p '{"metadata":{"finalizers":null}}' -n ${namespace}
done
