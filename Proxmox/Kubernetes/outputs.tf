output "k8s-node_id" {
  description = "Node id, starts from 1000> for convenience"
  value = proxmox_virtual_environment_vm.k8s-node.*.id
}

output "k8s-node_ipv4_addresses" {
  description = "Node ipv4 address. Index is 1, becouse default ubuntu server has loopback interface at 0 "
  value = proxmox_virtual_environment_vm.k8s-node.*.ipv4_addresses.1
}