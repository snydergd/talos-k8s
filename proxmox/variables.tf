variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
  default = "proxmox-talos-cluster"
}

variable "cluster_endpoint" {
  description = "The endpoint for the Talos cluster"
  type        = string
  default = "talos-control1"
}

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

