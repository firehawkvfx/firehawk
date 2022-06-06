# This allows a host to revoke tokens.  It allows it to explicitly terminate the token when done using it.
path "auth/token/lookup-accessor" {
  capabilities = ["update"]
}

path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}

# This allows a workstation to dynamically generate its own password on boot, and submit it to Vault for initial login.

path "dev/data/users/*"
{
  capabilities = ["list", "read"]
}

path "dev/data/users/deadlineuser_pw"
{
  capabilities = ["update", "list"]
}