def call(goArch) {
    node ("master") {
        def go = tool "golang-amd64"
        def build = createDirectory("build")
        def pkg = createDirectory("package")

        sh "env"

        withEnv(["PATH+GOLANG=${go}/bin", "GOARCH=" + goArch, "GOOS=linux", "GOROOT=${go}"]) {
            sh "which go"
            sh "env"

            stage ("simple-deps") {
                dir ("github.com/conservify/simple-deps") {
                    git branch: 'main', url: 'https://github.com/Conservify/simple-deps.git'

                    sh "make deps && make"
                    sh "cp build/* ${pkg}"
                }
            }
            stage ("flasher") {
                dir ("github.com/conservify/flasher") {
                    git branch: 'main', url: 'https://github.com/Conservify/flasher.git'

                    sh "make deps && make"
                    sh "cp -ar build/linux-arm/* ${pkg}"
                }
            }
            stage ("dev-ops") {
                dir ("github.com/conservify/dev-ops") {
                    git branch: 'main', url: 'https://github.com/Conservify/dev-ops.git'

                    sh "make"
                }
            }
            stage ("fktool") {
                dir ("github.com/fieldkit/cloud") {
                    git branch: 'main', url: 'https://github.com/fieldkit/cloud.git'

                    sh "make fktool"
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
