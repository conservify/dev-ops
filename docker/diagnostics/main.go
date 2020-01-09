package main

import (
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"encoding/json"

	"net/http"
)

type options struct {
	RootPath string
	Strip    int
}

type UploadMeta struct {
	Batch string
	Time  time.Time
}

func saveOrReadMeta(batch, path string) (meta *UploadMeta, err error) {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		file, err := os.Create(path)
		if err != nil {
			return nil, fmt.Errorf("error: %v", err)
		}

		defer file.Close()

		meta := &UploadMeta{
			Batch: batch,
			Time:  time.Now(),
		}

		bytes, err := json.Marshal(meta)
		if err != nil {
			return nil, fmt.Errorf("error: %v", err)
		}

		_, err = file.Write(bytes)
		if err != nil {
			return nil, fmt.Errorf("error: %v", err)
		}
	} else {
		data, err := ioutil.ReadFile(path)
		if err != nil {
			return nil, fmt.Errorf("error: %v", err)
		}

		meta = &UploadMeta{}
		err = json.Unmarshal(data, meta)
		if err != nil {
			return nil, fmt.Errorf("error: %v", err)
		}
	}

	return
}

func serve(o *options, w http.ResponseWriter, req *http.Request) (meta *UploadMeta, err error) {
	log.Printf("[http] %s", req.URL)

	p := strings.Split(req.URL.Path[1:], "/")
	if len(p) != o.Strip+2 {
		return nil, fmt.Errorf("bad path")
	}

	batch := p[o.Strip]
	filename := p[o.Strip+1]
	localDirectory := filepath.Join(o.RootPath, batch)

	err = os.MkdirAll(localDirectory, 0755)
	if err != nil {
		return nil, fmt.Errorf("unable to create directory: %v", err)
	}

	metaPath := filepath.Join(localDirectory, "meta.json")
	meta, err = saveOrReadMeta(batch, metaPath)
	if err != nil {
		return nil, fmt.Errorf("unable to save or read meta: %v", err)
	}

	localPath := filepath.Join(localDirectory, filename)
	file, err := os.Create(localPath)
	if err != nil {
		return nil, fmt.Errorf("unable to create file: %v", err)
	}

	defer file.Close()

	bytes, err := io.Copy(file, req.Body)
	if err != nil {
		return nil, fmt.Errorf("unable to copy file: %v", err)
	}

	log.Printf("[http] %s received %d -> %s", req.URL, bytes, localPath)

	return meta, nil
}

func main() {
	o := &options{}

	flag.StringVar(&o.RootPath, "path", "", "path")
	flag.IntVar(&o.Strip, "strip", 0, "strip")

	flag.Parse()

	if o.RootPath == "" {
		flag.Usage()
		os.Exit(2)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, req *http.Request) {
		meta, err := serve(o, w, req)
		if err != nil {
			log.Printf("error: %v", err)
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte(fmt.Sprintf("error: %v", err)))
			return
		}

		bytes, err := json.Marshal(meta)
		if err != nil {
			log.Printf("error: %v", err)
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte(fmt.Sprintf("error: %v", err)))
			return
		}

		w.WriteHeader(http.StatusOK)
		w.Write(bytes)
	})

	log.Printf("starting...")

	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		panic(err)
	}
}
