package main

import (
	"encoding/xml"
	"flag"
	"fmt"
	htmltemplate "html/template"
	"io"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	texttemplate "text/template"
	"time"
)

type options struct {
	Source      string
	Destination string
}

type BuildInfo struct {
	Duration            int64  `xml:"duration"`
	Timestamp           int64  `xml:"timestamp"`
	StartTime           int64  `xml:"startTime"`
	Status              string `xml:"result"`
	ParameterCommitHash string `xml:"actions>hudson.plugins.git.RevisionParameterAction>commit"`
	BuildCommitHash     string `xml:"actions>hudson.plugins.git.util.BuildData>buildsByBranchName>entry>hudson.plugins.git.util.Build>marked>sha1"`
	BuildNumber         int32  `xml:"actions>hudson.plugins.git.util.BuildData>buildsByBranchName>entry>hudson.plugins.git.util.Build>hudsonBuildNumber"`
}

type Link struct {
	Title string
	Url   string
}

type IndexOption struct {
	Key     string
	Sort    int64
	Title   string
	Details string
	Links   []Link
}

type BySort []IndexOption

func (a BySort) Len() int           { return len(a) }
func (a BySort) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }
func (a BySort) Less(i, j int) bool { return a[i].Sort > a[j].Sort }

type FileTypeHandler interface {
	CanHandle(path string) bool
	Handle(path string, jobName string, build *BuildInfo, archived []string, artifact string) ([]IndexOption, error)
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

func (h *IpaHandler) Handle(path string, jobName string, build *BuildInfo, archived []string, artifact string) (options []IndexOption, err error) {
	templateData, err := ioutil.ReadFile(filepath.Join(h.Destination, "manifest.plist.template"))
	if err != nil {
		return nil, err
	}

	template, err := texttemplate.New("manifest").Parse(string(templateData))
	if err != nil {
		return nil, err
	}

	ipaUrl := fmt.Sprintf("https://code.conservify.org/distribution/archive/%s/%d/artifacts/%s", jobName, build.BuildNumber, filepath.Base(artifact))

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

	buildTime := time.Unix(build.Timestamp/1000, 0)
	timestamp := buildTime.Format("2006/01/02 15:04:05")
	manifestUrl := fmt.Sprintf("https://code.conservify.org/distribution/archive/%s/%d/manifest.plist", jobName, build.BuildNumber)
	installUrl := fmt.Sprintf("itms-services://?action=download-manifest&url=%s", manifestUrl)

	options = []IndexOption{
		IndexOption{
			Key:     jobName,
			Sort:    build.Timestamp,
			Title:   fmt.Sprintf("%s #%d", jobName, build.BuildNumber),
			Details: fmt.Sprintf("%s", timestamp),
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

func (h *ApkHandler) Handle(path string, jobName string, build *BuildInfo, archived []string, artifact string) (options []IndexOption, err error) {
	buildTime := time.Unix(build.Timestamp/1000, 0)
	timestamp := buildTime.Format("2006/01/02 15:04:05")
	downloadUrl := fmt.Sprintf("https://code.conservify.org/distribution/archive/%s/%d/artifacts/%s", jobName, build.BuildNumber, filepath.Base(artifact))

	options = []IndexOption{
		IndexOption{
			Key:     jobName,
			Sort:    build.Timestamp,
			Title:   fmt.Sprintf("%s #%d", jobName, build.BuildNumber),
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

type BuildWalkFunc func(path string, jobName string, buildXmlPath string, build *BuildInfo, artifactPaths []string) error

// Sorry.
func fixXmlVersion(bytes []byte) []byte {
	return []byte(strings.Replace(strings.Replace(string(bytes), "version=\"1.1\"", "version=\"1.0\"", 1), "version='1.1'", "version='1.0'", 1))
}

func walkBuilds(path string, walkFunc BuildWalkFunc) error {
	return filepath.Walk(path, func(path string, info os.FileInfo, err error) error {
		if !info.IsDir() {
			return nil
		}

		buildXmlPath := filepath.Join(path, "build.xml")
		if _, err := os.Stat(buildXmlPath); os.IsNotExist(err) {
			return nil
		}

		jobName := filepath.Base(filepath.Dir(path))
		if jobName == "builds" {
			jobName = filepath.Base(filepath.Dir(filepath.Dir(path)))
		}

		data, err := ioutil.ReadFile(buildXmlPath)
		if err != nil {
			return err
		}

		buildInfo := BuildInfo{}
		err = xml.Unmarshal(fixXmlVersion(data), &buildInfo)
		if err != nil {
			return fmt.Errorf("Error reading %s (%v)", buildXmlPath, err)
		}

		artifactPaths, err := getFilesUnder([]string{filepath.Join(path, "archive"), filepath.Join(path, "artifacts")})
		if err != nil {
			return err
		}

		return walkFunc(path, jobName, buildXmlPath, &buildInfo, artifactPaths)
	})
}

func copy(o *options) error {
	archive := filepath.Join(o.Destination, "archive")

	log.Printf("Copying %s to %s", o.Source, archive)

	return walkBuilds(o.Source, func(path string, jobName string, buildXmlPath string, info *BuildInfo, artifactPaths []string) error {
		if len(artifactPaths) == 0 {
			return nil
		}

		copyingTo := filepath.Join(archive, jobName, fmt.Sprintf("%d", info.BuildNumber))

		log.Printf("Processing %s -> %s (%s)", path, copyingTo, jobName)

		err := mkdirDirIfMissing(copyingTo)
		if err != nil {
			return err
		}

		newBuildXmlPath := filepath.Join(copyingTo, "build.xml")
		err = copyFileIfMissing(buildXmlPath, newBuildXmlPath)
		if err != nil {
			return err
		}

		destinationArtifacts := filepath.Join(copyingTo, "artifacts")
		err = mkdirDirIfMissing(destinationArtifacts)
		if err != nil {
			return err
		}

		for _, artifactPath := range artifactPaths {
			newArtifactsPath := filepath.Join(destinationArtifacts, filepath.Base(artifactPath))
			err = copyFileIfMissing(artifactPath, newArtifactsPath)
			if err != nil {
				return err
			}
		}
		return nil
	})
}

type IndexData struct {
	Options []IndexOption
	ByKey   map[string][]*IndexOption
}

func writeIndex(o *options, data IndexData) error {
	templateData, err := ioutil.ReadFile(filepath.Join(o.Destination, "index.html.template"))
	if err != nil {
		return err
	}

	template, err := htmltemplate.New("index").Parse(string(templateData))
	if err != nil {
		return err
	}

	indexPath := filepath.Join(o.Destination, "index.html")

	file, err := os.Create(indexPath)
	if err != nil {
		return err
	}

	defer file.Close()

	err = template.Execute(file, data)
	if err != nil {
		return err
	}

	log.Printf("Wrote %s", indexPath)

	return nil
}

func toIndexData(options []IndexOption) IndexData {
	byKey := make(map[string][]*IndexOption)

	sort.Sort(BySort(options))

	for _, o := range options {
		if byKey[o.Key] == nil {
			byKey[o.Key] = make([]*IndexOption, 0)
		}
		byKey[o.Key] = append(byKey[o.Key], &o)
	}

	return IndexData{
		Options: options,
		ByKey:   byKey,
	}
}

func index(o *options) error {
	archive := filepath.Join(o.Destination, "archive")

	log.Printf("Indexing %s", archive)

	handlers := []FileTypeHandler{
		&IpaHandler{Destination: o.Destination},
		&ApkHandler{Destination: o.Destination},
	}

	options := make([]IndexOption, 0)

	err := walkBuilds(archive, func(path string, jobName string, buildXmlPath string, info *BuildInfo, artifactPaths []string) error {
		log.Printf("Processing %s %s", path, jobName)

		for _, p := range artifactPaths {
			for _, handler := range handlers {
				if handler.CanHandle(p) {
					log.Printf("- %T (%s)", handler, p)

					newOptions, err := handler.Handle(path, jobName, info, artifactPaths, p)
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

	return writeIndex(o, toIndexData(options))
}

func main() {
	o := options{}

	flag.StringVar(&o.Source, "source", "", "source directory")
	flag.StringVar(&o.Destination, "destination", "", "destination directory")

	flag.Parse()

	if o.Source == "" || o.Destination == "" {
		flag.Usage()
		os.Exit(2)
	}

	err := copy(&o)
	if err != nil {
		log.Fatalf("Error: %v", err)
	}

	err = index(&o)
	if err != nil {
		log.Fatalf("Error: %v", err)
	}
}

func getFilesUnder(paths []string) (files []string, err error) {
	files = make([]string, 0)
	for _, path := range paths {
		if _, err := os.Stat(path); !os.IsNotExist(err) {
			err = filepath.Walk(path, func(path string, info os.FileInfo, err error) error {
				if !info.IsDir() {
					files = append(files, path)
				}
				return nil
			})
			if err != nil {
				return nil, err
			}
		}
	}

	return
}

func mkdirDirIfMissing(p string) error {
	if _, err := os.Stat(p); os.IsNotExist(err) {
		log.Printf("Mkdir %v", p)

		err = os.MkdirAll(p, 0755)
		if err != nil {
			return err
		}
	}
	return nil
}

func copyFileIfMissing(s, d string) error {
	if _, err := os.Stat(d); os.IsNotExist(err) {
		log.Printf("Copying %v -> %v", s, d)

		err = copyFile(s, d)
		if err != nil {
			return err
		}
		if err != nil {
			return err
		}
	}
	return nil
}

func copyFile(s, d string) error {
	sFile, err := os.Open(s)
	if err != nil {
		return err
	}
	defer sFile.Close()

	dFile, err := os.Create(d)
	if err != nil {
		return err
	}
	defer dFile.Close()

	_, err = io.Copy(dFile, sFile)
	if err != nil {
		return err
	}

	err = dFile.Sync()
	if err != nil {
		return err
	}
	return nil
}
