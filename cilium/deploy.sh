#!/bin/bash

cd "$(dirname "$(readlink -f "$0")")";

echo "# Ensure repo is installed"
helm repo list | grep "cilium " || {
    echo "## Installing"
    helm repo add cilium https://helm.cilium.io/
    helm repo update
}

echo "# Generate template"
helm template \
    cilium \
    cilium/cilium \
    --version 1.18.0-pre.0 \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=true \
    --set k8sClientRateLimit.qps=65 \
    --set k8sClientRateLimit.burst=150 \
    --set bgpControlPlane.enabled=true \
    --set bgpControlPlane.routerIDPool=10.0.0.0/16 \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --set k8sServiceHost=localhost \
    --set ingressController.enabled=true \
    --set ingressController.default=true \
    --set ingressController.loadbalancerMode=shared \
    --set ingressController.defaultSecretName=letsencrypt-pve-prod \
    --set ingressController.defaultSecretNamespace=kube-system \
    --set ingressController.enforceHttps=true \
    --set gatewayApi.enabled=true \
    --set envoy.enabled=true \
    --set loadBalancer.l7.backend=envoy \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set hubble.ui.ingress.enabled=true \
    --set hubble.ui.ingress.className=cilium \
    --set 'hubble.ui.ingress.hosts[0]=hubble.pve.gdsnyder.info' \
    --set 'hubble.ui.ingress.tls[0].hosts[0]=hubble.pve.gdsnyder.info' \
    --set k8sServicePort=7445 > cilium.yaml

#    --set hubble.ui.ingress.className=nginx \
echo "# Get creds for upload"
sops decrypt --output-type dotenv --input-type dotenv --output creds.env creds.env.enc
. creds.env

UPLOAD_URL='http://bootstrap.gdsnyder.info/talos/cilium.yaml' 
echo "# Upload to $UPLOAD_URL"
curl -T cilium.yaml "$UPLOAD_URL" -u "${BOOTSTRAP_USER}:${BOOTSTRAP_PASS}"

echo "# Apply"
kubectl apply -f cilium.yaml

echo "# Done"
