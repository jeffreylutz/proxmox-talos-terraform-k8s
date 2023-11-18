
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox.api_endpoint
  pm_user         = "${var.proxmox.username}@pam"
  pm_password     = var.proxmox.password
  pm_tls_insecure = true
}

locals {
}

provider "docker" {}

# resource "docker_image" "imager" {
#   name = "ghcr.io/siderolabs/imager:${local.imager_version}"
# }

resource "null_resource" "cleanup" {
  provisioner "local-exec" {
    command     = "mkdir -p output && rm -f talos_setup.sh haproxy.cfg talosconfig worker.yaml controlplane.yaml"
    working_dir = path.root
  }
}

resource "null_resource" "create_template" {
  # depends_on = [null_resource.copy_image]
  connection {
    type        = "ssh"
    host        = var.proxmox.ip
    user        = var.proxmox.username
    private_key = file("~/.ssh/id_rsa")
  }
  provisioner "file" {
    source      = "${path.root}/scripts/proxmox_create_vm_template.sh"
    destination = "/tmp/proxmox_create_vm_template.sh"
  }
  provisioner "remote-exec" {
    when = create
    inline = [
      "chmod +x /tmp/proxmox_create_vm_template.sh",
      "/tmp/proxmox_create_vm_template.sh ${var.storage_volume} ${var.machine_id}"
    ]
  }
}

module "master_domain" {
  depends_on     = [null_resource.create_template]
  source         = "./modules/domain"
  count          = var.master_config.count
  name           = format("talos-master-%s", count.index)
  memory         = var.master_config.memory
  vcpus          = var.master_config.vcpus
  sockets        = var.master_config.sockets
  autostart      = var.autostart
  default_bridge = var.proxmox.default_bridge
  target_node    = var.proxmox.target_node
}

module "worker_domain" {
  depends_on     = [null_resource.create_template]
  source         = "./modules/domain"
  count          = var.worker_config.count
  name           = format("talos-worker-%s", count.index)
  memory         = var.worker_config.memory
  vcpus          = var.worker_config.vcpus
  sockets        = var.worker_config.sockets
  autostart      = var.autostart
  default_bridge = var.proxmox.default_bridge
  target_node    = var.proxmox.target_node
}
