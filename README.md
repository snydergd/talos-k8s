# Summary
Config for cluster
- "sops" and "age" for encrypting secrets
- talos on proxmox

# Install summary
https://www.talos.dev/v1.9/talos-guides/install/virtualized-platforms/proxmox/


# Download ISO and create VMs
https://factory.talos.dev/?arch=amd64&board=undefined&cmdline-set=true&extensions=-&extensions=siderolabs%2Ffuse3&extensions=siderolabs%2Fgvisor&extensions=siderolabs%2Fkata-containers&platform=metal&secureboot=undefined&target=metal&version=1.9.5

https://factory.talos.dev/image/3d21306bff7a05d66bfef815d12d887a115026cca68eac56755d7b8db22ee090/v1.9.5/metal-amd64.iso

Turn off firewall in network tab on creation
check qemu agent box on cpu
change to 2 cores
change memory to 4096
change disk to 64gb
Edit VM after creation to add this:
vi /etc/pve/qemu-server/<vmid>.conf # in proxmox host shell
create static dhcp lease for mac address

The following line:

    args: -cpu kvm64,+cx16,+lahf_lm,+popcnt,+sse3,+ssse3,+sse4.1,+sse4.2

# Start up VMs and configure
VMS will show IPs - you can record like this

CONTROL_PLANE_IP=192.168.240.104
WORKER_IP=192.168.240.108 # node 1
WORKER_IP=192.168.240.142 # node 2

already done at this point:
- # alternate - talosctl gen config talos-proxmox-cluster https://$CONTROL_PLANE_IP:6443 --output-dir _out
- talosctl gen config talos-proxmox-cluster https://$CONTROL_PLANE_IP:6443 --output-dir _out --install-image factory.talos.dev/installer/ce4c980550dd2ab1b17bbf2b08801c7eb59418eafe8f279833297925d67c7515:v1.9.2

# cilium
run decrypt script: `sops_helper.sh decrypt`
run cilium/deploy.sh to update dav location

# Apply/Bootstrap
talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file _out/controlplane.yaml
talosctl apply-config --insecure --nodes $WORKER_IP --file _out/worker.yaml

export TALOSCONFIG="_out/talosconfig"
talosctl config endpoint $CONTROL_PLANE_IP
talosctl config node $CONTROL_PLANE_IP

talosctl bootstrap

talosctl kubeconfig .

# openebs
kubectl create namespace openebs
kubectl label --overwrite ns openebs pod-security.kubernetes.io/enforce=privileged
helm install openebs --namespace openebs openebs/openebs -f openebs/values.yaml --version 4.2.0

# metallb

kubectl create namespace metallb
kubectl label --overwrite ns metallb pod-security.kubernetes.io/enforce=privileged
kubectl label --overwrite ns metallb pod-security.kubernetes.io/audit=privileged
kubectl label --overwrite ns metallb pod-security.kubernetes.io/warn=privileged
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb --version=0.14.9 -f metallb/values.yaml -n metallb

# nginx

## Install CRDs
mkdir nginx; cd nginx;
curl -OL https://raw.githubusercontent.com/nginx/kubernetes-ingress/v4.0.1/deploy/crds.yaml
kubectl apply -f crds.yaml

## Install chart for ingress
kubectl create namespace nginx
kubectl label --overwrite ns nginx pod-security.kubernetes.io/enforce=privileged
(install or upgrade)
helm upgrade nginx oci://ghcr.io/nginx/charts/nginx-ingress --version 2.0.1 -f nginx/values.yml -n kube-system

# Cert manager
kubectl create namespace cert-manager
kubectl label --overwrite ns cert-manager pod-security.kubernetes.io/enforce=privileged pod-security.kubernetes.io/warn=privileged pod-security.kubernetes.io/audit=privileged
helm install cert-manager jetstack/cert-manager -n cert-manager --version=v1.17.0 -f cert-manager/values.yaml
kubectl apply -f cert-manager/secret.yml # after sops_helper script
kubectl apply -f cert-manager/issuer.yml
kubectl apply -f cert-manager/certificate.yml

# woodpecker
kubectl create namespace woodpecker
kubectl label --overwrite ns woodpecker pod-security.kubernetes.io/enforce=privileged
helm install woodpecker woodpecker/woodpecker --version 3.0.6 -f woodpecker/values.yaml -n woodpecker

# gitea
kubectl create namespace gitea
helm repo add gitea-charts https://dl.gitea.com/charts/
helm repo update
helm install gitea gitea-charts/gitea -f gitea/values.yaml -n gitea
