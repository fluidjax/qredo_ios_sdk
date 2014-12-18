Changes
=============

## alpha-05
* Add MQTT support. To enable it, set `useMQTT` flag in QredoClientOptions when `[QredoClient authorizeWithConversationTypes: vaultDataTypes: options: completionHandler:]` is called
* Implement Qredo Keychain with random keys
* Store device info when the new keychain is created
* Changed service URL to `alpha01.qredo.me`

## alpha-04
* Use QredoClientOptions with more explicit options instead of NSDictionary for authorising QredoClient.
* In BLERendezvous, rendezvous tags advertised as URI. (This ensures compatibility with the Android implementation.)

## alpha-03
* Fixed interoperability between iOS and Android datatime summary values (used QatChat)
* Added samples for creating and responding to rendezvous with QR code and BLE
* Added error handling for SDKExamples sample code
* Fixed samples to be compatible with Xcode 6.1.1
