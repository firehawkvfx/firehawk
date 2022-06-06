# when using the vault_token terraform resource we need to be able to renew and revoke tokens

path "auth/token/lookup-accessor" {
  capabilities = ["update"]
}

path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}

# path "dev/data/user"
# {
#   capabilities = ["create", "read", "update", "delete", "list"]
# }

# provide ability to read stored vpn file paths

path "dev/data/vpn/client_cert_files/usr/local/openvpn_as/scripts/seperate/*" 
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "green/data/vpn/client_cert_files/usr/local/openvpn_as/scripts/seperate/*" 
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "blue/data/vpn/client_cert_files/usr/local/openvpn_as/scripts/seperate/*" 
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "main/data/vpn/client_cert_files/usr/local/openvpn_as/scripts/seperate/*" 
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

# provide ability to retrieve private ip address

path "dev/data/vpn/onsite_private_vpn_ip" 
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "blue/data/vpn/onsite_private_vpn_ip" 
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "green/data/vpn/onsite_private_vpn_ip" 
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "main/data/vpn/onsite_private_vpn_ip" 
{
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "transit/encrypt/vpn_client" {
   capabilities = [ "update" ]
}

path "transit/decrypt/vpn_client" {
   capabilities = [ "update" ]
}