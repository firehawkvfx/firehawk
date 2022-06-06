# The provisioner policy is for packer instances and other automation that requires read access to vault

path "auth/token/lookup-accessor" {
  capabilities = ["update"]
}

path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}

# path "dev/*"
# {
#   capabilities = ["list", "read"]
# }

path "dev/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "dev/data/user"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "green/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "green/data/user"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "blue/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "blue/data/user"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "main/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "main/data/user"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# This allows the instance to generate certificates

path "pki_int/issue/*" {
    capabilities = ["create", "update"]
}

path "pki_int/certs" {
    capabilities = ["list"]
}

path "pki_int/revoke" {
    capabilities = ["create", "update"]
}

path "pki_int/tidy" {
    capabilities = ["create", "update"]
}

path "pki/cert/ca" {
    capabilities = ["read"]
}

path "auth/token/renew" {
    capabilities = ["update"]
}

path "auth/token/renew-self" {
    capabilities = ["update"]
}