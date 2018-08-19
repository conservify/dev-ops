#!/usr/bin/env groovy

def call(Map parameters = [:]) {
    def required = false

    if (parameters.required) {
        required = true
    }

    stage ("hardware-tests") {
        copyArtifacts(projectName: 'tools-arm')

        unstash(parameters.stash)

        sh "ls -alh /dev/serial/by-path/"
        sh "rm -f *.log"

        def binaries = findFiles(glob: "*.bin")
        echo binaries.toString()

        binaries.each { file ->
            sh "./flasher --binary ${file} --port /dev/ttyACM0 --tail --tail-inactivity 5 --upload-quietly --append ${file}.log"
            checkForFailures("${file}.log", required)
        }
    }
}

def checkForFailures(String path, Boolean required) {
    def success = false
    def lines = readFile(path).split('\n')

    lines.each { line ->
        def matcher = (line =~ /.+(\d+) passed, (\d+) failed, (\d+) skipped, (\d+) timed out.+/)
        if (matcher.matches()) {
            def passed = matcher[0][1] as Integer
            def failed = matcher[0][2] as Integer
            def skipped = matcher[0][3] as Integer
            def timedOut = matcher[0][4] as Integer
            def total = passed + failed + skipped + timedOut

            if (failed > 0 || timedOut > 0) {
                error "Detected test failures: ${failed} failed, ${timedOut} timed out!"
            }
            else {
                echo "Tests: ${passed} ${failed} ${skipped} ${timedOut}"
                success = true
            }
        }
    }

    if (!success && required) {
        error "Unable to find test results."
    }

    return true
}
