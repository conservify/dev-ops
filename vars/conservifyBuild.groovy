#!/usr/bin/env groovy

def call(Map parameters = [:]) {
    repository = parameters.repository
    name = parameters.name
    archive = parameters.archive
    distribute = parameters.distribute

    if (!name) {
        error 'conservifyBuild: Name is required'
    }

    stage ('git') {
        if (repository) {
            git branch: 'master', url: repository
        }
        else {
            checkout scm
        }
    }

    stage ('clean') {
        sh "rm -rf gitdeps"
        sh "make clean"
    }

    stage ('deps') {
        def files = findFiles(glob: '**/arduino-libraries')
        if (files.length > 0) {
            sh "rm -rf gitdeps"
            sh "make gitdeps"
        }
    }

    stage ('build') {
        sh "make"
    }

    if (archive) {
        stage ('archive') {
            archiveArtifacts artifacts: 'build/*.bin'
        }
    }

    // slackSend channel: '#automation', color: 'good', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} Back to normal (<${env.BUILD_URL}|Open>)"

    return
}
