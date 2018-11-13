package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
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

func (i *Indexer) DeleteOldBuilds(directory string, maximumAge time.Duration) error {
	archive := filepath.Join(directory, "archive")

	log.Printf("Deleting old builds %s", archive)

	now := time.Now()

	err := walkBuilds(archive, func(path string, relative string, jobName string, buildXmlPath string, info *BuildInfo, artifactPaths []string) error {
		age := now.Sub(time.Unix(info.StartTime/1000, 0))

		if age.Hours() > maximumAge.Hours() {
			log.Printf("DELETING %s %s (%s) (%s)", path, jobName, relative, age)
			if true {
				return nil
			}
			return os.RemoveAll(path)
		}

		return nil
	})
	if err != nil {
		return err
	}

	return nil
}
