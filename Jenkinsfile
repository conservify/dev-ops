@Library('conservify') _

conservifyProperties([
    pipelineTriggers([upstream('fk/mobile-app-ios, fk/mobile-app-android')])
])

timestamps {
    node {
        stage ('git') {
            checkout scm
        }

        stage ('build') {
              withEnv(["PATH+GOLANG=${tool 'golang-amd64'}/bin"]) {
                sh "make clean build"
            }
        }

        stage ('archive') {
            sh "cp artifacts/* build"
            sh "rm build/*.go"
            archiveArtifacts artifacts: 'build/*'
        }

        stage ('publish') {
            sh "cp build/artifacts-publisher /var/lib/distribution"
            sh "cp build/*.template /var/lib/distribution"
            sh "cp build/favicon.png /var/lib/distribution"
        }
    }

    // This will fail the first time this is run, because there's no dev-ops
    // build to pull artifacts from.
	try {
		refreshDistribution()
	}
	catch (Exception e) {
		slackSend channel: '#automation', color: 'good', message: "${env.JOB_NAME} - #${env.BUILD_NUMBER} Distribution Error (may be ok) (<${env.BUILD_URL}|Open>)"
	}
}
