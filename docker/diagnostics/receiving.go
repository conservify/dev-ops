package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/sethvargo/go-diceware/diceware"
)

func saveOrReadMeta(batch, path string) (meta *UploadMeta, created bool, err error) {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		file, err := os.Create(path)
		if err != nil {
			return nil, false, fmt.Errorf("error: %v", err)
		}

		phrase, err := diceware.Generate(3)

		defer file.Close()

		meta = &UploadMeta{
			Phrase: strings.Join(phrase, " "),
			Batch:  batch,
			Time:   time.Now(),
		}

		bytes, err := json.Marshal(meta)
		if err != nil {
			return nil, false, fmt.Errorf("error: %v", err)
		}

		_, err = file.Write(bytes)
		if err != nil {
			return nil, false, fmt.Errorf("error: %v", err)
		}

		created = true
	} else {
		data, err := ioutil.ReadFile(path)
		if err != nil {
			return nil, false, fmt.Errorf("error: %v", err)
		}

		meta = &UploadMeta{}
		err = json.Unmarshal(data, meta)
		if err != nil {
			return nil, false, fmt.Errorf("error: %v", err)
		}
	}

	return
}

func saveIncomingFile(s *Services, w http.ResponseWriter, req *http.Request) (meta *UploadMeta, created bool, err error) {
	p := strings.Split(req.URL.Path[1:], "/")
	if len(p) != s.Options.Strip+2 {
		return nil, false, fmt.Errorf("bad path")
	}

	batch := p[s.Options.Strip]
	filename := p[s.Options.Strip+1]
	localDirectory := filepath.Join(s.Options.RootPath, batch)

	err = os.MkdirAll(localDirectory, 0755)
	if err != nil {
		return nil, false, fmt.Errorf("unable to create directory: %v", err)
	}

	metaPath := filepath.Join(localDirectory, "meta.json")
	meta, created, err = saveOrReadMeta(batch, metaPath)
	if err != nil {
		return nil, false, fmt.Errorf("unable to save or read meta: %v", err)
	}

	localPath := filepath.Join(localDirectory, filename)
	file, err := os.Create(localPath)
	if err != nil {
		return nil, false, fmt.Errorf("unable to create file: %v", err)
	}

	defer file.Close()

	bytes, err := io.Copy(file, req.Body)
	if err != nil {
		return nil, false, fmt.Errorf("unable to copy file: %v", err)
	}

	log.Printf("[http] %s received %d -> %s", req.URL, bytes, localPath)

	return meta, created, nil
}

func receive(ctx context.Context, s *Services, w http.ResponseWriter, r *http.Request) error {
	log.Printf("[http] %s receiving", r.URL)

	meta, created, err := saveIncomingFile(s, w, r)
	if err != nil {
		return err
	}

	bytes, err := json.Marshal(meta)
	if err != nil {
		return err
	}

	w.WriteHeader(http.StatusOK)
	w.Write(bytes)

	if created {
		if meta != nil {
			err := s.Notifier.NotifyReceived(meta)
			if err != nil {
				return err
			}
		}
	}

	return nil
}
