# path "dev/*"
# {
#   capabilities = ["list", "read", "update"]
# }

path "dev/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "dev/data/user"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}