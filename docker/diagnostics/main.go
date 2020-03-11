package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gorilla/mux"
)

type Options struct {
	RootPath string
	Strip    int
}

type Services struct {
	Options    *Options
	Repository *Repository
}

type UploadMeta struct {
	Phrase string    `json:"phrase"`
	Batch  string    `json:"batch"`
	Time   time.Time `json:"time"`
}

func index(ctx context.Context, s *Services, w http.ResponseWriter, r *http.Request) error {
	archives, err := s.Repository.ListAll(ctx)
	if err != nil {
		return err
	}

	response := &IndexResponse{
		Archives: archives,
	}

	bytes, err := json.Marshal(response)
	if err != nil {
		return err
	}

	w.WriteHeader(http.StatusOK)
	w.Write(bytes)

	return nil
}

func middleware(services *Services, h func(context.Context, *Services, http.ResponseWriter, *http.Request) error) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, req *http.Request) {
		log.Printf("[http] %s %s", req.Method, req.URL)

		ctx := req.Context()
		err := h(ctx, services, w, req)
		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			io.WriteString(w, fmt.Sprintf("error: %v", err))
		}
	}
}

func main() {
	o := &Options{}

	flag.StringVar(&o.RootPath, "path", "", "path")
	flag.IntVar(&o.Strip, "strip", 0, "strip")

	flag.Parse()

	if o.RootPath == "" {
		flag.Usage()
		os.Exit(2)
	}

	repo, err := NewRepository(o.RootPath)
	if err != nil {
		panic(err)
	}

	services := &Services{
		Options:    o,
		Repository: repo,
	}

	router := mux.NewRouter().StrictSlash(true)

	router.HandleFunc("/", middleware(services, receive)).Methods("POST")
	router.HandleFunc("/", middleware(services, index)).Methods("GET")

	log.Printf("listening on :8080")

	err = http.ListenAndServe(":8080", router)
	if err != nil {
		panic(err)
	}
}
