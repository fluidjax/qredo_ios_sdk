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

	echo Please install xctool by running 'brew install xctool'
fi

PWD=`pwd`
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT_DIR=$( cd "$DIR/.." && pwd )

cd $ROOT_DIR

PACKAGE_NAME=`date +"%Y%m%d_%H%M"`
PACKAGE_DIR=$ROOT_DIR/package/$PACKAGE_NAME
LIBRARY_DIR=$PACKAGE_DIR/lib
SAMPLES_DIR=$PACKAGE_DIR/samples
TEMP_DIR=$ROOT_DIR/temp
BUILD_DIR=$ROOT_DIR/build

echo Package directory: $LIBRARY_DIR

# Run tests
#xctool -workspace QredoSDK_pods.xcworkspace -scheme QredoSDKTests -sdk iphonesimulator test

# Building the SDK package
BUILD_PARAMS="-workspace QredoSDK_pods.xcworkspace"

LIBS=""

function build {
	ARCH=$2
	SDK=$1
	echo Building for architecture $ARCH $SDK
	TEMP_DIR=$ROOT_DIR/build/temp/$SDK/$ARCH
	BUILD_DIR=$ROOT_DIR/build/$SDK/$ARCH
	rm -Rf $TEMP_DIR $BUILD_DIR
	xctool $BUILD_PARAMS -scheme Pods-QredoSDK-LinguaFranca -sdk $SDK -arch $ARCH CONFIGURATION_BUILD_DIR=$BUILD_DIR CONFIGURATION_TEMP_DIR=$TEMP_DIR  
	xctool $BUILD_PARAMS -scheme Pods-QredoSDK -sdk $SDK -arch $ARCH CONFIGURATION_BUILD_DIR=$BUILD_DIR CONFIGURATION_TEMP_DIR=$TEMP_DIR  
	xctool $BUILD_PARAMS -scheme QredoSDK -sdk $SDK -arch $ARCH CONFIGURATION_BUILD_DIR=$BUILD_DIR CONFIGURATION_TEMP_DIR=$TEMP_DIR  
	LIBS="$LIBS $BUILD_DIR/libqredosdk.a"
}

rm -Rf $BUILD_DIR $TEMP_DIR

build "iphonesimulator" "i386"
build "iphonesimulator" "x86_64"

build "iphoneos" "armv7"
build "iphoneos" "arm64"
build "iphoneos" "armv7s"

echo Making the fat library
mkdir -p $LIBRARY_DIR
lipo -create $LIBS -output $LIBRARY_DIR/libqredosdk.a

echo Copying public header files
rsync -r --exclude=.DS_Store QredoSDK/include $LIBRARY_DIR
cp Pods/Headers/Public/LinguaFranca/QredoQUID.h $LIBRARY_DIR/include

echo Cloning examples from git
EXAMPLES_DIR=$TEMP_DIR/examples
rm -Rf $EXAMPLES_DIR
mkdir -p $EXAMPLES_DIR
git clone --depth 1 git@github.com:Qredo/qredo_ios_examples.git $EXAMPLES_DIR

echo Preparing samples content
mkdir -p $SAMPLES_DIR

# Prepare samples
function cpex {
	echo Copying from $1
	rsync -r --exclude=.DS_Store --exclude='.git' --exclude Podfile.lock --exclude Pods --exclude='*.xcworkspace' \
		--exclude='*.xcuserdatad' \
		$1 $2
}

# Copy sample projects
cpex $EXAMPLES_DIR/SDKExamples $SAMPLES_DIR 
cpex $EXAMPLES_DIR/QatChat $SAMPLES_DIR
cpex $EXAMPLES_DIR/QRCodeRendezvous $SAMPLES_DIR 
cpex $EXAMPLES_DIR/BLERendezvous $SAMPLES_DIR 

# Modify podspec in each sample to include the relative link to the Qredo SDK
for i in $(find $SAMPLES_DIR -name "Podfile"); do
	cat $i | grep -v "LinguaFranca" | egrep -v "^#" | grep -v "qredo_cocoapods" | \
		sed 's/pod\(.*\)"QredoSDK"\(.*\)/pod "QredoSDK", :path => "..\/..\/lib\/QredoSDK.podspec"/g' > $i.new
	mv $i.new $i
done

mkdir -p $LIBRARY_DIR
cp $DIR/QredoSDK.podspec $LIBRARY_DIR/QredoSDK.podspec 

# Test if the source files contain the developers names
teststr=`(find $PACKAGE_DIR -name '*.h' -o -name '*.swift' -o -name '*.m' | xargs \
	egrep --color=always 'Dmitry|David|Gabriel|Justin|jmegawarne|Hugh') \
	|| echo ""`
if ["$teststr" eq ""]; then
	echo "Names are not found. Sources are ok"
else
	echo "Please remove developer's names from the source files"
	exit 1
fi

echo Archiving the package qredo_ios_sdk_$PACKAGE_NAME.zip
cd $PACKAGE_DIR && zip -9 -r $PACKAGE_DIR/../qredo_ios_sdk_$PACKAGE_NAME.zip * -x "*.DS_Store"

cd $PWD
