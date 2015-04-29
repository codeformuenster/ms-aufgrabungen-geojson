#!/bin/bash

URL=https://www.citeq.de/datexup/uploads/opendata/aufbrueche.zip
TODAY=`date --iso-8601`
ZIP_FILENAME=$TODAY.zip
OUTPUT_DIR=/usr/share/nginx/html/archive
OUTPUT_FILENAME=$TODAY.json

# create output dir
mkdir -p $OUTPUT_DIR

# download todays shapefile
curl --silent --output "$ZIP_FILENAME" "$URL"

# unzip it
unzip -q $ZIP_FILENAME -d tmp

# convert it to geojson, process and minify json
export SHAPE_ENCODING="" # no recoding, http://www.mail-archive.com/gdal-dev@lists.osgeo.org/msg12322.html
ogr2ogr -nlt POLYGON -f GeoJSON -t_srs crs:84 /vsistdout/ tmp/aufbrueche.shp | jq -r -f jq-filters | sed "s/@@date@@/`date --iso-8601=sec`/" > $OUTPUT_DIR/$TODAY.json

# gzip it..
gzip -1 -f -c $OUTPUT_DIR/$TODAY.json > $OUTPUT_DIR/$TODAY.json.gz;

# copy to ../latest.json
cp $OUTPUT_DIR/$TODAY.json $OUTPUT_DIR/../latest.json
cp $OUTPUT_DIR/$TODAY.json.gz $OUTPUT_DIR/../latest.json.gz

# cleanup
rm -rf tmp $ZIP_FILENAME
