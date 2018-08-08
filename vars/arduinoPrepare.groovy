#!/usr/bin/env groovy

def call(Map parameters = [:]) {
    stage ('prepare') {
        echo "Preparing Arduino Packages"

        def cmake = tool("cmake")
        echo cmake

        dir ('..') {
            sh "env; pwd"

            if (!fileExists('arduino-packages/.git/config')) {
                dir ('arduino-packages') {
                    checkout([$class: 'GitSCM', branches: [[name: '*/linux']], userRemoteConfigs: [[url: 'https://github.com/jlewallen/arduino-packages.git']]])
                }
            }

            dir ('arduino-ide') {
                sh """
if [ ! -d arduino-1.8.3 ]; then
  if [ ! -f arduino-1.8.3-linux64.tar.xz ]; then
    wget https://downloads.arduino.cc/arduino-1.8.3-linux64.tar.xz
  fi
  tar xf arduino-1.8.3-linux64.tar.xz
  (cd arduino-1.8.3 && ln -sf ../../arduino-packages/packages packages)
  (cd .. && ln -sf arduino-ide/arduino-1.8.3 arduino-1.8.3)
fi
"""
            }

            dir ("arduino-cmake-minimal") {
                if (!fileExists('arduino-cmake-minimal/.git/config')) {
                    checkout([$class: 'GitSCM', branches: [[name: '*/master']], userRemoteConfigs: [[url: 'https://github.com/Conservify/arduino-cmake-minimal.git']]])
                }
                else {
                    sh "env"
                    sh "git checkout master && git pull origin master"
                }
            }
        }
    }

    return
}
