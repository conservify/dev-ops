#!/usr/bin/env groovy

def call() {
	def maybeVersion = currentBuild.description
	if (maybeVersion && maybeVersion != "") {
		slackSend channel: '#automation', color: 'good', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} <${env.BUILD_URL}|Success> (${maybeVersion})"
	}
	else {
		slackSend channel: '#automation', color: 'good', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} <${env.BUILD_URL}|Success>"
	}
}
