Softnas Command Line Notes

#to import an existing s3 disk, login with softnas-cmd, then-
#sudo /var/www/softnas/scripts/s3disk.sh --import --dname s3-1 --bname softnas-27944-s3disk-1 --bsize 500 --region ap-southeast-2 --encrypt $someRandomPass

#to create a new s3 disk, login with softnas-cmd, then-
#sudo /var/www/softnas/scripts/s3disk.sh --create --dname s3-2 --bname softnas-bucket-0003 --bsize 500 --encrypt $someRandomPass

#how to create a pool, login with softnas-cmd, then-
#softnas-cmd createpool /dev/s3-0:/dev/s3-1:/dev/s3-2 -n=pool1 -r=0 -f=on -sync=standard -cs=off -t

#if dynamically creating a volume, login with softnas-cmd, then-
#softnas-cmd createvolume vol_name=volume1 pool=pool1 vol_type=filesystem provisioning=thin exportNFS=on dedup=off enable_snapshot=off sync=always replication=off