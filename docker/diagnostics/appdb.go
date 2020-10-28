package main

import (
	"database/sql"
	"encoding/base64"

	_ "github.com/mattn/go-sqlite3"

	"github.com/golang/protobuf/proto"

	pb "github.com/fieldkit/app-protocol"
)

type Station struct {
	DeviceID    string      `json:"device_id"`
	Generation  string      `json:"generation"`
	Name        string      `json:"name"`
	StatusReply interface{} `json:"status_reply"`
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
	rows, err := adb.DB.Query("SELECT device_id, generation_id, name, serialized_status FROM stations")
	if err != nil {
		return nil, err
	}

	stations = make([]*Station, 0)

	var id string
	var name string
	var generation string
	var serializedStatus string

	for rows.Next() {
		rows.Scan(&id, &generation, &name, &serializedStatus)

		reply := &pb.HttpReply{}

		if len(serializedStatus) > 0 {
			encoded, err := base64.StdEncoding.DecodeString(serializedStatus)
			if err != nil {
				return nil, err
			}

			buf := proto.NewBuffer(encoded)
			buf.DecodeVarint()
			err = buf.Unmarshal(reply)
			if err != nil {
				return nil, err
			}
		}

		stations = append(stations, &Station{
			DeviceID:    id,
			Generation:  generation,
			Name:        name,
			StatusReply: reply,
		})
	}

	return
}
