#!/usr/bin/env groovy

def call() {
	def maybeVersion = currentBuild.description
	def jobName = URLDecoder.decode(env.JOB_NAME)
	if (maybeVersion && maybeVersion != "") {
		slackSend channel: '#automation', color: 'good', message: "${jobName} - #${env.BUILD_NUMBER} <${env.BUILD_URL}|Success> (${maybeVersion})"
	}
	else {
		slackSend channel: '#automation', color: 'good', message: "${jobName} - #${env.BUILD_NUMBER} <${env.BUILD_URL}|Success>"
	}
}
