#!/bin/sh

if [ ! -d /var/lib/mysql/mysql ]; then
    mysqld --initialize-insecure --user=mysql || exit 1
fi

exec mysqld --user=mysql --bind-address=127.0.0.1
