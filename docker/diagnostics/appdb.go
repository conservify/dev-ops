package main

import (
	"database/sql"

	_ "github.com/mattn/go-sqlite3"
)

type Station struct {
	DeviceID   string `json:"device_id"`
	Generation string `json:"generation"`
	Name       string `json:"name"`
}

type ApplicationDB struct {
	DB   *sql.DB
	Path string
}

func NewApplicationDB(path string) (adb *ApplicationDB, err error) {
	database, err := sql.Open("sqlite3", path)
	if err != nil {
		return nil, err
	}

	adb = &ApplicationDB{
		Path: path,
		DB:   database,
	}

	return
}

func (adb *ApplicationDB) ListStations() (stations []*Station, err error) {
	rows, err := adb.DB.Query("SELECT device_id, generation_id, name FROM stations")
	if err != nil {
		return nil, err
	}

	stations = make([]*Station, 0)

	var id string
	var name string
	var generation string

	for rows.Next() {
		rows.Scan(&id, &generation, &name)

		stations = append(stations, &Station{
			DeviceID:   id,
			Generation: generation,
			Name:       name,
		})
	}

	return
}
