path "auth/token/lookup-accessor" {
  capabilities = ["update"]
}

path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}

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