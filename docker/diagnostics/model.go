package main

import (
	"time"
)

type ArchiveFile struct {
	Name string `json:"name"`
}

type Archive struct {
	ID     string            `json:"id"`
	Time   time.Time         `json:"time"`
	Files  []*ArchiveFile    `json:"files"`
	Phrase string            `json:"phrase"`
	Device map[string]string `json:"device"`
	Size   int64             `json:"size"`
}

type IndexResponse struct {
	Archives []*Archive `json:"archives"`
}
