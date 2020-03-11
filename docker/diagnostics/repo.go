package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
)

type Repository struct {
	Path string
}

func NewRepository(path string) (r *Repository, err error) {
	r = &Repository{
		Path: path,
	}
	return
}

func (r *Repository) ListAll(ctx context.Context) (a []*Archive, err error) {
	a = make([]*Archive, 0)

	entries, err := ioutil.ReadDir(r.Path)
	if err != nil {
		return nil, err
	}

	for _, e := range entries {
		meta, err := readMeta(filepath.Join(r.Path, e.Name(), "meta.json"))
		if err != nil {
			return nil, err
		}

		device, err := readDevice(filepath.Join(r.Path, e.Name(), "device.json"))
		if err != nil {
			return nil, err
		}

		size, err := sizeOfDirectory(filepath.Join(r.Path, e.Name()))
		if err != nil {
			return nil, err
		}

		log.Printf("%v", device)

		files := make([]*ArchiveFile, 0)

		a = append(a, &Archive{
			ID:     e.Name(),
			Time:   meta.Time,
			Files:  files,
			Phrase: meta.Phrase,
			Device: device,
			Size:   size,
		})
	}

	log.Printf("index: %d files", len(a))

	return
}

func readMeta(path string) (meta *UploadMeta, err error) {
	rawMeta, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("error: %v", err)
	}
	meta = &UploadMeta{}
	err = json.Unmarshal(rawMeta, meta)
	if err != nil {
		return nil, fmt.Errorf("error: %v", err)
	}
	return
}

func readDevice(path string) (meta map[string]string, err error) {
	rawMeta, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("error: %v", err)
	}
	meta = make(map[string]string)
	err = json.Unmarshal(rawMeta, &meta)
	if err != nil {
		return nil, fmt.Errorf("error: %v", err)
	}
	return
}

func sizeOfDirectory(path string) (int64, error) {
	var size int64
	err := filepath.Walk(path, func(_ string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			size += info.Size()
		}
		return err
	})
	return size, err
}
