package main

import (
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"

	"net/http"
)

type options struct {
	RootPath string
	Strip    int
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
		log.Printf("[http] %s", req.URL)

		p := strings.Split(req.URL.Path[1:], "/")
		if len(p) != o.Strip+2 {
			w.WriteHeader(http.StatusBadRequest)
			return
		}

		batch := p[o.Strip]
		filename := p[o.Strip+1]

		localDirectory := filepath.Join(o.RootPath, batch)
		err := os.MkdirAll(localDirectory, 0755)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte(fmt.Sprintf("error: %v", err)))
			return
		}

		localPath := filepath.Join(localDirectory, filename)
		file, err := os.Create(localPath)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte(fmt.Sprintf("error: %v", err)))
			return
		}

		defer file.Close()

		bytes, err := io.Copy(file, req.Body)

		log.Printf("[http] (%s) received %d -> %s", req.URL, bytes, localPath)

		w.WriteHeader(http.StatusOK)
		w.Write([]byte(fmt.Sprintf("%s", batch)))
	})

	log.Printf("starting...")

	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		panic(err)
	}
}
