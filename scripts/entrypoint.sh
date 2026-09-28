#!/bin/sh

/usr/local/bin/mysql.sh &
mysql_pid=$!

/usr/local/bin/splunk.sh || exit 1

wait "$mysql_pid"
