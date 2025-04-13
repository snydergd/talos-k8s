variable "nodes" {
  type = list(
    object({
      mac     = string
      id      = number
      type    = string
      index   = number
      smbios_uuid = string
    })
  )
  default = [
      {
        id = 103
        type = "control"
        index = 1
        mac = "d2:6b:07:67:8f:a4"
        smbios_uuid = "b848e2dd-c9f9-46d7-ab8d-f1491fdcc141"
      },
      {
        id = 109
        type = "control"
        index = 2
        mac = "de:ad:25:3f:1d:29"
        smbios_uuid = "79802d79-d4ad-4c3b-a1c2-241581b921b3"
      },
      {
        id = 110
        type = "control"
        index = 3
        name = "control3"
        mac = "02:1c:1b:bf:a5:33"
        smbios_uuid = "52609137-79c4-4d3e-98a0-c9e5798b1a4f"
      },
      {
        id = 105
        type = "worker"
        index = 1
        mac = "0e:e0:aa:7c:5a:f7"
        smbios_uuid = "7a71385c-e928-4a83-9f98-7725d24d56da"
      },
      {
        id = 104
        type = "worker"
        index = 2
        mac = "6e:24:28:9d:5f:59"
        smbios_uuid = "6cbf1a4f-54bf-4a82-9151-207a44e34a1d"
      },
      {
        id = 107
        type = "worker"
        index = 3
        mac = "26:b4:22:3d:8b:fd"
        smbios_uuid = "23694662-adce-4295-8cd0-ed7007235cd0"
      },
  ]
}

resource "proxmox_pool" "talos" {
  poolid = "talos"
	comment = "Talos k8s cluster"
}

resource "proxmox_vm_qemu" "nodes" {
  for_each = { for i, node in var.nodes : "${node.type}${node.index}" => node }

  additional_wait             = null
  agent                       = 1
  agent_timeout               = null
  args                        = "-cpu kvm64,+cx16,+lahf_lm,+popcnt,+sse3,+ssse3,+sse4.1,+sse4.2"
  automatic_reboot            = false
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
  vm_state                    = "running"
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
