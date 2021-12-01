FROM mariadb:10.6
COPY iedb_public.tar.gz /root
RUN apt-get update -q && apt-get install -qqy pigz
COPY iedb-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/iedb-entrypoint.sh
ENTRYPOINT ["iedb-entrypoint.sh"]
CMD ["mysqld"]
