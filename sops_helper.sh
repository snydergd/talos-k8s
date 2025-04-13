#!/bin/bash

SCRIPT_DIR="$(readlink -f "$(dirname "$0")")"
cd "$SCRIPT_DIR";

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
EOF
)

JSON_FILES=$(cat <<EOF
pve.json
proxmox/state.tf.json
bootstrap.json
EOF
)

encrypt_if_different() {
    output="$1"
    input="$2"
    type="$3"

    sops decrypt "$output" --output "/tmp/encryption_test" --output-type="$type" --input-type="$type"
    if [ "$type" == "json" ]; then
      mv /tmp/encryption_test /tmp/encryption_test3;
      cat /tmp/encryption_test3 | jq > /tmp/encryption_test;
      cat "$input" | jq > /tmp/encryption_test2;
      otherfile=/tmp/encryption_test2;
    else
      otherfile="$input"
    fi;
    if ! cmp "$otherfile" "/tmp/encryption_test" >/dev/null; then
        echo " - $input ($type)"
        sops encrypt "$input" --output "$output" --output-type="$type" --input-type="$type"
    fi;
}

IFS=$'\n'
case "$1" in
  encrypt)
    echo "Encrypt"
    echo "$YAML_FILES" | while read -r f; do
        encrypt_if_different "$f.enc" "$f" yaml
    done;
    echo "$ENV_FILES" | while read -r f; do
        if [ -n "$f" ]; then
            encrypt_if_different "$f.enc" "$f" dotenv
        fi;
    done;
    echo "$JSON_FILES" | while read -r f; do
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
        if [ -n "$f" ]; then
            echo " - $f (dotenv)"
            sops decrypt --output-type dotenv --input-type dotenv --output "$f" "$f.enc"
        fi;
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
