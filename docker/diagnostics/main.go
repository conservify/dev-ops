package main

import (
	"context"
	"encoding/base64"
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

func tryAuthenticate(payload *LoginPayload) *User {
	for _, user := range Users {
		if user.User == payload.User && user.Password == payload.Password {
			return &user
		}
	}
	return nil
}

func login(ctx context.Context, s *Services, w http.ResponseWriter, r *http.Request) error {
	payload := &LoginPayload{}

	dec := json.NewDecoder(r.Body)
	err := dec.Decode(payload)
	if err != nil {
		return err
	}

	user := tryAuthenticate(payload)
	if user == nil {
		w.WriteHeader(http.StatusUnauthorized)
		return nil
	}

	key, err := base64.StdEncoding.DecodeString(SessionKey)
	if err != nil {
		return fmt.Errorf("error decoding session key: %v", err)
	}

	token := NewToken(time.Now())
	signed, err := token.SignedString(key)
	if err != nil {
		return fmt.Errorf("error signing token: %v", err)
	}

	w.Header().Set("Authorization", "Bearer "+signed)
	w.WriteHeader(http.StatusNoContent)

	return nil
}

func view(ctx context.Context, s *Services, w http.ResponseWriter, r *http.Request) error {
	id := mux.Vars(r)["id"]

	archive, err := s.Repository.FindByID(ctx, id)
	if err != nil {
		return err
	}

	log.Printf("view %+v", archive)

	bytes, err := json.Marshal(archive)
	if err != nil {
		return err
	}

	w.WriteHeader(http.StatusOK)
	w.Write(bytes)

	return nil
}

func download(ctx context.Context, s *Services, w http.ResponseWriter, r *http.Request) error {
	id := mux.Vars(r)["id"]

	archive, err := s.Repository.FindByID(ctx, id)
	if err != nil {
		return err
	}

	log.Printf("download %+v", archive)

	path, err := ZipDirectory(archive.Path)
	if err != nil {
		return err
	}

	f, err := os.Open(path)
	if err != nil {
		return err
	}

	defer f.Close()

	w.WriteHeader(http.StatusOK)

	io.Copy(w, f)

	return nil
}

func search(ctx context.Context, s *Services, w http.ResponseWriter, r *http.Request) error {
	query := mux.Vars(r)["query"]

	archives, err := s.Repository.FindByQuery(ctx, query)
	if err != nil {
		return err
	}

	log.Printf("found %+v", archives)

	if len(archives) == 0 {
		w.WriteHeader(http.StatusNotFound)
		return nil
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
			details := struct {
				Error string `json:"error"`
			}{
				err.Error(),
			}
			bytes, err := json.Marshal(details)
			if err != nil {
				panic(err)
			}

			w.WriteHeader(http.StatusInternalServerError)
			w.Write(bytes)
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

	static := http.FileServer(http.Dir("./static"))

	router.HandleFunc("/archives", middleware(services, secure(index))).Methods("GET")
	router.HandleFunc("/archives/{id}.zip", middleware(services, secure(download))).Methods("GET")
	router.HandleFunc("/archives/{id}", middleware(services, secure(view))).Methods("GET")
	router.HandleFunc("/search/{query}", middleware(services, secure(search))).Methods("GET")
	router.HandleFunc("/login", middleware(services, login)).Methods("POST")
	router.HandleFunc("/", middleware(services, receive)).Methods("POST")

	// NOTE Move this to PathPrefix
	router.Handle("/", static).Methods("GET")
	router.Handle("/App.js", static).Methods("GET")
	router.Handle("/App.css", static).Methods("GET")

	log.Printf("listening on :8080")

	err = http.ListenAndServe(":8080", router)
	if err != nil {
		panic(err)
	}
}
