data "aws_cognito_user_pools" "unity_user_pool" {
  name = var.cognito_user_pool_name
}

resource "aws_cognito_user_pool_client" "jupyter_cognito_client" {
  name          = "${var.resource_prefix}-jupyter-${var.deployment_name}-${var.venue}-client"
  user_pool_id  = tolist(data.aws_cognito_user_pools.unity_user_pool.ids)[0]

  callback_urls = var.jupyter_base_url != null ? ["${var.jupyter_base_url}/${var.jupyter_base_path}/hub/oauth_callback"] : null
  logout_urls   = var.jupyter_base_url != null ? ["${var.jupyter_base_url}/${var.jupyter_base_path}/hub/login/oauth_callback/logout"] : null

  allowed_oauth_flows                           = var.jupyter_base_url != null ? ["code"] : null
  allowed_oauth_flows_user_pool_client          = var.jupyter_base_url != null ? true : null
  allowed_oauth_scopes                          = var.jupyter_base_url != null ? ["email", "openid", "profile"] : null

  generate_secret                               = true
  supported_identity_providers                  = ["COGNITO"]
  enable_propagate_additional_user_context_data = "false"
  enable_token_revocation                       = "true"
  prevent_user_existence_errors                 = "ENABLED"
  access_token_validity                         = 60 
  id_token_validity                             = 60

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

output "cognito_user_pool_id" {
  value = tolist(data.aws_cognito_user_pools.unity_user_pool.ids)[0]
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.jupyter_cognito_client.id
}
