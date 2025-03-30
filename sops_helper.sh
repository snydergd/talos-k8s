#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <encrypt|decrypt>" >&2
  exit 1
fi;

YAML_FILES=$(cat <<EOF
gitea/values.yaml
woodpecker/values.yaml
cert-manager/secret.yml
_out/talosconfig
_out/controlplane.yaml
_out/worker.yaml
EOF
)
ENV_FILES=$(cat <<EOF
cilium/creds.env
EOF
)

IFS=$'\n'
case "$1" in
  encrypt)
    echo "Encrypt"
    echo "$YAML_FILES" | while read -r f; do
        echo " - $f (yaml)"
	sops encrypt --output-type yaml --input-type=yaml --output "$f.enc" "$f"
    done;
    echo "$ENV_FILES" | while read -r f; do
        echo " - $f (dotenv)"
	sops encrypt --output-type dotenv --input-type dotenv --output "$f.enc" "$f"
    done;
    ;;
  decrypt)
    echo "Decrypt"
    echo "$YAML_FILES" | while read -r f; do
        echo " - $f (yaml)"
	sops decrypt --output-type yaml --input-type yaml --output "$f" "$f.enc"
    done;
    echo "$ENV_FILES" | while read -r f; do
        echo " - $f (dotenv)"
	sops decrypt --output-type dotenv --input-type dotenv --output "$f" "$f.enc"
    done;
    ;;
esac;
