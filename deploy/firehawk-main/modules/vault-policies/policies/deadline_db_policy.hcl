# when using the vault_token terraform resource we need to be able to renew and revoke tokens

path "auth/token/lookup-accessor" {
  capabilities = ["update"]
}

path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}

path "auth/token/renew" {
    capabilities = ["update"]
}

path "auth/token/renew-self" {
    capabilities = ["update"]
}

# The provisioner policy is for packer instances and other automation that requires read access to vault

path "dev/data/deadline/*" # to be deprecated
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "dev/data/deadline/client_cert_files/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "green/data/deadline/*" # to be deprecated
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "green/data/deadline/client_cert_files/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "blue/data/deadline/*" # to be deprecated
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "blue/data/deadline/client_cert_files/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "main/data/deadline/*" # to be deprecated
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "main/data/deadline/client_cert_files/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# path "main/data/user"
# {
#   capabilities = ["create", "read", "update", "delete", "list"]
# }