#!/bin/bash

env

ANDROID_SDK_VERSION=8092744
GRADLE_VERSION=7.4.1
GRADLE_HOME=./gradle
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
	mv gradle-${GRADLE_VERSION} gradle
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

yes | sdkmanager --install "build-tools;30.0.3"
yes | sdkmanager --install "platforms;android-33"
yes | sdkmanager --install "platform-tools"
yes | sdkmanager --install "cmdline-tools;latest"
yes | sdkmanager --install "ndk;25.2.9519653"
yes | sdkmanager --install "cmake;3.22.1"

