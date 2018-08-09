#!/usr/bin/env groovy

def call(Map parameters = [:]) {
    node ('master') {
        dir ("../distribution") {
            sh "build/artifacts-publisher --source ~/jobs --destination /var/lib/distribution"
        }
    }

    return
}
