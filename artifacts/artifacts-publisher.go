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

	am := NewArtifactsManager(o.Destination)
	mg := NewMenuGenerator()
	indexer := NewIndexer()

	if o.Source != "" && o.Destination != "" {
		err := am.Copy(o.Source)
		if err != nil {
			log.Fatalf("Error: %v", err)
		}
	}

	if o.Destination != "" {
		err := mg.GenerateMenu(o.Destination)
		if err != nil {
			log.Fatalf("Error: %v", err)
		}

		err = indexer.GenerateIndex(o.Destination)
		if err != nil {
			log.Fatalf("Error: %v", err)
		}
	}
}
