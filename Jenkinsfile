@Library('conservify') _

conservifyProperties()

timestamps {
    node {
        stage ('git') {
            checkout scm
        }

        stage ('build') {
            sh "make clean build"
        }

        stage ('archive') {
            sh "cp artifacts/* build"
            archiveArtifacts artifacts: 'build/*'
        }

        stage ('publish') {
            sh "cp artifacts/*.template /var/lib/distribution"
            sh "cp artifacts/favicon.png /var/lib/distribution"

            refreshDistribution()
        }
    }
}
