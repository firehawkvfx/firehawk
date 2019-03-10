IFS='
'
for i in `ansible-vault view --vault-id /vagrant/keys/.vault-key /vagrant/secrets/secrets.txt`
do
    [[ "$i" =~ ^#.*$ ]] && continue
    export $i
done