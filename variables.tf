variable "system_type" {
  description = "System type"
  type        = string

  validation {
    condition     = var.system_type == "intel" || var.system_type == "amd"
    error_message = "Valid values for system_type are 'intel' or 'amd'"
  }
}

variable "proxmox" {
  description = "Proxmox configuration for accessing"
  type = object({
    api_endpoint   = string
    username       = string
    password       = string
    ip             = string
    default_bridge = string
    target_node    = string
  })
  default = {
    api_endpoint   = "https://10.0.0.200:8006/api2/json"
    username       = "root"
    password       = "password"
    ip             = "10.0.0.200"
    default_bridge = "vmbr0"
    target_node    = "node-lnc"
  }
}

variable "autostart" {
  description = "Enable/Disable VM start on host bootup"
  type        = bool
}

variable "master_config" {
  description = "Kubernetes master config"
  type = object({
    count   = number
    memory  = string
    vcpus   = number
    sockets = number
  })
}

variable "worker_config" {
  description = "Kubernetes worker config"
  type = object({
    count   = number
    memory  = string
    vcpus   = number
    sockets = number
  })
}

# HA Proxy config
variable "ha_proxy_server" {
  description = "IP address of server running haproxy"
  type        = string
}

variable "ha_proxy_user" {
  description = "User on ha_proxy_server that can modify '/etc/haproxy/haproxy.cfg' and restart haproxy.service"
  type        = string
}

variable "storage_volume" {
  description = "The Proxmox storage volume"
  type        = string
}

variable "machine_id" {
  description = "The Proxmox VM machine ID for the VM template"
  type        = string
}
