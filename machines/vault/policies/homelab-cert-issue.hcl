path "intermediate_ca/issue/issue-homelab-certs" {
  capabilities = ["create", "update"]
}

path "intermediate_ca/crl" {
  capabilities = ["read"]
}

path "intermediate_ca/ca_chain" {
  capabilities = ["read"]
}
