#!/usr/bin/env groovy

def call(path) {
    def actual = ""
    dir (path) {
        sh "pwd"
        actual = pwd()
    }
    return actual
}
