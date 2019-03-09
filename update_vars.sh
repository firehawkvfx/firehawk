IFS='
'
for i in `ansible-vault view ansible/group_vars/all/secrets.txt`
do
    [[ "$i" =~ ^#.*$ ]] && continue
    export $i
done