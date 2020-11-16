package main

import (
	"bufio"
	"context"
	"encoding/base64"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
)

type Options struct {
	RootPath     string
	Strip        int
	URL          string
	SlackToken   string
	SlackChannel string
}

type Services struct {
	Options    *Options
	Repository *Repository
	Notifier   *Notifier
}

func index(ctx context.Context, s *Services, w http.ResponseWriter, r *http.Request) error {
	query := r.URL.Query()["q"]

	var archives []*Archive
	var err error

	if len(query) == 0 {
		log.Printf("listing")
		archives, err = s.Repository.ListRecent(ctx)
	} else {
		log.Printf("searching %v", query[0])
		archives, err = s.Repository.FindByQuery(ctx, query[0])
	}
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

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(bytes)

	return nil
}

func tryAuthenticate(payload *LoginPayload) *User {
	for _, user := range Users {
		log.Printf("checking %v %v", user.User, payload.User)
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

	w.Header().Set("Content-Type", "application/json")
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

func archiveFile(ctx context.Context, s *Services, w http.ResponseWriter, r *http.Request) error {
	id := mux.Vars(r)["id"]
	file := mux.Vars(r)["file"]

	archive, err := s.Repository.FindByID(ctx, id)
	if err != nil {
		return err
	}

	path := filepath.Join(archive.Path, file)

	log.Printf("serving %v", path)

	f, err := os.Open(path)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		return nil
	}

	defer f.Close()

	w.WriteHeader(http.StatusOK)

	io.Copy(w, f)

	return nil
}

func analysis(ctx context.Context, s *Services, w http.ResponseWriter, r *http.Request) error {
	id := mux.Vars(r)["id"]

	archive, err := s.Repository.FindByID(ctx, id)
	if err != nil {
		return err
	}

	dbPath := filepath.Join(archive.Path, "fk.db")
	db, err := NewApplicationDB(dbPath)
	if err != nil {
		return err
	}

	stations, err := db.ListStations()
	if err != nil {
		return err
	}

	analysis := struct {
		Stations []*Station `json:"stations"`
	}{
		stations,
	}

	bytes, err := json.Marshal(analysis)
	if err != nil {
		panic(err)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(bytes)

	return nil
}

type Launch struct {
	Time int64  `json:"time"`
	Logs string `json:"logs"`
}

// 2020-11-14T11:54:59-08:00
var timeRegex = regexp.MustCompile(`\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d-\d\d:\d\d`)
var nlRegex = regexp.MustCompile(`\n+`)

func getTime(line string) time.Time {
	values := timeRegex.FindAllString(line, -1)
	if len(values) > 0 {
		time, err := time.Parse("2006-01-02T15:04:05-07:00", values[len(values)-1])
		if err == nil {
			log.Printf("time-good: %v %v", values[len(values)-1], time)
			return time
		}
		log.Printf("time-bad: %v", values[len(values)-1])
	}
	return time.Time{}
}

func launches(ctx context.Context, s *Services, w http.ResponseWriter, r *http.Request) error {
	id := mux.Vars(r)["id"]

	archive, err := s.Repository.FindByID(ctx, id)
	if err != nil {
		return err
	}

	logsPath := filepath.Join(archive.Path, "logs.txt")

	file, err := os.Open(logsPath)
	if err != nil {
		return err

	}

	defer file.Close()

	scanner := bufio.NewScanner(file)
	scanner.Split(bufio.ScanLines)

	launches := make([]*Launch, 0)
	var launch *Launch

	for scanner.Scan() {
		line := scanner.Text()

		if strings.Contains(line, "startup loaded") {
			launch = &Launch{
				Time: getTime(line).Unix() * 1000,
				Logs: "",
			}
			launches = append(launches, launch)
		} else {
			if launch == nil {
				launch = &Launch{
					Time: getTime(line).Unix() * 1000,
					Logs: "",
				}
				launches = append(launches, launch)
			}
		}

		launch.Logs += line + "\n"
	}

	for _, launch := range launches {
		launch.Logs = nlRegex.ReplaceAllString(launch.Logs, "\n")
	}

	response := struct {
		Launches []*Launch `json:"launches"`
	}{
		launches,
	}

	bytes, err := json.Marshal(response)
	if err != nil {
		panic(err)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write(bytes)

	return nil
}

func middleware(services *Services, h func(context.Context, *Services, http.ResponseWriter, *http.Request) error) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, req *http.Request) {
		log.Printf("[http] %s %s", req.Method, req.URL)

		ctx := req.Context()
		handlerError := h(ctx, services, w, req)
		if handlerError != nil {
			details := struct {
				Error string `json:"error"`
			}{
				handlerError.Error(),
			}
			bytes, err := json.Marshal(details)
			if err != nil {
				panic(err)
			}

			switch e := handlerError.(type) {
			case StatusError:
				w.WriteHeader(e.Status())
				w.Write(bytes)
			default:
				w.WriteHeader(http.StatusInternalServerError)
				w.Write(bytes)
			}
		}
	}
}

func main() {
	o := &Options{}

	flag.IntVar(&o.Strip, "strip", 0, "strip")
	flag.StringVar(&o.RootPath, "path", "", "path")
	flag.StringVar(&o.URL, "url", "", "url")
	flag.StringVar(&o.SlackChannel, "slack-channel", "", "slack-channel")
	flag.StringVar(&o.SlackToken, "slack-token", SlackToken, "slack-token")

	flag.Parse()

	if o.RootPath == "" {
		flag.Usage()
		os.Exit(2)
	}

	repo, err := NewRepository(o.RootPath)
	if err != nil {
		panic(err)
	}

	notifier, err := NewSlackNotifier(o.URL, o.SlackChannel, o.SlackToken)
	if err != nil {
		panic(err)
	}

	services := &Services{
		Options:    o,
		Repository: repo,
		Notifier:   notifier,
	}

	router := mux.NewRouter().StrictSlash(true)

	static := http.StripPrefix("/diagnostics", http.FileServer(http.Dir("./public")))

	router.HandleFunc("/diagnostics/archives", middleware(services, secure(index))).Methods("GET")
	router.HandleFunc("/diagnostics/archives/{id}.zip", middleware(services, secure(download))).Methods("GET")
	router.HandleFunc("/diagnostics/archives/{id}", middleware(services, secure(view))).Methods("GET")
	router.HandleFunc("/diagnostics/archives/{id}/analysis", middleware(services, secure(analysis))).Methods("GET")
	router.HandleFunc("/diagnostics/archives/{id}/launches", middleware(services, secure(launches))).Methods("GET")
	router.HandleFunc("/diagnostics/archives/{id}/{file}", middleware(services, secure(archiveFile))).Methods("GET")
	router.HandleFunc("/diagnostics/login", middleware(services, login)).Methods("POST")
	router.PathPrefix("/diagnostics/").Methods("POST").HandlerFunc(middleware(services, receive))
	router.PathPrefix("/diagnostics").Methods("GET").HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
		log.Printf("[http] %s %s", req.Method, req.URL)
		static.ServeHTTP(rw, req)
	})

	log.Printf("listening on :8080")

	withCors := handlers.CORS(
		handlers.ExposedHeaders([]string{"Authorization"}),
		handlers.AllowedHeaders([]string{"X-Requested-With", "Content-Type", "Authorization"}),
		handlers.AllowedMethods([]string{"GET", "POST", "PUT", "HEAD", "OPTIONS"}),
		handlers.AllowedOrigins([]string{"*"}))(router)

	err = http.ListenAndServe(":8080", withCors)
	if err != nil {
		panic(err)
	}
}
