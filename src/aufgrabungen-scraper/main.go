package main

import (
	"encoding/csv"
	"fmt"
	"net/http"

	"github.com/paulmach/go.geojson"
)

var aufgrabungenCSVUrl string = "https://www.stadt-muenster.de/ows/mapserv621/odaufgrabserv?REQUEST=GetFeature&SERVICE=WFS&VERSION=1.1.0&TYPENAME=aufgrabungen&srsname=epsg:4326&outputformat=csv"

func readCSVFromUrl(url string) ([][]string, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()
	reader := csv.NewReader(resp.Body)

	data, err := reader.ReadAll()
	if err != nil {
		return nil, err
	}

	return data, nil
}

func main() {
	data, err := readCSVFromUrl(aufgrabungenCSVUrl)
	if err != nil {
		panic(err)
	}

	featureCollection := geojson.NewFeatureCollection()

	for idx, row := range data {

		// skip header
		if idx == 0 {
			continue
		}

		feature, err := CsvRowToGeoJSON(row)
		if err != nil {
			fmt.Println(err)
		}

		featureCollection.AddFeature(feature)
	}

	json, err := featureCollection.MarshalJSON()
	if err != nil {
		fmt.Println(err)
	}

	fmt.Println(string(json))
}
