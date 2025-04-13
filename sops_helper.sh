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

JSON_FILES=$(cat <<EOF
pve.json
proxmox/state.tf.json
EOF
)

encrypt_if_different() {
    output="$1"
    input="$2"
    type="$3"

    sops decrypt "$output" --output "/tmp/encryption_test" --output-type="$type" --input-type="$type"
    if ! cmp "$input" "/tmp/encryption_test"; then
        sops encrypt "$input" --output "$output" --output-type="$type" --input-type="$type"
    fi;
}

IFS=$'\n'
case "$1" in
  encrypt)
    echo "Encrypt"
    echo "$YAML_FILES" | while read -r f; do
        echo " - $f (yaml)"
        encrypt_if_different "$f.enc" "$f" yaml
    done;
    echo "$ENV_FILES" | while read -r f; do
        echo " - $f (dotenv)"
        encrypt_if_different "$f.enc" "$f" dotenv
    done;
    echo "$JSON_FILES" | while read -r f; do
        echo " - $f (json)"
        encrypt_if_different "$f.enc" "$f" json
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
    echo "$JSON_FILES" | while read -r f; do
        echo " - $f (json)"
	sops decrypt --output-type json --input-type json --output "$f" "$f.enc"
    done;
    ;;
  reset)
    echo -e "$YAML_FILES\n$ENV_FILES\n$JSON_FILES" | while read -r f; do
	echo " - $f"
        git checkout -- "$f.enc"
    done;
    ;;
esac;
