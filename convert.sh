#!/bin/bash

URL=https://www.citeq.de/datexup/uploads/opendata/aufbrueche.zip
TODAY=`date --iso-8601`
ZIP_FILENAME=$TODAY.zip

# migrate database if necessary
shmig -t postgresql -d postgres -l postgres -H postgis -p ${POSTGIS_ENV_POSTGRES_PASSWORD} up

# download todays shapefile
curl --silent --output "$ZIP_FILENAME" "$URL"

# unzip it
unzip -q $ZIP_FILENAME -d tmp

# read and put into postgis
export SHAPE_ENCODING="" # no recoding, http://www.mail-archive.com/gdal-dev@lists.osgeo.org/msg12322.html
ogr2ogr -skipfailures -update -append -nlt POLYGON -t_srs crs:84 -f "PostGreSQL" PG:"host=postgis user=postgres dbname=postgres password=${POSTGIS_ENV_POSTGRES_PASSWORD}" tmp/aufbrueche.shp

# cleanup
rm -rf tmp $ZIP_FILENAME
