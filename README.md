# Aufgrabungsmeldung Stadt Münster as GeoJSON API

The City of Münster provides an open dataset of road works through [govdata.de](https://www.govdata.de). Unfortunately this data is published as esri shapefile as a download.

This project uses the power of several open source projects to create an API out of this shapefile. These technologies are
- [Docker](http://docker.com/) and [docker-compose](http://docs.docker.com/compose/)
- [ogr2ogr (Part of gdal)](http://www.gdal.org/ogr2ogr.html) for converting the shapefile
- [PostgreSQL](http://www.postgresql.org/)/[PostGIS](http://postgis.net/) in the excellent Docker container [mdillon/postgis:9.4](https://registry.hub.docker.com/u/mdillon/postgis/)
- [PostgREST](https://github.com/begriffs/postgrest) for providing a HTTP REST endpoint
- [nginx](http://nginx.org/)


## Querying

The data can be accessed through making HTTP get calls. See the [PostgREST documentation](https://github.com/begriffs/postgrest/wiki/Routing#json-columns) about JSON querying.

For example:
- get all data before a certain point in time: `/aufgrabungen?properties->>beginn=lt.2012-01-01`
- get all data for streetnames like `/aufgrabungen?properties->>strassen=ilike.*weg`
-

## Data license

The data provided is licensed under the [Data licence Germany – attribution – Version 1.0](https://www.govdata.de/dl-de/by-1-0). Data provider is the [Tiefbaumat of the City of Münster](http://www.muenster.de/stadt/tiefbauamt/)
