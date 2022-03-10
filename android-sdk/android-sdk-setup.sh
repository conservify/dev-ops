#!/bin/bash

env

ANDROID_SDK_VERSION=8092744
GRADLE_VERSION=7.4.1
GRADLE_HOME=./gradle-${GRADLE_VERSION}
ANDROID_HOME=./android-sdk
PATH=${GRADLE_HOME}/bin:${ANDROID_HOME}/emulator:${ANDROID_HOME}/cmdline-tools/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}

set -xe

if [ ! -f commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip ]; then
	wget -q https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip
fi

# We actually have just used the wrapper, but this is installed anyway.
if [ ! -f gradle-${GRADLE_VERSION}-bin.zip ]; then
	wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
	unzip gradle*.zip
fi

ls -alh

if [ ! -d android-sdk/cmdline-tools/tools/bin ]; then
	mkdir -p android-sdk/cmdline-tools
	cd android-sdk/cmdline-tools
	unzip -o ../../commandlinetools-linux*.zip
	mv * tools
	cd ../../
fi

echo $ANDROID_HOME

which sdkmanager

sdkmanager --list

yes | sdkmanager "build-tools;23.0.1" "build-tools;25.0.0" "build-tools;25.0.1" "build-tools;25.0.3" "build-tools;26.0.1" "build-tools;28.0.2" "build-tools;29.0.2"
yes | sdkmanager "platforms;android-23" "platforms;android-25" "platforms;android-26" "platforms;android-27" "platforms;android-28" "platforms;android-29" "platforms;android-30" "platforms;android-31"
yes | sdkmanager "platform-tools"
