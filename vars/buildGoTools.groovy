def call(goArch) {
    node ("master") {
        def go = tool "golang-amd64"
        def build = createDirectory("build")
        def pkg = createDirectory("package")

        sh "env"

        withEnv(["PATH+GOLANG=/bin:/usr/local/bin:/usr/bin:${go}/bin", "GOARCH=" + goArch, "GOOS=linux", "GOROOT=${go}"]) {
            sh "which go"
            sh "env"

            stage ("simple-deps") {
                dir ("github.com/Conservify/simple-deps") {
                    git branch: 'master', url: 'https://github.com/Conservify/simple-deps.git'

                    sh "make deps && make"
                    sh "cp build/* ${pkg}"
                }
            }
            stage ("flasher") {
                dir ("github.com/Conservify/flasher") {
                    git branch: 'master', url: 'https://github.com/Conservify/flasher.git'

                    sh "make deps && make"
                    sh "cp -ar build/linux-arm/* ${pkg}"
                }
            }
            stage ("dev-ops") {
                dir ("github.com/Conservify/dev-ops") {
                    git branch: 'master', url: 'https://github.com/Conservify/dev-ops.git'

                    sh "make"
                }
            }
            stage ("fktool") {
                dir ("github.com/fieldkit/cloud") {
                    git branch: 'master', url: 'https://github.com/fieldkit/cloud.git'

                    sh "make deps && make build/fktool"
                    sh "cp build/fktool ${pkg}"
                }
            }

            stage ("archive") {
                dir (pkg) {
                    stash name: "tools", includes: "**"
                    archiveArtifacts artifacts: '**'
                }
            }
        }
        deleteDir()
    }
}
