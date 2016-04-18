##Qredo SDK early access developer program
(Release 0.9)

###Release Note

Welcome to the Qredo early access developer program. This release includes the libraries, sample code and tutorials to allow you to prototype apps for iOS and Android using the Qredo APIs.

The purpose of this release is to gain feedback from you about using the Qredo SDK, the APIs, services and documentation. Use this version of the Qredo SDK to build proof of concept apps with secure storage or messaging, or try out the APIs to see how Qredo fits into your existing apps.   

**This version of the Qredo SDK is for your own use and experimentation only and must not be used for final, released versions of your apps.
**

####The release archive

This release is distributed as a .zip file containing both the Android and iOS releases of the SDK. Once extracted, you'll find an Android, iOS and additional docs folder. Within the Android folder is the JAR file that you will need to include in your projects, together with the examples and tutorial solutions. The iOS folder contains the Framework file to include in your projects, as well as all the examples and tutorial code. 

####Documentation

Developer documentation can be found on our [website] (https://qredo.com/docs). This contains all programming guides and tutorials in both HTML and PDF format. We'll be adding more guides and references to the website shortly, so keep an eye out for new content.

**Note** that the *Qredo Cryptography Guide* is not available online and is included in the release archive that you downloaded, together with the *Technical Introduction to Qredo* White Paper. The information in these PDFs will be incorporated in forthcoming *Qredo Developer Guide* which will be available online.

####Getting started

The best way to start with either the iOS or Android SDK is to work through the tutorials. You can find the step by step tutorial instructions on our website for 
[Android](https://qredo.com/docs/android/tutorials/), [iOS (Swift)] (https://qredo.com/docs/ios/swift/tutorials/) and [iOS  (Objective-C)] (https://qredo.com/docs/ios/objective-c/tutorials/)

While you don’t have to work through each tutorial step by step, and completed versions of each app are included in the tutorials folder in the release repository, we do recommend at least reading through each tutorial.

• *Your First Qredo App*
This tutorial explains how to create a project that uses the Qredo APIs, the important classes and methods you use to connect to the service, and how to write to and read from the Qredo Vault. 

• *Rendezvous/Conversation*
This tutorial shows how to implement secure messaging using Rendezvous and Conversation. It shows how to create and respond to a rendezvous and how to send messages in a secure Conversation.

Once you’ve worked through each tutorial, we recommend taking a look at the sample apps.

####Programming guides

Programming guides are available for each platform and language currently supported for Qredo:

- [Qredo iOS Programming Guide for Objective-C] (https://qredo.com/docs/ios/objective-c/programming_guide/html/)
- [Qredo iOS Programming Guide for Swift] (https://qredo.com/docs/ios/swift/programming_guide/html/)
- [Qredo Android Programming Guide] (https://qredo.com/docs/android/programming_guide/html/)


####Examples

The **iOS** SDK includes *QatChat*, a messaging app, *QatPics* which demonstrates the Vault, *CustomerLookup* which shows how to retrieve items using metadata and *QRCodeRendezvous* and *BLERendezvous*, which demonstrate how to publish a Rendezvous in a QR code or BLE beacon respectively. *iOSEpiq*, a simple word game is also included. For more details on building the examples, see either language version of the *Qredo iOS Programming Guide.* 

The **Android** SDK includes *QatPics*, an app which shows how to add pictures and text to the Qredo Vault and read them back. Further examples will be added in future releases. For more details on building *QatPics*, see the *Qredo Android Programming Guide.*

After you've worked through the tutorials and run the examples, just dive in and start using the Qredo APIs in your own apps.

####AppIDs and your appSecret
In order to make use of Qredo services and run any of the example apps or tutorials, you must have an **appSecret**, together with an appID that identifies your app. The registration email we sent you included one appID and appSecret to use for each of the examples, together with an appID and appSecret to use for your own app. 

For more details of setting up the examples see the *Building the Examples* section of the [iOS (Objective-C)] (http://qredo.com/docs/ios/objective-c/programming_guide/html/building_the_examples/index.html), [iOS (Swift)] (http://qredo.com/docs/ios/swift/programming_guide/html/building_the_examples/index.html) and [Android] (http://qredo.com/docs/android/programming_guide/html/building_the_examples/index.html) programming guides.

To learn how to use the app secret and appID for your own app, see *Connecting to Qredo* in the [iOS (Objective-C)] (http://qredo.com/docs/ios/objective-c/programming_guide/html/connecting_to_qredo/index.html), [iOS (Swift)] (http://qredo.com/docs/ios/swift/programming_guide/html/connecting_to_qredo/index.html) and [Android] (http://qredo.com/docs/android/programming_guide/html/connecting_to_qredo/index.html) guides.


####Getting help

Thanks for being part of the Qredo early access developer program. We’ll keep in close contact with you as the program progresses and to let you know about updates, fixes and new releases. 

If you have any questions, bug reports, or need any help or support, please contact us by email at info@qredo.com.

The Qredo Development Team, March 2016

**All contents of this release ©Qredo Ltd, 2015, 2016
**
