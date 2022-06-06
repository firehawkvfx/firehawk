provider "vault" {}

### SSH key signing for machines that wish to ssh to other known hosts ###

resource "vault_mount" "ssh_signer" {
  path        = "ssh-client-signer"
  type        = "ssh"
  description = "The SSH key signer certifying machines to authenticate ssh sessions"
}

resource "vault_ssh_secret_backend_ca" "ssh_signer_ca" {
  backend              = vault_mount.ssh_signer.path
  generate_signing_key = true
}

resource "vault_ssh_secret_backend_role" "ssh_role" {
  name                    = "ssh-role"
  backend                 = vault_mount.ssh_signer.path
  allow_user_certificates = true
  allowed_users           = "*"
  allowed_extensions      = "permit-pty,permit-port-forwarding"
  default_extensions = tomap({
    "permit-pty"              = "",
    "permit-agent-forwarding" = "",
    "permit-port-forwarding"  = "",
    "valid_principals" : "centos,ubuntu"
  })
  key_type         = "ca"
  default_user     = "centos"
  algorithm_signer = "rsa-sha2-256"
  # valid_principals= "ubuntu,centos"
  # ttl = "30m0s"
  ttl = "720h"
  # cidr_list     = "0.0.0.0/0"
}

### SSH key signing for machines to be recognised as known hosts ### # note need to use rsa-sha2-256 now https://ibug.io/blog/2020/04/ssh-8.2-rsa-ca/

resource "vault_mount" "ssh_host_signer" {
  path        = "ssh-host-signer"
  type        = "ssh"
  description = "The SSH host key signer enabling machines to be recognised certified known hosts"
}

resource "vault_ssh_secret_backend_ca" "ssh_host_signer_ca" {
  backend              = vault_mount.ssh_host_signer.path
  generate_signing_key = true
}

resource "vault_ssh_secret_backend_role" "host_role" {
  name                    = "hostrole"
  backend                 = vault_mount.ssh_host_signer.path
  key_type                = "ca"
  ttl                     = "87600h"
  max_ttl                 = "87600h"
  allow_host_certificates = true
  allowed_domains         = "localdomain,consul,${var.aws_external_domain}"
  algorithm_signer        = "rsa-sha2-256"
  allow_subdomains        = true
}