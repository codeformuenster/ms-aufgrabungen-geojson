FROM debian:jessie

RUN rm /etc/localtime && ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

RUN apt-get update && apt-get install --no-install-recommends -y postgresql-client ca-certificates unzip curl gdal-bin && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -L https://github.com/odise/go-cron/releases/download/v0.0.6/go-cron-linux.gz \
    | zcat > /usr/local/bin/go-cron \
  && chmod u+x /usr/local/bin/go-cron

RUN curl -L https://raw.githubusercontent.com/naquad/shmig/a06917d0ecf3e198c4416e4f6caa8580b73e0f97/shmig > /usr/local/bin/shmig \
  && chmod u+x /usr/local/bin/shmig

COPY migrations /migrations
COPY convert.sh .
COPY go-cron.sh /usr/local/bin/

CMD ["go-cron.sh"]

