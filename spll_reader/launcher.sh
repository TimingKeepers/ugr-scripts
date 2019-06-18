#!/bin/bash

function clean_up {

    kill $SPLL_PID
    kill $LOG_PID
    exit
}

trap clean_up SIGHUP SIGINT SIGTERM

REMOTE_ADDR=192.168.4.122
FILENAME="noPpsiNoFan"

./../spll_reader -a $REMOTE_ADDR -p 12345 -m -f $FILENAME &
SPLL_PID=$!

./../log_temp.sh $REMOTE_ADDR $FILENAME &
LOG_PID=$!

wait
echo "Finished.\n"
