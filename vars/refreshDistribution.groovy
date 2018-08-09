#!/usr/bin/env groovy

def call(Map parameters = [:]) {
    node ('master') {
        sh "/var/lib/distribution/artifacts-publisher --source ~/jobs --destination /var/lib/distribution"
    }

    return
}
