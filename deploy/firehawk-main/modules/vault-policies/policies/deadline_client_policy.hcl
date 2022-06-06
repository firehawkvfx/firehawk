# when using the vault_token terraform resource we need to be able to renew and revoke tokens

path "auth/token/lookup-accessor" {
  capabilities = ["update"]
}

path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}

path "dev/data/deadline/client_cert_files/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}
# path "dev/data/deadline/client_cert_files/opt/Thinkbox/certs/*"
# {
#   capabilities = ["create", "read", "update", "delete", "list"]
# }

path "green/data/deadline/client_cert_files/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "blue/data/deadline/client_cert_files/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "main/data/deadline/client_cert_files/*"
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "transit/encrypt/deadline_client" {
   capabilities = [ "update" ]
}
path "transit/decrypt/deadline_client" {
   capabilities = [ "update" ]
}