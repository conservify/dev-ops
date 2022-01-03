#!/usr/bin/env groovy

def call(Map parameters = [:]) {
    node ('main') {
        lock("distribution") {
            copyArtifacts(projectName: 'dev-ops', flatten: true)
            sh "./artifacts-publisher --source ~/jobs --destination /var/lib/distribution"
        }
    }

    return
}
