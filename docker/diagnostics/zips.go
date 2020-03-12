package main

import (
	"io"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"

	"archive/zip"
)

func ZipDirectory(directory string) (string, error) {
	zipPath := directory + ".zip"

	if _, err := os.Stat(zipPath); !os.IsNotExist(err) {
		return zipPath, nil
	}

	log.Printf("compressing %v", directory)

	newZipFile, err := os.Create(zipPath)
	if err != nil {
		return "", err
	}

	defer newZipFile.Close()

	zipWriter := zip.NewWriter(newZipFile)
	defer zipWriter.Close()

	files, err := ioutil.ReadDir(directory)
	if err != nil {
		return "", err
	}

	for _, file := range files {
		filePath := filepath.Join(directory, file.Name())

		log.Printf("adding %v", filePath)

		if err = addFileToZip(zipWriter, filePath); err != nil {
			return "", err
		}
	}

	return zipPath, nil
}

func addFileToZip(zipWriter *zip.Writer, filename string) error {
	fileToZip, err := os.Open(filename)
	if err != nil {
		return err
	}

	defer fileToZip.Close()

	info, err := fileToZip.Stat()
	if err != nil {
		return err
	}

	header, err := zip.FileInfoHeader(info)
	if err != nil {
		return err
	}

	header.Name = filename
	header.Method = zip.Deflate

	writer, err := zipWriter.CreateHeader(header)
	if err != nil {
		return err
	}

	_, err = io.Copy(writer, fileToZip)

	return err
}
