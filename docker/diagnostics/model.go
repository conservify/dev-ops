package main

import (
	"time"
)

type ArchiveFile struct {
	Name string `json:"name"`
}

type Archive struct {
	ID       string            `json:"id"`
	Time     time.Time         `json:"time"`
	Files    []*ArchiveFile    `json:"files"`
	Phrase   string            `json:"phrase"`
	Device   map[string]string `json:"device"`
	Size     int64             `json:"size"`
	Location string            `json:"location"`
}

type IndexResponse struct {
	Archives []*Archive `json:"archives"`
}

type UploadMeta struct {
	Phrase string    `json:"phrase"`
	Batch  string    `json:"batch"`
	Time   time.Time `json:"time"`
}
