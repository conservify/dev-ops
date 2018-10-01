#!/usr/bin/env groovy

def call(Map parameters = [:]) {
    properties([
        [$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', numToKeepStr: '5']],
        pipelineTriggers([cron('@weekly'), githubPush()]),
    ])
}
