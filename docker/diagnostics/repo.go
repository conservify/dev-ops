package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
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
		return nil, fmt.Errorf("error reading directory: %v", err)
	}

	for _, e := range entries {
		if !e.IsDir() {
			continue
		}

		metaPath := filepath.Join(r.Path, e.Name(), "meta.json")
		meta, err := readMeta(metaPath)
		if err != nil {
			log.Printf("malformed: %v", metaPath)
			continue
		}

		devicePath := filepath.Join(r.Path, e.Name(), "device.json")
		device, err := readDevice(devicePath)
		if err != nil {
			log.Printf("malformed: %v", devicePath)
			continue
		}

		size, err := sizeOfDirectory(filepath.Join(r.Path, e.Name()))
		if err != nil {
			return nil, fmt.Errorf("error getting repo %v size: %v", e.Name(), err)
		}

		files, err := getFiles(filepath.Join(r.Path, e.Name()))
		if err != nil {
			return nil, fmt.Errorf("error getting repo %v files: %v", e.Name(), err)
		}

		a = append(a, &Archive{
			ID:       e.Name(),
			Time:     meta.Time,
			Files:    files,
			Phrase:   meta.Phrase,
			Device:   device,
			Size:     size,
			Location: "/archives/" + e.Name(),
			Path:     filepath.Join(r.Path, e.Name()),
		})
	}

	sort.Sort(ByTime(a))

	log.Printf("index: %d files", len(a))

	return
}

func (r *Repository) FindByQuery(ctx context.Context, query string) (archives []*Archive, err error) {
	archives = make([]*Archive, 0)

	all, err := r.ListAll(ctx)
	if err != nil {
		return nil, err
	}

	for _, a := range all {
		if strings.Contains(a.Phrase, query) {
			archives = append(archives, a)
		}
	}

	return
}

func (r *Repository) FindByID(ctx context.Context, id string) (archive *Archive, err error) {
	all, err := r.ListAll(ctx)
	if err != nil {
		return nil, err
	}

	for _, a := range all {
		if a.ID == id {
			return a, nil
		}
	}

	return
}

func (r *Repository) FindZipByID(ctx context.Context, id string) (path string, err error) {
	archive, err := r.FindByID(ctx, id)
	if err != nil {
		return "", err
	}

	_ = archive

	return
}

func readMeta(path string) (meta *UploadMeta, err error) {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		meta = &UploadMeta{}
		return meta, nil
	}
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

func readDevice(path string) (meta map[string]interface{}, err error) {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		meta = make(map[string]interface{})
		return meta, nil
	}
	rawMeta, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("error: %v", err)
	}
	meta = make(map[string]interface{})
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

func getFiles(path string) (files []*ArchiveFile, err error) {
	entries, err := ioutil.ReadDir(path)
	if err != nil {
		return nil, err
	}

	files = make([]*ArchiveFile, 0)

	for _, e := range entries {
		if !e.IsDir() {
			files = append(files, &ArchiveFile{
				Name: e.Name(),
				Size: e.Size(),
			})
		}
	}

	return
}
