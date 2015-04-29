FROM debian:jessie

RUN rm /etc/localtime && ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime

RUN apt-get update && apt-get install --no-install-recommends -y postgresql-client ca-certificates unzip curl gdal-bin && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -L https://github.com/odise/go-cron/releases/download/v0.0.6/go-cron-linux.gz \
    | zcat > /usr/local/bin/go-cron \
  && chmod u+x /usr/local/bin/go-cron

COPY dl-and-convert.sh /

CMD ["go-cron", "0 0 1 * * *", "/bin/bash", "dl-and-convert.sh"]
