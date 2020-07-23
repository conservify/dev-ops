#!/usr/bin/env groovy

import groovy.json.JsonSlurper

@NonCPS
def getStatusHash(String url) {
	def get = new URL(url).openConnection();
	def httpStatus = get.getResponseCode();
	if (!httpStatus.equals(200)) {
		return null
	}
	def json = new JsonSlurper().parseText(get.getInputStream().getText())
	return json.git.hash
}

def call(Map parameters = [:]) {
    try {
        stage ('watch-deploy') {
			def seconds = parameters.seconds ?: 30
			def counter = 0
			def previous = getStatusHash(parameters.url)
			if (!previous) {
				slackSend channel: '#automation', color: 'danger', message: "No status: " + parameters.url
				return false
			}
			while (counter < seconds) {
				def gitHash = getStatusHash(parameters.url)
				if (gitHash) {
					println(gitHash);
					if (previous != gitHash) {
						slackSend channel: '#automation', color: 'good', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} Deployed And Ready (<${env.BUILD_URL}|Open>)"

						println("returning, true")
						return true
					}
				}
				sleep(1)
				counter += 1
			}

			slackSend channel: '#automation', color: 'danger', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} Oh, no. Deploy took too long (<${env.BUILD_URL}|Open>)"

			println("returning(a), false")
			return false
		}
	}
	catch (Exception e) {
		throw e;
	}

	println("returning(b), false")
	return false
}
