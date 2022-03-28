#!/usr/bin/env groovy

def call(maybeException = null) {
    if (maybeException != null) {
        if (maybeException instanceof java.lang.InterruptedException) {
            return;
        }
    }

	def jobName = URLDecoder.decode(env.JOB_NAME)
    slackSend channel: '#automation', color: 'danger', message: "${jobName} - #${env.BUILD_NUMBER} <${env.BUILD_URL}|Failed>"
}
