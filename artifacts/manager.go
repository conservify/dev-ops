package main

import (
	"log"
	"path/filepath"
	"strings"
)

type ArtifactsManager struct {
	Directory string
}

func NewArtifactsManager(directory string) (am *ArtifactsManager) {
	return &ArtifactsManager{
		Directory: directory,
	}
}

func (am *ArtifactsManager) Copy(source string) error {
	archive := filepath.Join(am.Directory, "archive")

	log.Printf("Copying %s to %s", source, archive)

	return walkBuilds(source, func(path string, relative string, jobName string, buildXmlPath string, info *BuildInfo, artifactPaths []string) error {
		if len(artifactPaths) == 0 {
			return nil
		}

		copyingTo := filepath.Join(archive, cleanupRelativePath(relative))

		if false {
			log.Printf("Processing %s -> %s (%s)", path, copyingTo, jobName)
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

func (am *ArtifactsManager) Index() error {
	return nil
}

func cleanupRelativePath(relative string) string {
	return strings.Replace(relative, "jobs/", "", -1)
}
