package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"time"

	htmltemplate "html/template"
	texttemplate "text/template"
)

type Link struct {
	Title string
	Url   htmltemplate.URL
}

type MenuOption struct {
	Key     string
	Sort    int64
	Title   string
	Details string
	Links   []Link
}

type MenuData struct {
	Options []MenuOption
	ByKey   map[string][]*MenuOption
}

type MenuGenerator struct {
}

type BySort []MenuOption

func (a BySort) Len() int           { return len(a) }
func (a BySort) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a BySort) Less(i, j int) bool { return a[i].Sort > a[j].Sort }

func NewMenuGenerator() (mg *MenuGenerator) {
	return &MenuGenerator{}
}

type FileTypeHandler interface {
	CanHandle(path string) bool
	Handle(path string, relative string, jobName string, build *BuildInfo, archived []string, artifact string) ([]MenuOption, error)
}

type IpaHandler struct {
	Destination string
}

func (h *IpaHandler) CanHandle(path string) bool {
	return filepath.Ext(path) == ".ipa"
}

type IpaTemplateData struct {
	Url string
}

func (h *IpaHandler) Handle(path string, relative string, jobName string, build *BuildInfo, archived []string, artifact string) (options []MenuOption, err error) {
	templateData, err := ioutil.ReadFile(filepath.Join(h.Destination, "manifest.plist.template"))
	if err != nil {
		return nil, err
	}

	template, err := texttemplate.New("manifest").Parse(string(templateData))
	if err != nil {
		return nil, err
	}

	ipaUrl := fmt.Sprintf("https://code.conservify.org/distribution/archive/%s/artifacts/%s", relative, filepath.Base(artifact))

	data := IpaTemplateData{
		Url: ipaUrl,
	}

	manifestFile, err := os.Create(filepath.Join(path, "manifest.plist"))
	if err != nil {
		return nil, err
	}

	defer manifestFile.Close()

	err = template.Execute(manifestFile, data)
	if err != nil {
		return nil, err
	}

	location, err := time.LoadLocation("America/Los_Angeles")
	if err != nil {
		return nil, err
	}

	buildTime := time.Unix(build.Timestamp/1000, 0)
	timestamp := buildTime.UTC().In(location).Format("2006/01/02 15:04:05")
	manifestUrl := fmt.Sprintf("https://code.conservify.org/distribution/archive/%s/manifest.plist", relative)
	installUrl := htmltemplate.URL(fmt.Sprintf("itms-services://?action=download-manifest&url=%s", url.QueryEscape(manifestUrl)))

	options = []MenuOption{
		MenuOption{
			Key:     jobName,
			Sort:    build.Timestamp,
			Title:   fmt.Sprintf("%s #%d", jobName, build.BuildNumber()),
			Details: timestamp,
			Links: []Link{
				Link{
					Title: "Install",
					Url:   installUrl,
				},
			},
		},
	}

	return
}

type ApkHandler struct {
	Destination string
}

func (h *ApkHandler) CanHandle(path string) bool {
	return filepath.Ext(path) == ".apk"
}

func (h *ApkHandler) Handle(path string, relative string, jobName string, build *BuildInfo, archived []string, artifact string) (options []MenuOption, err error) {
	location, err := time.LoadLocation("America/Los_Angeles")
	if err != nil {
		return nil, err
	}

	buildTime := time.Unix(build.Timestamp/1000, 0)
	timestamp := buildTime.In(location).Format("2006/01/02 15:04:05")
	downloadUrl := htmltemplate.URL(fmt.Sprintf("https://code.conservify.org/distribution/archive/%s/artifacts/%s", relative, filepath.Base(artifact)))

	options = []MenuOption{
		MenuOption{
			Key:     jobName,
			Sort:    build.Timestamp,
			Title:   fmt.Sprintf("%s #%d", jobName, build.BuildNumber()),
			Details: fmt.Sprintf("%s", timestamp),
			Links: []Link{
				Link{
					Title: "Download",
					Url:   downloadUrl,
				},
			},
		},
	}

	return
}

func writeMenuFile(directory string, data MenuData) error {
	templateData, err := ioutil.ReadFile(filepath.Join(directory, "index.html.template"))
	if err != nil {
		return err
	}

	template, err := htmltemplate.New("index").Parse(string(templateData))
	if err != nil {
		return err
	}

	indexPath := filepath.Join(directory, "index.html")

	file, err := os.Create(indexPath)
	if err != nil {
		return err
	}

	defer file.Close()

	err = template.Execute(file, data)
	if err != nil {
		return err
	}

	log.Printf("wrote %s", indexPath)

	return nil
}

func toMenuData(options []MenuOption) MenuData {
	byKey := make(map[string][]*MenuOption)

	sort.Sort(BySort(options))

	for _, o := range options {
		if byKey[o.Key] == nil {
			byKey[o.Key] = make([]*MenuOption, 0)
		}
		byKey[o.Key] = append(byKey[o.Key], &o)
	}

	return MenuData{
		Options: options,
		ByKey:   byKey,
	}
}

func (mg *MenuGenerator) GenerateMenu(directory string) error {
	archive := filepath.Join(directory, "archive")

	log.Printf("indexing %s", archive)

	handlers := []FileTypeHandler{
		&IpaHandler{Destination: directory},
		&ApkHandler{Destination: directory},
	}

	options := make([]MenuOption, 0)

	err := walkBuilds(archive, func(path string, relative string, jobName string, buildXmlPath string, info *BuildInfo, artifactPaths []string) error {
		if false {
			log.Printf("processing %s %s (%s)", path, jobName, relative)
		}

		for _, p := range artifactPaths {
			for _, handler := range handlers {
				if handler.CanHandle(p) {
					if false {
						log.Printf("- %T (%s)", handler, p)
					}

					newOptions, err := handler.Handle(path, relative, jobName, info, artifactPaths, p)
					if err != nil {
						return err
					}

					options = append(options, newOptions...)
				}

			}
		}

		return nil
	})
	if err != nil {
		return err
	}

	return writeMenuFile(directory, toMenuData(options))
}
