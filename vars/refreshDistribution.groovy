#!/usr/bin/env groovy

def call(Map parameters = [:]) {
    node ('master') {
        lock("distribution") {
            copyArtifacts(projectName: 'distribution', flatten: true)
            sh "./artifacts-publisher --source ~/jobs --destination /var/lib/distribution"
        }
    }

    return
}
