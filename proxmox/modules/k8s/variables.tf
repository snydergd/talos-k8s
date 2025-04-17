variable "cluster_name" {
  description = "A name to provide for the Talos cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "The endpoint for the Talos cluster"
  type        = string
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
}

