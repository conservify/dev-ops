package main

import (
	"log"

	"gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/config"
	"gopkg.in/src-d/go-git.v4/plumbing"
	"gopkg.in/src-d/go-git.v4/plumbing/object"
	"gopkg.in/src-d/go-git.v4/storage/memory"

	_ "github.com/nlopes/slack"
)

func getUnmergedChanges(url string, developName, masterName string) error {
	r, err := git.Clone(memory.NewStorage(), nil, &git.CloneOptions{
		URL: url,
	})
	if err != nil {
		return err
	}

	remote, err := r.Remote("origin")
	if err != nil {
		return err
	}

	if err := remote.Fetch(&git.FetchOptions{
		RefSpecs: []config.RefSpec{"refs/*:refs/*"},
	}); err != nil {
		return err
	}

	allRemoteRefs, err := remote.List(&git.ListOptions{})
	if err != nil {
		return err
	}
	remoteRefs := make(map[string]*plumbing.Reference)
	for _, reference := range allRemoteRefs {
		log.Printf("branch: %v = %v", reference.Name(), reference.Hash())
		remoteRefs[reference.Name().String()] = reference
	}

	master := remoteRefs["refs/heads/"+masterName]
	develop := remoteRefs["refs/heads/"+developName]

	iter, err := r.Log(&git.LogOptions{
		From: ref.Hash(),
	})
	if err != nil {
		return err
	}

	err = iter.ForEach(func(c *object.Commit) error {
		// log.Printf("%v", c)
		return nil
	})
	if err != nil {
		return err
	}

	return nil
}

func main() {
	log.Printf("checking...")

	err := getUnmergedChanges("https://github.com/fieldkit/app.git", "develop", "master")
	if err != nil {
		log.Fatal(err)
	}
}
