#!/bin/bash

env

ANDROID_SDK_VERSION=3859397
GRADLE_VERSION=4.6
GRADLE_HOME=./gradle-${GRADLE_VERSION}
ANDROID_HOME=./android-sdk
PATH=${PATH}:${GRADLE_HOME}/bin:${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools/bin

set -xe

if [ ! -f sdk-tools-linux-${ANDROID_SDK_VERSION}.zip ]; then
  wget -q https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_VERSION}.zip
fi

# We actually have just used the wrapper, but this is installed anyway.
if [ ! -f gradle-${GRADLE_VERSION}-bin.zip ]; then
    wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
    unzip gradle*.zip
fi

ls -alh

if [ ! -d android-sdk/bin ]; then
	ls -alh android-sdk
	mkdir -p android-sdk
    cd android-sdk
    unzip ../*tools*linux*.zip
    cd ..
fi

sdkmanager --list

yes | sdkmanager "build-tools;23.0.1" "build-tools;25.0.0" "build-tools;25.0.1" "build-tools;25.0.3" "build-tools;26.0.1" "build-tools;28.0.2" "build-tools;29.0.2"
yes | sdkmanager "platforms;android-23" "platforms;android-25" "platforms;android-26" "platforms;android-27" "platforms;android-28" "platforms;android-29"
