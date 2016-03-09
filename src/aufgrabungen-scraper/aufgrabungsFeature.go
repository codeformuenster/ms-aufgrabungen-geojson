package main

import (
	"fmt"
	"strconv"
	"time"

	"github.com/mb0/wkt"
	"github.com/paulmach/go.geojson"
)

var dummyFeature = geojson.NewFeature(geojson.NewPointGeometry([]float64{1, 1}))

func wktPolygonToGeoJSON(wktPolygon *wkt.Polygon) *geojson.Geometry {
	var poly [][][]float64

	for _, coords := range wktPolygon.Rings {
		var ring [][]float64
		for _, coord := range coords {
			ring = append(ring, []float64{coord.X, coord.Y})
		}
		poly = append(poly, ring)
	}

	return geojson.NewPolygonGeometry(poly)
}

func wktMultiPolygonToGeoJSON(wktMultiPolygon *wkt.MultiPolygon) *geojson.Geometry {
	var multiPoly [][][][]float64

	for _, polygon := range wktMultiPolygon.Polygons {
		var poly [][][]float64
		for _, coords := range polygon {
			var ring [][]float64
			for _, coord := range coords {
				ring = append(ring, []float64{coord.X, coord.Y})
			}
			poly = append(poly, ring)
		}
		multiPoly = append(multiPoly, poly)
	}

	return geojson.NewMultiPolygonGeometry(multiPoly...)
}

func CsvRowToGeoJSON(row []string) (*geojson.Feature, error) {
	wktGeometry, err := wkt.Parse([]byte(row[0]))
	if err != nil {
		return dummyFeature, err
	}

	var geojsonGeometry *geojson.Geometry
	switch wktGeom := wktGeometry.(type) {
	default:
		err := fmt.Errorf("%T is not supported!\n", wktGeom)
		return dummyFeature, err
	case *wkt.Polygon:
		geojsonGeometry = wktPolygonToGeoJSON(wktGeom)
	case *wkt.MultiPolygon:
		geojsonGeometry = wktMultiPolygonToGeoJSON(wktGeom)
	}

	feature := geojson.NewFeature(geojsonGeometry)

	// id, cast to int
	idProperty, err := strconv.Atoi(row[1])
	if err != nil {
		return dummyFeature, err
	}
	feature.SetProperty("id", idProperty)

	// beginn, parse to time
	beginnProperty, err := time.Parse("2006/01/02 15:04:05", row[5])
	if err != nil {
		return dummyFeature, err
	}
	feature.SetProperty("beginn", beginnProperty)

	feature.SetProperty("vtraeger", row[2])
	feature.SetProperty("strassen", row[3])
	feature.SetProperty("spuren", row[4])

	return feature, nil
}
