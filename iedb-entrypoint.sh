#! /bin/sh

set -e

mkdir /mysqldata
cd /mysqldata
tar --use-compress-program pigz -xvvf /root/iedb_public.tar.gz
chown -R mysql:mysql /mysqldata
ln -s /mysqldata/iedb_public /var/lib/mysql/iedb_public
docker-entrypoint.sh $@
