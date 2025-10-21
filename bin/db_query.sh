#!/bin/bash

# Script to execute SQL queries safely using Docker environment variables

docker compose exec db bash -c 'echo -e "[client]\nuser=$MYSQL_USER\npassword=$MYSQL_PASSWORD" > /tmp/my.cnf && mysql --defaults-extra-file=/tmp/my.cnf $MYSQL_DATABASE --default-character-set=utf8 -e "'"$1"'" && rm /tmp/my.cnf'