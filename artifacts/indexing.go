package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"time"
)

type FileEntry struct {
	Name         string    `json:"name"`
	ModifiedTime time.Time `json:"modified"`
	RelativePath string    `json:"relative"`
	Size         int64     `json:"size"`
	Url          string    `json:"url"`
}

type DirectoryEntry struct {
	Name         string            `json:"name"`
	ModifiedTime time.Time         `json:"modified"`
	RelativePath string            `json:"relative"`
	Url          string            `json:"url"`
	Files        []*FileEntry      `json:"files"`
	Directories  []*DirectoryEntry `json:"directories"`
}

type Index struct {
	Root *DirectoryEntry `json:"root"`
}

type Indexer struct {
}

func NewIndexer() *Indexer {
	return &Indexer{}
}

func createRawIndex(path string, base string) (de *DirectoryEntry, err error) {
	entries, err := ioutil.ReadDir(path)
	if err != nil {
		return nil, err
	}

	info, err := os.Stat(path)
	if err != nil {
		return nil, err
	}

	files := make([]*FileEntry, 0)
	dirs := make([]*DirectoryEntry, 0)
	for _, e := range entries {
		if e.IsDir() {
			sub, err := createRawIndex(filepath.Join(path, e.Name()), base)
			if err != nil {
				return nil, err
			}
			dirs = append(dirs, sub)
		} else {
			relative, err := filepath.Rel(base, filepath.Join(path, e.Name()))
			if err != nil {
				return nil, err
			}
			files = append(files, &FileEntry{
				Name:         e.Name(),
				ModifiedTime: e.ModTime(),
				Size:         e.Size(),
				RelativePath: relative,
				Url:          fmt.Sprintf("http://code.conservify.org/distribution/%s", relative),
			})
		}
	}

	relative, err := filepath.Rel(base, path)
	if err != nil {
		return nil, err
	}
	de = &DirectoryEntry{
		Name:         filepath.Base(path),
		ModifiedTime: info.ModTime(),
		Files:        files,
		Directories:  dirs,
		RelativePath: relative,
		Url:          fmt.Sprintf("http://code.conservify.org/distribution/%s", relative),
	}
	return
}

func (i *Indexer) GenerateFileIndex(directory string) error {
	r, err := createRawIndex(directory, directory)
	if err != nil {
		return err
	}

	index := Index{
		Root: r,
	}

	indexJsonPath := filepath.Join(directory, "index.json")
	bytes, err := json.Marshal(index)

	err = ioutil.WriteFile(indexJsonPath, bytes, 0666)
	if err != nil {
		return err
	}

	return nil
}
