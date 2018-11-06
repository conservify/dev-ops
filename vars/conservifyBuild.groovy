#!/usr/bin/env groovy

def call(Map parameters = [:]) {
    repository = parameters.repository
    name = parameters.name
    archive = parameters.archive
    distribute = parameters.distribute

    if (!name) {
        error 'conservifyBuild: Name is required'
    }

    try {
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
            def files = findFiles(glob: '**/arduino-libraries, **/dependencies.sd')
            if (files.length > 0) {
                sh "rm -rf gitdeps"
                sh "make gitdeps"
            }
        }

        stage ('build') {
            sh "make"
        }

        if (archive instanceof String) {
            stage ('archive') {
                archiveArtifacts artifacts: archive
            }
        }

        if (parameters.test) {
            stage ('test') {
                sh "make test"
            }
        }

        notifySuccess()
    }
    catch (Exception e) {
        notifyFailure()
        throw e;
    }

    return
}
