#!/bin/bash

set -e

# Need to pull the latest change for Lingua Franca
pod update

if ! which xctool >/dev/null; then
	echo xctool is NOT installed
	
	if ! which brew >/dev/null; then
		echo Homebrew is not installed. Please install it first from http://brew.sh
		exit 1
	fi

	brew install xctool
fi

DIR=`pwd`i
PACKAGE_NAME=`date +"%Y%m%d_%H%M"`
PACKAGE_DIR=package/$PACKAGE_NAME

# Run tests
#xctool -workspace QredoSDK_pods.xcworkspace -scheme QredoSDKTests -sdk iphonesimulator test

# Building the SDK package
BUILD_PARAMS="-workspace QredoSDK_pods.xcworkspace"

LIBS=""

function build {
	ARCH=$2
	SDK=$1
	echo Building for architecture $ARCH $SDK
	TEMP_DIR=$DIR/build/temp/$SDK/$ARCH
	BUILD_DIR=$DIR/build/$SDK/$ARCH
	rm -Rf $TEMP_DIR $BUILD_DIR
	xctool $BUILD_PARAMS -scheme Pods-QredoSDK-LinguaFranca -sdk $SDK -arch $ARCH CONFIGURATION_BUILD_DIR=$BUILD_DIR CONFIGURATION_TEMP_DIR=$TEMP_DIR  
	xctool $BUILD_PARAMS -scheme Pods-QredoSDK -sdk $SDK -arch $ARCH CONFIGURATION_BUILD_DIR=$BUILD_DIR CONFIGURATION_TEMP_DIR=$TEMP_DIR  
	xctool $BUILD_PARAMS -scheme QredoSDK -sdk $SDK -arch $ARCH CONFIGURATION_BUILD_DIR=$BUILD_DIR CONFIGURATION_TEMP_DIR=$TEMP_DIR  
	LIBS="$LIBS $BUILD_DIR/libQredoSDK.a"
}

rm -Rf build test
build "iphonesimulator" "i386"
build "iphonesimulator" "x86_64"

build "iphoneos" "armv7"
build "iphoneos" "arm64"
build "iphoneos" "armv7s"

echo Making the fat library
mkdir -p $PACKAGE_DIR
lipo -create $LIBS -output $PACKAGE_DIR/libQredoSDK.a

echo Copying public header files
rsync -r --exclude=.DS_Store QredoSDK/include $PACKAGE_DIR
cp Pods/Headers/Public/LinguaFranca/QredoQUID.h $PACKAGE_DIR/include
cp Pods/Headers/Public/LinguaFranca/QredoErrorCodes.h $PACKAGE_DIR/include

cd $PACKAGE_DIR && zip -9 -r ../qredo_ios_sdk_$PACKAGE_NAME.zip *

cd $DIR
