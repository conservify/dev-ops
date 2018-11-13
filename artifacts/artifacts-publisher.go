package main

import (
	"flag"
	"fmt"
	"log"
	"os"
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

	if o.Source == "" {
		fmt.Printf("Usage of %s:\n", os.Args[0])
		flag.PrintDefaults()
		os.Exit(2)
	}

	if o.Source != "" && o.Destination != "" {
		ac := NewArtifactsCopier(o.Destination)
		err := ac.Copy(o.Source)
		if err != nil {
			log.Fatalf("Error: %v", err)
		}
	}

	if o.Destination != "" {
		mg := NewMenuGenerator()
		err := mg.GenerateMenu(o.Destination)
		if err != nil {
			log.Fatalf("Error: %v", err)
		}

		indexer := NewIndexer()
		err = indexer.GenerateFileIndex(o.Destination)
		if err != nil {
			log.Fatalf("Error: %v", err)
		}
	}
}
