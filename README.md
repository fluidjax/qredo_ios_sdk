# Qredo SDK

### Steps to build & test

This is for the internal testing of the SDK and development.

`git clone --recursive git@github.com:Qredo/qredo_ios_sdk.git`

`cd qredo_ios_sdk`

`pod install`

`open QredoSDK.xcworkspace`

then `CMD + B` and `CMD + U`...

#### Oneliner:

```

git clone --recursive git@github.com:Qredo/qredo_ios_sdk.git && cd qredo_ios_sdk && pod install && open QredoSDK.xcworkspace

```

---

### Steps to include in a project

Add this line to a `Podfile` (with a proper link to a podspec)

For now you need to:

`git clone --recursive git@github.com:Qredo/qredo_ios_sdk.git -b baptism-by-drowning`

`cd your_project_name`

`echo 'pod "QredoSDK", :path => "../qredo_ios_sdk/QredoSDK.podspec"' >> Podfile'`

`pod install`

`open QredoSDK.xcworkspace`

then `CMD + B` and `CMD + U`...

---

### Podspec

```

pod spec lint QredoSDK.podspec --use-libraries --allow-warnings --verbose --fail-fast --no-clean

```

---

### CLI build

```

xcodebuild -workspace QredoSDK.xcworkspace -scheme QredoSDK -destination name="iPhone 6" build

```

---
# ios_build
