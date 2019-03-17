# the purpose of this script is to:
# 1) set envrionment variables as defined in the encrypted secrets/secrets-prod file
# 2) consistently rebuild the secrets.template file based on the variable names found in the secrets-prod file.
#    This generated template will never/should never have any secrets stored in it since it is commited to version control.
#    The purpose of this script is to ensure that the template for all users remains consistent.
# 3) Example values for the secrets.template file are defined in secrets.example. Ensure you have placed an example key=value for any new vars in secrets.example. 
# If any changes have resulted in a new variable name, then example values helps other understand what they should be using for their own infrastructure.
mkdir -p ./tmp/
# The template will be updated by this script
touch ./secrets.template
rm ./secrets.template
touch ./tmp/secrets.temp
rm ./tmp/secrets.temp

# IFS will allow for lop to iterate over lines instead of words seperated by ' '
IFS='
'
for i in `cat ./secrets.example`
do
    [[ "$i" =~ ^#.*$ ]] && continue
    export $i
done

argument="$1"

# if --init is supplied, no decryption occurs.  otherwise, we assume a key is required.
echo ""
if [[ -z $argument ]] ; then
  echo "No argument supplied. assuming secrets are encrypted, dev environment.  Use --prod for production."
  export TF_VAR_envtier='dev'
  export vault_command="ansible-vault view --vault-id ./keys/.vault-key-$TF_VAR_envtier ./secrets/secrets-$TF_VAR_envtier"
  # Update template
else
  case $argument in
    -d|--dev)
      export TF_VAR_envtier='dev'
      export vault_command="ansible-vault view --vault-id ./keys/.vault-key-$TF_VAR_envtier ./secrets/secrets-$TF_VAR_envtier"
      ;;
    -p|--prod)
      export TF_VAR_envtier='prod'
      export vault_command="ansible-vault view --vault-id ./keys/.vault-key-$TF_VAR_envtier ./secrets/secrets-$TF_VAR_envtier"
      ;;
    *)
      raise_error "Unknown argument: ${argument}"
      return
      ;;
  esac
fi

argument2="$2"

# if --init is supplied, no decryption occurs.  otherwise, we assume a key is required.
echo ""
if [[ -z $argument2 ]] ; then
  echo "No 2nd argument supplied. Secrets will be encrypted by default if not already encrypted"
  echo "Encrypting secrets."
  ansible-vault encrypt --vault-id ./keys/.vault-key-$TF_VAR_envtier ./secrets/secrets-$TF_VAR_envtier
  # Update template
else
  case $argument2 in
    -i|--init)
      echo "Assuming secrets are not encrypted to set environment vars"
      export vault_command="cat ./secrets/secrets-$TF_VAR_envtier"
      ;;
    -u|--decrypt)
      echo "Decrypting secrets. WARNING: Do not commit unencrypted secrets to version control. run this command again without --decrypt before commiting any secrets to version control"
      ansible-vault decrypt --vault-id ./keys/.vault-key-$TF_VAR_envtier ./secrets/secrets-$TF_VAR_envtier
      export vault_command="cat ./secrets/secrets-$TF_VAR_envtier"
      ;;
    -v|--view)
      echo "Ensuring secrets are encrypted."
      ansible-vault encrypt --vault-id ./keys/.vault-key-$TF_VAR_envtier ./secrets/secrets-$TF_VAR_envtier
      echo "Viewing encrypted secrets."
      ansible-vault view --vault-id ./keys/.vault-key-$TF_VAR_envtier ./secrets/secrets-$TF_VAR_envtier
      ;;
    *)
      raise_error "Unknown argument2: ${argument2}"
      return
      ;;
  esac
fi

printf "\nTF_VAR_envtier=$TF_VAR_envtier\n"
printf "vault_command=$vault_command\n"


for i in `eval $vault_command`
do
    if [[ "$i" =~ ^#.*$ ]]
    then
        echo $i >> ./tmp/secrets.temp
    else
        echo ${i%%=*}'=$'${i%%=*} >> ./tmp/secrets.temp
    fi
done

# substitute example var vules into the template.

envsubst < "./tmp/secrets.temp" > "./secrets.template"
rm ./tmp/secrets.temp

# # Now set environment variables to the actual values defined in the user's secrets-prod file
for i in `eval $vault_command`
do
    [[ "$i" =~ ^#.*$ ]] && continue
    export $i
done

# # Determine your current public ip for security groups.

export TF_VAR_remote_ip_cidr="$(dig +short myip.opendns.com @resolver1.opendns.com)/32"

# # this python script generates mappings based on the current environment.
# # any var ending in _prod or _dev will be stripped and mapped based on the envtier
python ./scripts/envtier_vars.py
envsubst < "./tmp/envtier_mapping.txt" > "./tmp/envtier_exports.txt"

# using the current envtier environment, evaluate the variables
for i in `cat ./tmp/envtier_exports.txt`
do
    [[ "$i" =~ ^#.*$ ]] && continue
    export $i
done

rm ./tmp/envtier_exports.txt