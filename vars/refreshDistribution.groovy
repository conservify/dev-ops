#!/usr/bin/env groovy

def call(Map parameters = [:]) {
    node ('main') {
        lock("distribution") {
            copyArtifacts(projectName: 'dev-ops', flatten: true)
            sh "./artifacts-publisher --source ~jenkins/jobs --destination /var/lib/distribution --jobs mobile-app-android,mobile-app-ios,patina-android,patina-ios"
        }
    }

    return
}
