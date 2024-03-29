variable "virtual_environment_endpoint" {
  type = string
  description = "The endpoint for the Proxmox Virtual Environment API (example: https://host:port)"
}

variable "virtual_environment_token" {
  type = string
  description = "The token for the Proxmox Virtual Environment API"
}

variable "virtual_environment_username" {
  type = string
  description = "The username for the Proxmox Virtual Environment API"
}

variable "virtual_environment_password" {
  type = string
  description = "The password for the Proxmox Virtual Environment API"

}
