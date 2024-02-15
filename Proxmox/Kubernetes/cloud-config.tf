data "local_file" "ssh_public_key" {
  filename = "./id_rsa.pub"
}

resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "<enter_your_datastore_id>" 
  node_name    = "proxmox"
  # Check if your datastore supports snippets at Datacenter -> Storage -> Your_datastore -> Content
    

  source_raw {
    data = <<EOF
#cloud-config
users:
  - default
  - name: ubuntu
    shell: /bin/bash
    ssh_authorized_keys:
      - ${trimspace(data.local_file.ssh_public_key.content)}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    shell: /bin/bash

package_update: true
package_upgrade: true
packages:
  # Update the apt package index and install packages needed to use the Docker and Kubernetes apt repositories over HTTPS
  - apt-transport-https
  - ca-certificates
  - curl
  - gpg

# Let iptables see bridged traffic
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#letting-iptables-see-bridged-traffic
write_files:
 - path: /etc/modules-load.d/k8s.conf
   content: |
    overlay
    br_netfilter  
 
 - path: /etc/sysctl.d/k8s.conf
   content: |
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1

runcmd:
 - sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
 - sed -i -e '$aAllowUsers ubuntu' /etc/ssh/sshd_config
 - restart ssh
 - apt update
 - apt install -y qemu-guest-agent net-tools
 - timedatectl set-timezone Europe/Zagreb
 - systemctl enable qemu-guest-agent
 - systemctl start qemu-guest-agent
 - swapoff -a # Disable swap
 - wget https://github.com/containerd/containerd/releases/download/v1.7.2/containerd-1.7.2-linux-amd64.tar.gz
 - tar Cxzvf /usr/local containerd-1.7.2-linux-amd64.tar.gz
 - wget https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64
 - install -m 755 runc.amd64 /usr/local/sbin/runc
 - mkdir /etc/containerd
 - containerd config default | sudo tee /etc/containerd/config.toml
 - sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
 - curl -L https://raw.githubusercontent.com/containerd/containerd/main/containerd.service -o /etc/systemd/system/containerd.service
 - systemctl daemon-reload
 - systemctl enable --now containerd
 - modprobe br_netfilter # Load br_netfilter module.
 - curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg # Download the Google Cloud public signing key:
 - echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list # Add the Kubernetes apt repository
 - apt-get update -y # Update apt package index
 - apt-get install -y kubelet kubeadm kubectl # Install kubelet, kubeadm and kubectl 
 - apt-mark hold kubelet kubeadm kubectl # pin kubelet kubeadm kubectl version
 - sysctl --system # Reload settings from all system configuration files to take iptables configuration
 - curl -L -o /opt/cni/bin/calico https://github.com/projectcalico/cni-plugin/releases/download/v3.14.0/calico-amd64

 EOF

  file_name = "cloud-config.yaml"
  # Logs from cloud-config are located in /var/log/cloud-init-output.log
  }
  
  # Things to do manually after cloud-config is finished:
  # 1. Generate new token on the control node and then apply them on worker nodes so they could join the cluster
  #    kubeadm token create --print-join-command --ttl=0 
  # 2. Install CNI plugin of your choice
  #
  # 3. Optional, copy the admin.conf from master node so you could utilize kubectl on the worker node
  #    mkdir -p $HOME/.kube
  #    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  #    sudo chown $(id -u):$(id -g) $HOME/.kube/config
  

}