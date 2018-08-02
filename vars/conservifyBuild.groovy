#!/usr/bin/env groovy

def call(Map parameters = [:]) {
    repository = parameters.repository
    name = parameters.name

    if (!name) {
        error 'conservifyBuild: Name is required'
    }

    if (!repository) {
        error 'conservifyBuild: Repository is required'
    }

    stage ('git') {
        checkout([$class: 'GitSCM', branches: [[name: '*/master']], userRemoteConfigs: [[url: repository]]])
    }

    stage ('clean') {
        sh "make clean"
    }

    stage ('build') {
        sh "make"
    }

    stage ('archive') {
        archiveArtifacts artifacts: 'build/*.bin'
    }

    // currentBuild.displayName = version
    // currentBuild.description = "Docker: ${tag}"
    return
}
