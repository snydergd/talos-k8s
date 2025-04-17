#!/bin/bash

if [ -e ~/.kube/config ]; then
  echo "Merging new config into user's"
  tofu output -raw -show-sensitive kubeconfig > kubeconfig.tmp
  BACKUP_FILE="$HOME/.kube/config.backup$(date "+%Y-%m-%d_%H%M%S")"
  mv ~/.kube/config "$BACKUP_FILE"
  KUBECONFIG="kubeconfig.tmp:$BACKUP_FILE" kubectl config view --flatten > ~/.kube/config
  rm kubeconfig.tmp
else
  echo "No user config -- placing this one in that location"
  tofu output -raw -show-sensitive kubeconfig > ~/.kube/config
fi;
chmod 600 ~/.kube/config

