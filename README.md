# Summary
Config for cluster
- "sops" and "age" for encrypting secrets
- talos on proxmox

# Install summary
https://www.talos.dev/v1.9/talos-guides/install/virtualized-platforms/proxmox/

# Pre-requisites

- `bootstrap.gdsnyder.info` configured/running:
  - webdav http server with a `/talos` path configured with the credentials in `bootstrap.json` (generated from sops decryption of the `.enc`)
    - Used for nodes to pull in cilium config (you push the file there from the deploy script in the cilium folder)
  - minio on port 9000 -- a bucket `talos` configured, with a user having full access of it.  The user's credentials are in `proxmox/state.tf.json`.
    - This is used for the opentofu/terraform "backend" (holds tfstate files to keep track of resources terraform deployed previously)
- Local tools:
  - talosctl (somewhat optional, but nice to have)
  - cilium (also optional, but nice to have)
  - helm
  - kubectl
  - opentofu cli or terrraform cli
  - Proxmox cluster/node
  - OpenWRT (there are other options - used for dhcp and routing for ipv6 - bgp router using quagga)

# Getting started

After one-time pre-req setup:

- After clone, secrets are decrypted by running `sops_helper.sh decrypt` (sops will need to be configured with an age key listed in `.sops.yaml`)

# DHCP setup
See proxmox/variables.tf for nodes to configure (adapt as needed) -- based on these, set up static dhcp leases for the mac addresses, using the host names (talos-control1, talos-worker3, etc.)

# Download ISO and create VMs
ISO customizer: https://factory.talos.dev/?arch=amd64&board=undefined&cmdline-set=true&extensions=-&extensions=siderolabs%2Ffuse3&extensions=siderolabs%2Fgvisor&extensions=siderolabs%2Fkata-containers&platform=metal&secureboot=undefined&target=metal&version=1.9.5

ISO download: https://factory.talos.dev/image/3d21306bff7a05d66bfef815d12d887a115026cca68eac56755d7b8db22ee090/v1.9.5/metal-amd64.iso

Upload to "local" disk of PVE as an iso image named `talos3.iso`.

# Cilium
If setting up the bootstrap server, you'll need to deploy to there by running cilium/deploy.sh to update dav location

It will fail trying to apply the config, due to k8s not being available yet, but that is ok

If you want to make changes to it, you'll want to run it again

# Start up VMs and configure

1. Go into `proxmox` folder
2. Run `tofu apply` (`tofu` being an open source alternative to `tf`) -- optionally with `-auto-approve`

# Install config files from outputs

kubeconfig (merge)

    tofu output -raw -show-sensitive kubeconfig > kubeconfig.tmp
    BACKUP_FILE=~"/.kube/config.backup$(date "+%Y-%m-%d_%H%M%S")"
    mv ~/.kube/config "$BACKUP_FILE"
    KUBECONFIG="$BACKUP_FILE:kubeconfig.tmp" kubectl config view --flatten > ~/.kube/config
    chmod 600 ~/.kube/config
    rm kubeconfig.tmp

and talosctl (doesn't merge - so be careful)

    tofu output -raw -show-sensitive talosconfig > ~/.talos/config

# Load Balancer/BGP/IPv6
To expose IP addresses through load balanced IPs, you'll need to create an IP range.  For example:

    kubectl apply -f cilium/red-pool.yaml

IPv6 should be all ready in Talos hopefully.

However, the idea is kind of neat of having full IP addresses accessible on the internet.  This way, you could
have nginx ingress exposed on one IP, and the Cilium ingress exposed on another.  Or I could have an IP dedicated
to gitea, and another for gogs.  In either case, I could expose two services with the same port, which is pretty
slick.

Solution: Route IPv6 from the internet into load balanced IPs.

BGP allows Cilium to dynamically add this routing, but it needs to be configured first.  For this, see `cilium/bgp` resources.

# OpenEBS
This is for persistent storage on the cluster

helm repo add openebs https://openebs.github.io/openebs
kubectl create namespace openebs
kubectl label --overwrite ns openebs pod-security.kubernetes.io/enforce=privileged
helm install openebs --namespace openebs openebs/openebs -f openebs/values.yaml --version 4.2.0

# Cert manager
Certificates for ingress

    # kubectl label --overwrite ns cert-manager pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/warn=privileged pod-security.kubernetes.io/audit=privileged

    kubectl create namespace cert-manager
    helm install cert-manager jetstack/cert-manager -n cert-manager --version=v1.17.0 -f cert-manager/values.yaml
    kubectl apply -f cert-manager/secret.yml
    kubectl apply -f cert-manager/issuer.yml
    kubectl apply -f cert-manager/certificate.yml

# nginx
This is optional -- by default we can just use envoy.

## Install CRDs
mkdir nginx; cd nginx;
curl -OL https://raw.githubusercontent.com/nginx/kubernetes-ingress/v4.0.1/deploy/crds.yaml
kubectl apply -f crds.yaml

## Install chart for ingress
kubectl create namespace nginx
#kubectl label --overwrite ns nginx pod-security.kubernetes.io/enforce=privileged
helm install nginx oci://ghcr.io/nginx/charts/nginx-ingress --version 2.0.1 -f nginx/values.yml -n nginx

# woodpecker (optional)
kubectl create namespace woodpecker
kubectl label --overwrite ns woodpecker pod-security.kubernetes.io/enforce=privileged
helm install woodpecker woodpecker/woodpecker --version 3.0.6 -f woodpecker/values.yaml -n woodpecker

# gitea (optional)
kubectl create namespace gitea
helm repo add gitea-charts https://dl.gitea.com/charts/
helm repo update
helm install gitea gitea-charts/gitea -f gitea/values.yaml -n gitea
