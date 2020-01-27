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

/*
   <hudson.plugins.git.util.BuildData plugin="git@4.1.1">
     <buildsByBranchName>
       <entry>
         <string>master</string>
         <hudson.plugins.git.util.Build>
           <marked plugin="git-client@3.1.1">
             <sha1>c517ccee19e8539338c9a2082db7326cfab255c2</sha1>
             <branches class="singleton-set">
               <hudson.plugins.git.Branch>
                 <sha1 reference="../../../sha1"/>
                 <name>master</name>
               </hudson.plugins.git.Branch>
             </branches>
           </marked>
           <revision reference="../marked"/>
           <hudsonBuildNumber>408</hudsonBuildNumber>
         </hudson.plugins.git.util.Build>
       </entry>
     </buildsByBranchName>
     <lastBuild reference="../buildsByBranchName/entry/hudson.plugins.git.util.Build"/>
     <remoteUrls>
       <string>https://github.com/conservify/dev-ops.git</string>
     </remoteUrls>
   </hudson.plugins.git.util.BuildData>
*/

type BuildData struct {
	BranchName  string `xml:"buildsByBranchName>entry>string"`
	BuildNumber int32  `xml:"buildsByBranchName>entry>hudson.plugins.git.util.Build>hudsonBuildNumber"`
	BuildCommit string `xml:"buildsByBranchName>entry>hudson.plugins.git.util.Build>marked/sha1"`
}

type BuildInfo struct {
	Duration  int64        `xml:"duration"`
	Timestamp int64        `xml:"timestamp"`
	StartTime int64        `xml:"startTime"`
	Status    string       `xml:"result"`
	BuildData []*BuildData `xml:"actions>hudson.plugins.git.util.BuildData"`
}

func (i *BuildInfo) BuildNumber() int32 {
	for _, b := range i.BuildData {
		return b.BuildNumber
	}
	return -1
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
