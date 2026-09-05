provider "opnsense" {
  uri        = var.opnsense_uri
  api_key    = var.opnsense_api_key
  api_secret = var.opnsense_api_secret

  # Web UI certificate is issued by an internal CA that is not in this
  # machine's trust store. Prefer adding the CA to the trust store and
  # removing this once certificates are issued via Vault PKI.
  allow_insecure = true
}
