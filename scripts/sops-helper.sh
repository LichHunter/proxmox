#!/usr/bin/env nix
#! nix shell nixpkgs#bash nixpkgs#sops nixpkgs#yq-go nixpkgs#ssh-to-age nixpkgs#openssh --command bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOPS_DIR="${REPO_ROOT}/machines/nixos"
SECRETS_DIR="${SOPS_DIR}/secrets"
SOPS_FILE="${SOPS_DIR}/.sops.yaml"
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> <machine> [args...]

Commands:
  set <machine> <key> <value>    Set a secret value
  update-keys <machine> <host>   Update machine's age key from SSH host key

Examples:
  $(basename "$0") set nixarr nixarr_role_id "abc-123"
  $(basename "$0") update-keys nixarr 192.168.1.54
EOF
  exit 1
}

cmd_set() {
  local machine="$1" key="$2" value="$3"
  local rel="secrets/${machine}.yaml"

  [[ ! -f "${SECRETS_DIR}/${machine}.yaml" ]] && { echo "Error: ${SECRETS_DIR}/${machine}.yaml not found"; exit 1; }

  cd "$SOPS_DIR"
  DECRYPTED=$(sops decrypt "$rel")
  echo "$DECRYPTED" | yq eval ".${key} = \"${value}\"" - > "$rel"
  sops encrypt -i "$rel"
  echo "Updated '${key}' in ${rel}"
}

cmd_update_keys() {
  local machine="$1"
  local host="${2:-}"

  if [[ -z "$host" ]]; then
    echo "Error: provide hostname/IP as second argument"
    echo "Usage: $(basename "$0") update-keys <machine> <host>"
    exit 1
  fi

  local age_key
  age_key=$(ssh-keyscan -t ed25519 "$host" 2>/dev/null | ssh-to-age)
  if [[ -z "$age_key" ]]; then
    echo "Error: could not derive age key from ${host}"
    exit 1
  fi
  echo "Machine '${machine}' age key: ${age_key}"

  if grep -q "&${machine}" "$SOPS_FILE"; then
    sed -i "s|^\(  - \&${machine}\) .*|\1 ${age_key}|" "$SOPS_FILE"
    echo "Updated existing key for '${machine}' in .sops.yaml"
  else
    sed -i "/^keys:/a\\  - \&${machine} ${age_key}" "$SOPS_FILE"
    echo "Added new key for '${machine}' in .sops.yaml"
  fi

  if [[ -f "${SECRETS_DIR}/${machine}.yaml" ]]; then
    cd "$SOPS_DIR"
    sops updatekeys -y "secrets/${machine}.yaml"
    echo "Re-encrypted secrets/${machine}.yaml with updated keys"
  fi
}

[[ $# -lt 2 ]] && usage

COMMAND="$1"
shift

case "$COMMAND" in
  set)
    [[ $# -ne 3 ]] && usage
    cmd_set "$1" "$2" "$3"
    ;;
  update-keys)
    [[ $# -ne 2 ]] && usage
    cmd_update_keys "$1" "$2"
    ;;
  *)
    usage
    ;;
esac
