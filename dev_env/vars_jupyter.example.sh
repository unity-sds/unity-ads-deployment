export AWS_PROFILE=mcp-venue-dev

export KUBE_CONFIG_PATH=$HOME/.kube/config

# Required to be set before beginning installation
export TF_VAR_project="unity"
export TF_VAR_venue="dev"
export TF_VAR_deployment_name="venue"

export TF_VAR_efs_identifier="uads-venue-dev-efs-fs"

# Can be determined automatically during installation process or supplied ahead of time
export TF_VAR_cognito_oauth_base_url="https://unitysds.auth.us-west-2.amazoncognito.com"
export TF_VAR_cognito_oauth_client_id=""
export TF_VAR_cognito_oauth_client_secret=""

# Public facing URL and path after that URL for routing
# If not supplied then the internal ALB is used
#export TF_VAR_jupyter_base_url="https://www.dev.mdps.mcp.nasa.gov:4443"
#export TF_VAR_jupyter_base_path="unity/dev/jupyter"

# Optional, these are Terraform arrays defined as strings, please follow the syntax in the
# examples below
#export TF_VAR_jupyter_s3_buckets='["bogus-bucket-name-1", "bogus-bucket-name-2"]'
#export TF_VAR_jupyter_admin_users='[]'
