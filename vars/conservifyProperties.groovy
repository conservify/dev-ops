#!/usr/bin/env groovy

def call(List additional = []) {
    def props = [] + additional

    props.add([$class: 'BuildDiscarderProperty', strategy: [$class: 'LogRotator', numToKeepStr: '5']])
    props.add(pipelineTriggers([cron('@weekly'), githubPush()]))

    properties(props)
}
