resource "vault_policy" "issue_homelab_certs" {
  name   = "issue-homelab-certs"
  policy = file("${path.module}/policies/homelab-cert-issue.hcl")
}

resource "vault_policy" "read_authentik_secrets" {
  name   = "read-authentik-secrets"
  policy = file("${path.module}/policies/read-authentik-secrets.hcl")
}
