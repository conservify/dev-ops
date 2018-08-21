#!/usr/bin/env groovy

def call(Map parameters = [:]) {
    stage ('distribute') {
        def directory = parameters.directory ?: "build"

        def command = "fktool --host api.fkdev.org --scheme https --firmware-directory " + directory

        if (parameters.module) {
            command += " --module " + parameters.module
        }

        def files = findFiles(glob: 'build/*.bin')
        if (files.length > 0) {
            echo files.toString()
            sh command
        }
        else {
            echo "No files to distribute."
        }
    }
}
