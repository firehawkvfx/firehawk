provider "vault" {}

resource "vault_auth_backend" "example" {
  type = "userpass"
}