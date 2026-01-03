#!/bin/sh
#if any error occurs, exit program
set -e

# Init var
HOST=192.168.1.6
MAC=2c:60:0c:0d:ac:44

#Check duration of backup job (portable)
start=$(date +%s)

#Back up all of lebon & labrute CTs & VMs using sync job on internal backup on lebon
#First power up lepaysan using wakeonlan
wakeonlan $MAC
until ping -c1 $HOST >/dev/null 2>&1; do :; done
echo '------------------------'
echo 'mordor is up and running'
echo '------------------------'
echo

# Push btrbk backups from shire to mordor
btrbk dryrun -c /etc/btrbk/btrbk_mordor.conf

#all bash lines that update the bakcup for the remote backup server are in backup_command.sh
ssh root@$HOST 'bash -s' < /home/bestwave/simplest_homelab/btrbk/command_mordor.sh
#all done, sleep well backup server
echo '-------------------------'
echo 'all done, shutdown mordor'
echo '-------------------------'
echo
ssh root@$HOST 'shutdown; exit'
end_ts=$(date +%s)
duration=$(( end_ts - start ))
printf "Duration of job: %d sec\n" "$duration"