#!/usr/bin/env groovy

def call(Map parameters = [:], List additional = []) {
    def props = [] + additional

    echo 'Applying Conservify properties'

    props.add([$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', numToKeepStr: '5']])

    if (parameters.manual) {
        echo 'Manual triggers enabled.'
    }
    else {
        echo 'Configuring default triggers.'
        props.add(pipelineTriggers([cron('@weekly'), githubPush()]))
    }

    properties(props)
}
