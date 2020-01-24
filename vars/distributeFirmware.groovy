#!/usr/bin/env groovy

def call(Map parameters = [:]) {
    stage ('distribute') {
        def command = "fktool --host api.fkdev.org --scheme https"

		if (parameters.directory) {
		   command += " --firmware-directory " + parameters.directory
		}

		if (parameters.file) {
		   command += " --firmware-file " + parameters.file
		}

        if (parameters.module) {
            command += " --module " + parameters.module
        }

        if (parameters.profile) {
            command += " --profile " + parameters.profile
        }

		echo command
		sh command
    }
}
