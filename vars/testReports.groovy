#!/usr/bin/env groovy

def call(Map parameters = [:]) {
    step([$class: 'XUnitBuilder', testTimeMargin: '3000', thresholdMode: 1, thresholds: [], tools: [GoogleTest(deleteOutputFiles: true, failIfNotNew: true, pattern: 'build/tests*.xml', skipNoTestFiles: true, stopProcessingIfError: true)]])
}
