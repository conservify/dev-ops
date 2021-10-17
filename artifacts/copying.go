package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

type ArtifactsCopier struct {
	Directory string
}

func NewArtifactsCopier(directory string) (am *ArtifactsCopier) {
	return &ArtifactsCopier{
		Directory: directory,
	}
}

func (am *ArtifactsCopier) Copy(source string) error {
	archive := filepath.Join(am.Directory, "archive")

	log.Printf("copying %s to %s", source, archive)

	latest := make(map[string]int64)

	err := walkBuilds(source, func(path string, relative string, jobName string, buildXmlPath string, info *BuildInfo, artifactPaths []string) error {
		if len(artifactPaths) == 0 {
			return nil
		}

		log.Printf("checking %s", relative)

		r := cleanupRelativePath(relative)
		copyingTo := filepath.Join(archive, r)

		maybeBuildNumber := filepath.Base(copyingTo)
		if buildNumber, err := strconv.ParseInt(maybeBuildNumber, 10, 64); err == nil {
			jobDirectory := filepath.Join(copyingTo, "../../")
			if buildNumber > latest[jobDirectory] {
				latest[jobDirectory] = buildNumber
			}
		}

		err := mkdirAllIfMissing(copyingTo)
		if err != nil {
			return err
		}

		newBuildXmlPath := filepath.Join(copyingTo, "build.xml")
		err = copyFileIfMissing(buildXmlPath, newBuildXmlPath)
		if err != nil {
			return err
		}

		destinationArtifacts := filepath.Join(copyingTo, "artifacts")
		err = mkdirAllIfMissing(destinationArtifacts)
		if err != nil {
			return err
		}

		copyStart := time.Now()

		for _, artifactPath := range artifactPaths {
			newArtifactsPath := filepath.Join(destinationArtifacts, filepath.Base(artifactPath))
			err = copyFileIfMissing(artifactPath, newArtifactsPath)
			if err != nil {
				return err
			}
		}

		copyEnd := time.Now()

		log.Printf("checking %s: artifacts: %v", relative, copyEnd.Sub(copyStart))

		return nil
	})
	if err != nil {
		return err
	}

	for k, v := range latest {
		log.Printf("linking %v -> %v", k, v)
		link := filepath.Join(k, "latest")
		to := filepath.Join(k, fmt.Sprintf("builds/%v", v))

		os.Remove(link)

		err := os.Symlink(to, link)
		if err != nil {
			return err
		}
	}

	return nil
}

func cleanupRelativePath(relative string) string {
	return strings.Replace(relative, "jobs/", "", -1)
}
