IFS='
'
for i in `ansible-vault view secrets/secrets.txt`
do
    [[ "$i" =~ ^#.*$ ]] && continue
    export $i
done