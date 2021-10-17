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
   <hudson.plugins.git.util.BuildData plugin="git@4.2.2">
     <buildsByBranchName>
       <entry>
         <string>main</string>
         <hudson.plugins.git.util.Build>
           <marked plugin="git-client@3.2.1">
             <sha1>d323e748cdc0cbd56bd4ee206611f7597fc92186</sha1>
             <branches class="singleton-set">
               <hudson.plugins.git.Branch>
                 <sha1 reference="../../../sha1"/>
                 <name>main</name>
               </hudson.plugins.git.Branch>
             </branches>
           </marked>
           <revision reference="../marked"/>
           <hudsonBuildNumber>621</hudsonBuildNumber>
         </hudson.plugins.git.util.Build>
       </entry>
       <entry>
         <string>master</string>
         <hudson.plugins.git.util.Build>
           <marked plugin="git-client@3.2.1">
             <sha1>498d3641af0924267a1fefbbc97e2671d6f0d42e</sha1>
             <branches class="list">
               <hudson.plugins.git.Branch>
                 <sha1 reference="../../../sha1"/>
                 <name>master</name>
               </hudson.plugins.git.Branch>
             </branches>
           </marked>
           <revision plugin="git-client@3.2.1">
             <sha1 reference="../../marked/sha1"/>
             <branches class="list">
               <hudson.plugins.git.Branch reference="../../../marked/branches/hudson.plugins.git.Branch"/>
             </branches>
           </revision>
           <hudsonBuildNumber>613</hudsonBuildNumber>
         </hudson.plugins.git.util.Build>
       </entry>
     </buildsByBranchName>
     <lastBuild reference="../buildsByBranchName/entry/hudson.plugins.git.util.Build"/>
     <remoteUrls>
       <string>https://github.com/conservify/dev-ops.git</string>
     </remoteUrls>
   </hudson.plugins.git.util.BuildData>
*/

type BuildBranch struct {
	BranchName  string `xml:"string"`
	BuildNumber int32  `xml:"hudson.plugins.git.util.Build>hudsonBuildNumber"`
	BuildCommit string `xml:"hudson.plugins.git.util.Build>marked/sha1"`
}

type BuildData struct {
	Branches []*BuildBranch `xml:"buildsByBranchName>entry"`
}

type BuildInfo struct {
	Duration    int64        `xml:"duration"`
	Timestamp   int64        `xml:"timestamp"`
	StartTime   int64        `xml:"startTime"`
	Status      string       `xml:"result"`
	Description *string      `xml:"description"`
	BuildData   []*BuildData `xml:"actions>hudson.plugins.git.util.BuildData"`
}

func (i *BuildInfo) BuildNumber() int32 {
	buildsByBranch := make(map[string]int32)
	for _, data := range i.BuildData {
		for _, branch := range data.Branches {
			buildsByBranch[branch.BranchName] = branch.BuildNumber
			return branch.BuildNumber
		}
	}
	return -1
}

type BuildWalkFunc func(path string, relative string, jobName string, buildXmlPath string, build *BuildInfo, artifactPaths []string) error

type GuardFunc func(path string) bool

// Sorry.
func fixXmlVersion(bytes []byte) []byte {
	return []byte(strings.Replace(strings.Replace(string(bytes), "version=\"1.1\"", "version=\"1.0\"", 1), "version='1.1'", "version='1.0'", 1))
}

func getPartBefore(parts []string, literal string) string {
	previous := ""
	for _, value := range parts {
		if value == literal {
			return previous
		}
		previous = value
	}
	return ""
}

func getJobName(path string) string {
	pathParts := strings.Split(path, "/")
	branchPart := getPartBefore(pathParts, "branches")
	buildPart := getPartBefore(pathParts, "builds")
	if branchPart == "" {
		return buildPart
	}
	return branchPart + " " + buildPart
}

func walkBuilds(base string, walkFunc BuildWalkFunc) error {
	return walkBuildsWithGuard(base, func(path string) bool {
		return true
	}, walkFunc)
}

func walkBuildsWithGuard(base string, guardPath GuardFunc, walkFunc BuildWalkFunc) error {
	return filepath.Walk(base, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			log.Printf("error: %v %v", path, err)
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

		jobName := getJobName(buildXmlPath)

		data, err := ioutil.ReadFile(buildXmlPath)
		if err != nil {
			return err
		}

		buildInfo := BuildInfo{}
		err = xml.Unmarshal(fixXmlVersion(data), &buildInfo)
		if err != nil {
			return fmt.Errorf("error reading %s (%v)", buildXmlPath, err)
		}

		artifactPaths, err := getFilesUnder([]string{filepath.Join(path, "archive"), filepath.Join(path, "artifacts")})
		if err != nil {
			return err
		}

		return walkFunc(path, relative, jobName, buildXmlPath, &buildInfo, artifactPaths)
	})
}
