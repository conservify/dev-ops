package main

import (
	"encoding/xml"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
)

type BuildInfo struct {
	Duration        int64  `xml:"duration"`
	Timestamp       int64  `xml:"timestamp"`
	StartTime       int64  `xml:"startTime"`
	Status          string `xml:"result"`
	BuildCommitHash string `xml:"actions>hudson.plugins.git.util.BuildDetails>build>marked>sha1"`
	BuildNumber     int32  `xml:"actions>hudson.plugins.git.util.BuildDetails>build>hudsonBuildNumber"`
}

type BuildWalkFunc func(path string, relative string, jobName string, buildXmlPath string, build *BuildInfo, artifactPaths []string) error

// Sorry.
func fixXmlVersion(bytes []byte) []byte {
	return []byte(strings.Replace(strings.Replace(string(bytes), "version=\"1.1\"", "version=\"1.0\"", 1), "version='1.1'", "version='1.0'", 1))
}

func walkBuilds(base string, walkFunc BuildWalkFunc) error {
	return filepath.Walk(base, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			log.Printf("Error: %v %v", path, err)
			return nil
		}
		if !info.IsDir() {
			return nil
		}

		relative, err := filepath.Rel(base, path)
		if err != nil {
			return err
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

		return walkFunc(path, relative, jobName, buildXmlPath, &buildInfo, artifactPaths)
	})
}
