#!/bin/bash

function clean_up {
    exit
}

trap clean_up SIGHUP SIGINT SIGTERM

SSH_OPTIONS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=error"

while : 
do
    dato=$(sshpass -p '' ssh $SSH_OPTIONS root@$1 "/wr/bin/wr_mon -w" | egrep "TEMP|sec")
    # dato=$(echo $dato | awk -F=':' "{print $1 $2}") # >> $2_temp
    echo $dato >> $2_temp
    sleep 1
done
