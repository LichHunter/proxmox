output "opnsense_user_password" {
  value     = random_password.opnsense.result
  sensitive = true
}

output "grafana_id" {
  value     = random_password.grafana_id.result
  sensitive = true
}

output "grafana_secret" {
  value     = random_password.grafana_secret.result
  sensitive = true
}

output "gitlab_id" {
  value     = random_password.gitlab_id.result
  sensitive = true
}

output "gitlab_secret" {
  value     = random_password.gitlab_secret.result
  sensitive = true
}
