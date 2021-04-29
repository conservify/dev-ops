#!/usr/bin/env groovy

def call() {
    slackSend channel: '#automation', color: 'danger', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} <${env.BUILD_URL}|Failed>"
}
