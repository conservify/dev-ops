package main

import (
	"context"
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

	"github.com/gorilla/mux"

	"github.com/sethvargo/go-diceware/diceware"
)

type options struct {
	RootPath string
	Strip    int
}

type UploadMeta struct {
	Phrase string    `json:"phrase"`
	Batch  string    `json:"batch"`
	Time   time.Time `json:"time"`
}

func saveOrReadMeta(batch, path string) (meta *UploadMeta, err error) {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		file, err := os.Create(path)
		if err != nil {
			return nil, fmt.Errorf("error: %v", err)
		}

		phrase, err := diceware.Generate(3)

		defer file.Close()

		meta := &UploadMeta{
			Phrase: strings.Join(phrase, " "),
			Batch:  batch,
			Time:   time.Now(),
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

func saveIncomingFile(s *Services, w http.ResponseWriter, req *http.Request) (meta *UploadMeta, err error) {
	log.Printf("[http] %s", req.URL)

	p := strings.Split(req.URL.Path[1:], "/")
	if len(p) != s.options.Strip+2 {
		return nil, fmt.Errorf("bad path")
	}

	batch := p[s.options.Strip]
	filename := p[s.options.Strip+1]
	localDirectory := filepath.Join(s.options.RootPath, batch)

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

func receive(ctx context.Context, s *Services, w http.ResponseWriter, r *http.Request) error {
	meta, err := saveIncomingFile(s, w, r)
	if err != nil {
		return err
	}

	bytes, err := json.Marshal(meta)
	if err != nil {
		return err
	}

	w.WriteHeader(http.StatusOK)
	w.Write(bytes)

	return nil
}

func index(ctx context.Context, s *Services, w http.ResponseWriter, r *http.Request) error {
	w.WriteHeader(http.StatusOK)
	return nil
}

type Services struct {
	options *options
}

func middleware(services *Services, h func(context.Context, *Services, http.ResponseWriter, *http.Request) error) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx := r.Context()
		err := h(ctx, services, w, r)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			io.WriteString(w, fmt.Sprintf("error: %v", err))
		}
	}
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

	services := &Services{
		options: o,
	}

	router := mux.NewRouter().StrictSlash(true)

	router.HandleFunc("/", middleware(services, receive)).Methods("POST")
	router.HandleFunc("/", middleware(services, index)).Methods("GET")

	log.Printf("starting...")

	err := http.ListenAndServe(":8080", router)
	if err != nil {
		panic(err)
	}
}
