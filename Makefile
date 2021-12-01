dump:
	@curl -sSL "https://www.iedb.org/downloader.php?file_name=doc/iedb_public.sql.gz" -o iedb_public.sql.gz
	@rm -rf mysqldata; mkdir mysqldata
	@docker rm -f iedb-public-dump 2>/dev/null || true
	@docker run \
		--name=iedb-public-dump \
		-e MYSQL_DATABASE=iedb_public \
		-e MYSQL_ALLOW_EMPTY_PASSWORD=yes \
		--volume=$(shell pwd)/mysqldata:/var/lib/mysql \
		--volume=$(shell pwd)/iedb_public.sql.gz:/docker-entrypoint-initdb.d/data.sql.gz \
		-d mariadb:10.6
	@bash -c 'while [ -z "`docker logs --tail 40 iedb-public-dump 2>&1 | grep "Ready for start up"`" ]; do echo -ne "\r`du -sh mysqldata 2>&1`"; sleep 5; done'
	@docker rm -f iedb-public-dump 2>/dev/null || true
	@cd mysqldata; tar --use-compress-program $(shell which pigz || echo "gzip") -cvvof ../iedb_public.tar.gz iedb_public

build:
	@docker build . -t hivdb/iedb-public:latest

release:
	@docker push hivdb/iedb-public:latest

run:
	@docker network create iedb-public-mysql 2>/dev/null || true
	$(eval volumes = $(shell docker inspect -f '{{ range .Mounts }}{{ .Name }}{{ end }}' iedb-public))
	@docker rm -f iedb-public 2>/dev/null || true
	@docker rm -f iedb-public-phpmyadmin 2>/dev/null || true
	@docker volume rm $(volumes) 2>/dev/null || true
	@docker pull hivdb/iedb-public:latest
	@docker run \
		--name iedb-public \
		--net iedb-public-mysql \
		-e MYSQL_DATABASE=iedb_public \
		-e MYSQL_ALLOW_EMPTY_PASSWORD=yes \
		-d -it --publish=127.0.0.1:3308:3306 hivdb/iedb-public:latest
	@docker run \
		--name iedb-public-phpmyadmin \
		--net iedb-public-mysql \
		-e PMA_HOST=iedb-public \
		-d -p 127.0.0.1:2300:80 phpmyadmin/phpmyadmin:latest
	@sleep 4
	@open http://127.0.0.1:2300

log:
	@docker logs -f iedb-public


.PHONY: dump build release run logs
