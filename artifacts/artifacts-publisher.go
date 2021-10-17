package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"time"
)

type options struct {
	Source      string
	Destination string
}

func main() {
	o := options{}

	flag.StringVar(&o.Source, "source", "", "source directory")
	flag.StringVar(&o.Destination, "destination", "", "destination directory")

	flag.Parse()

	if o.Source == "" && o.Destination == "" {
		fmt.Printf("usage of %s:\n", os.Args[0])
		flag.PrintDefaults()
		os.Exit(2)
	}

	forcePreserve := make([]string, 0)

	if o.Source != "" && o.Destination != "" {
		ac := NewArtifactsCopier(o.Destination)
		err := ac.Copy(o.Source)
		if err != nil {
			log.Fatalf("error: %v", err)
		}

		forcePreserve = ac.Copied
	}

	if o.Destination != "" {
		indexer := NewIndexer()
		maximumAge := (time.Hour * 24) * 90
		err := indexer.DeleteOldBuilds(o.Destination, maximumAge, forcePreserve)
		if err != nil {
			log.Fatalf("error: %v", err)
		}
		err = indexer.GenerateFileIndex(o.Destination)
		if err != nil {
			log.Fatalf("error: %v", err)
		}

		mg := NewMenuGenerator()
		err = mg.GenerateMenu(o.Destination)
		if err != nil {
			log.Fatalf("error: %v", err)
		}
	}
}
