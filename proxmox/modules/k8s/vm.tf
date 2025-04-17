#import {
#  to = proxmox_vm_qemu.nodes[each.key]
#  id = "pve/vm/${each.value.id}"
#  for_each = {for i, node in var.nodes : "${node.type}${node.index}" => node }
#}

resource "proxmox_pool" "talos" {
  poolid = "talos"
	comment = "Talos k8s cluster"
}

resource "proxmox_vm_qemu" "nodes" {
  depends_on = [proxmox_pool.talos]
  for_each = { for i, node in var.nodes : "${node.type}${node.index}" => node }

  additional_wait             = null
  agent                       = 1
  agent_timeout               = null
  args                        = "-cpu kvm64,+cx16,+lahf_lm,+popcnt,+sse3,+ssse3,+sse4.1,+sse4.2"
  automatic_reboot            = true
  bios                        = "seabios"
  boot                        = "order=scsi0;ide2"
  cores                       = each.value.type == "worker" ? 3 : 2
  define_connection_info      = false
  desc                        = ""
  force_create                = false
  force_recreate_on_change_of = null
  full_clone                  = false
  hagroup                     = ""
  hastate                     = ""
  hotplug                     = "network,disk,usb"
  ipconfig0                   = null
  ipconfig1                   = null
  ipconfig10                  = null
  ipconfig11                  = null
  ipconfig12                  = null
  ipconfig13                  = null
  ipconfig14                  = null
  ipconfig15                  = null
  ipconfig2                   = null
  ipconfig3                   = null
  ipconfig4                   = null
  ipconfig5                   = null
  ipconfig6                   = null
  ipconfig7                   = null
  ipconfig8                   = null
  ipconfig9                   = null
  kvm                         = true
  memory                      = 4096
  name                        = "talos-${each.key}"
  nameserver                  = null
  numa                        = false
  onboot                      = true
  os_network_config           = null
  os_type                     = null
  pool                        = "talos"
  protection                  = false
  pxe                         = null
  qemu_os                     = "l26"
  scsihw                      = "virtio-scsi-single"
  searchdomain                = null
  skip_ipv4                   = null
  skip_ipv6                   = null
  sockets                     = 1
  ssh_forward_ip              = null
  ssh_private_key             = null # sensitive
  ssh_user                    = null
  sshkeys                     = null
  startup                     = ""
  tablet                      = true
  tags                        = ""
  target_node                 = null
  target_nodes                = ["pve"]
  vm_state                    = "started"
  vmid                        = each.value.id
  serial {
    id = 0
    type = "socket"
  }
  disks {
    ide {
      ide2 {
        cdrom {
          iso         = "local:iso/talos-3.iso"
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          asyncio              = ""
          backup               = true
          cache                = ""
          discard              = false
          emulatessd           = false
          format               = "raw"
          iops_r_burst         = 0
          iops_r_burst_length  = 0
          iops_r_concurrent    = 0
          iops_wr_burst        = 0
          iops_wr_burst_length = 0
          iops_wr_concurrent   = 0
          iothread             = true
          mbps_r_burst         = 0
          mbps_r_concurrent    = 0
          mbps_wr_burst        = 0
          mbps_wr_concurrent   = 0
          readonly             = false
          replicate            = true
          serial               = ""
          size                 = each.value.type == "control" ? "32G" : "64G"
          storage              = "disk1"
          wwn                  = ""
        }
      }
    }
  }
  network {
    bridge    = "vmbr0"
    firewall  = false
    id        = 0
    link_down = false
    macaddr   = each.value.mac
    model     = "virtio"
    mtu       = 0
    queues    = 0
    rate      = 0
    tag       = 0
  }
  smbios {
    family       = ""
    manufacturer = ""
    product      = ""
    serial       = ""
    sku          = ""
    uuid         = each.value.smbios_uuid
    version      = ""
  }
}
