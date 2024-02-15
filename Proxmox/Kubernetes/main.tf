# Local ssh_private_key used for provisioner "remote-exec" aftermath. You should never leave your private key in the open. 
data "local_file" "ssh_private_key" {
  filename = "./id_rsa"
}

resource "proxmox_virtual_environment_vm" "k8s-node" {
  count = 1 # Number of nodes you want to create
  name = "k8s-node-${format("%0000d", 1000 + count.index + 1)}"
  description = "Managed by Terraform"
  tags = ["terraform", "ubuntu"]
  node_name = "<your_proxmox_node_name>"
  vm_id = "${format("%0000d", 1000 + count.index + 1)}"
  

  agent {
    enabled = true
    timeout = "1m"
  }

  connection {
    type        = "ssh"
    agent       = false
    host        = element(element(self.ipv4_addresses, index(self.network_interface_names, "eth0")), 0)
    private_key = data.local_file.ssh_private_key.content
    user        = "ubuntu"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "sudo hostnamectl set-hostname k8s-node-${format("%0000d", 1000 + count.index + 1)}"
    ]
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }

  network_device {
    bridge = "vmbr0"
    
  }

  initialization {

    
    interface = "ide0"

    ip_config {
      
      ipv4 {
        address = "dhcp"
        
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id # Launching the cloud-config
    
  }

  disk {
    datastore_id = "<your_datastore_id>"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "scsi0"
    file_format  = "raw"
    discard      = "on"
    size         = 20
  }
}

resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "proxmox"
  file_name = "ubuntu-22.04-server-cloudimg-amd64.img"

  url = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
}