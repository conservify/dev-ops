package main

import (
	"io"
	"log"
	"os"
	"path/filepath"
)

func mkdirAllIfMissing(p string) error {
	if _, err := os.Stat(p); os.IsNotExist(err) {
		if false {
			log.Printf("mkdir %v", p)
		}

		err = os.MkdirAll(p, 0755)
		if err != nil {
			return err
		}
	}
	return nil
}

func copyFileIfMissing(s, d string) error {
	if _, err := os.Stat(d); os.IsNotExist(err) {
		if false {
			log.Printf("copying %v -> %v", s, d)
		}

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
