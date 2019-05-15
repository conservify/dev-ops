#!/usr/bin/env groovy

def call(List additional = [], Map parameters = [:]) {
    def props = [] + additional

    props.add([$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', numToKeepStr: '5']])

    if (parameters.manual) {
    }
    else {
        props.add(pipelineTriggers([cron('@weekly'), githubPush()]))
    }

    properties(props)
}
