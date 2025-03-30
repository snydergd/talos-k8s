#!/bin/bash

cd "$(dirname "$(readlink -f "$0")")"

. ../.env
export TALOSCONFIG="$(pwd)/talosconfig"
echo $TALOSCONFIG
cat $TALOSCONFIG
talosctl apply-config "$@" --nodes $CONTROL_PLANE_IP --file controlplane.yaml
talosctl apply-config "$@" --nodes $WORKER_IP,$WORKER_IP2,$WORKER_IP3 --file worker.yaml
