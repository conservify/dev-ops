timestamps {
    node () {
        stage ('git') {
            checkout([$class: 'GitSCM', branches: [[name: '*/master']], userRemoteConfigs: [[url: 'https://github.com/Conservify/dev-ops.git']]])
        }

        stage ('build') {
            sh """
make clean build

cp artifacts/*.template /var/lib/distribution
cp artifacts/favicon.png /var/lib/distribution
cp build/artifacts-publisher /var/lib/distribution

ls -alh /var/lib/distribution
"""
        }
    }
}
