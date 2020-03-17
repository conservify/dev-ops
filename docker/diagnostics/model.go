package main

import (
	"time"
)

type ArchiveFile struct {
	Name string `json:"name"`
	Size int64  `json:"size"`
}

type Archive struct {
	ID       string                 `json:"id"`
	Time     time.Time              `json:"time"`
	Files    []*ArchiveFile         `json:"files"`
	Phrase   string                 `json:"phrase"`
	Device   map[string]interface{} `json:"device"`
	Size     int64                  `json:"size"`
	Location string                 `json:"location"`
	Path     string                 `json:"-"`
}

type IndexResponse struct {
	Archives []*Archive `json:"archives"`
}

type UploadMeta struct {
	Phrase string    `json:"phrase"`
	Batch  string    `json:"batch"`
	Time   time.Time `json:"time"`
}

type LoginPayload struct {
	User     string `json:"user"`
	Password string `json:"password"`
}

type User struct {
	User     string `json:"user"`
	Password string `json:"password"`
}

type ByTime []*Archive

func (s ByTime) Len() int {
	return len(s)
}

func (s ByTime) Swap(i, j int) {
	s[i], s[j] = s[j], s[i]
}

func (s ByTime) Less(i, j int) bool {
	return s[i].Time.After(s[j].Time)
}
