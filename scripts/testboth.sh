#!/bin/bash

lockfile=/tmp/testmultiple.lock

if [ ! -f $lockfile ]; then

    touch $lockfile

    xcodebuild -workspace QredoSDK.xcworkspace -scheme ConversationCreateTests -destination name="iPhone 6" test &
	XCODEPIG1=$!
	xcodebuild -workspace QredoSDK.xcworkspace -scheme ConversationRespondTests -destination name="iPhone 6" test &
	XCODEPIG2=$!
	wait $XCODEPIG1
	wait $XCODEPIG2

	rm -f $lockfile
	rm -f /tmp/multipletag.tmp

else
    echo "Sorry, test is already running, please wait..."
    exit 1
fi

