#!/bin/bash

function get_cert_fingerprint { # get the fingerprint for a pfx file
  local -r file_path="$1"
  current_fingerprint="$(openssl pkcs12 -in $file_path -nodes -passin pass: |openssl x509 -noout -fingerprint)"
  current_fingerprint=($current_fingerprint)
  current_fingerprint=${current_fingerprint[1]}
  current_fingerprint="$(echo $current_fingerprint | awk -F '=' '{print $2}')"
  echo "$current_fingerprint"
}

get_cert_fingerprint "$1"