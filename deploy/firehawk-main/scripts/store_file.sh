#!/bin/bash

set -e
set -x
# exec > >(tee -a /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

function store_file {
  local -r file_path="$1"
  local -r target="$2"
  local -r resourcetier="$3"
  local -r vault_addr="$4"

  if sudo test -f "$file_path"; then
    echo "Get file content at path: $file_path"
    # $file_content="$(sudo cat $file_path | base64 -w 0)"
    vault kv put -address="$vault_addr" "$target/file" value="$(sudo cat $file_path | base64 -w 0)"

    if [[ "$OSTYPE" == "darwin"* ]]; then # Acquire file permissions.
        octal_permissions=$(sudo stat -f %A $file_path | rev | sed -E 's/^([[:digit:]]{4})([^[:space:]]+)/\1/' | rev ) # clip to 4 zeroes
    else
        octal_permissions=$(sudo stat --format '%a' $file_path | rev | sed -E 's/^([[:digit:]]{4})([^[:space:]]+)/\1/' | rev) # clip to 4 zeroes
    fi
    octal_permissions=$( python3 -c "print( \"$octal_permissions\".zfill(4) )" ) # pad to 4 zeroes
    file_uid="$(sudo stat --format '%u' $file_path)"
    file_gid="$(sudo stat --format '%g' $file_path)"
    blob="{ \
      \"permissions\":\"$octal_permissions\", \
      \"owner\":\"$(sudo id -un -- $file_uid)\", \
      \"uid\":\"$file_uid\", \
      \"gid\":\"$file_gid\", \
      \"format\":\"base64\" \
    }"
    parsed_metadata=$( echo "$blob" | jq -c -r '.' )
    vault kv put -address="$vault_addr" -format=json "$target/permissions" value="$parsed_metadata"

    # the certificate can be stored with secrets manager for systems that are unable to use ssh certificates (Windows powershell)
    echo "Will store file with SSM Secrets Manager"
    echo "Setting string..."
    blob="{ \
      \"file\" : \"$(sudo cat $file_path | base64 -w 0)\", \
      \"permissions\" : $parsed_metadata \
    }"
    echo "Parsing string with jq..."
    store=$(echo "$blob" | jq -r '.') && exit_status=0 || exit_status=$?
    
    if [[ ! $exit_status -eq 0 ]]; then
      echo ""
      echo "Error: formatting json to store token with jq:"
      echo "jq returned: $store"
      exit 1
    fi

    aws secretsmanager put-secret-value \
        --secret-id "/firehawk/resourcetier/$resourcetier/file_deadline_cert" \
        --secret-string "$store"
  else
    echo "Error: file not found: $file_path"
    exit 1
  fi
}

store_file "$1" "$2" "$3" "$4"