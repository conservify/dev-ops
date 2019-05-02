@Library('conservify') _

conservifyProperties([
    pipelineTriggers([upstream('fk/app-ios, fk/app-android, fk/app-android-easy-mode')])
])

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
    // build to pull artifacts from. We should make this optional.
    refreshDistribution()
}
