############################################################
## NOTE: The empty targets are necessay
############################################################



xcodeproj 'QredoSDK.xcodeproj/'
platform :ios, '8.0'
#inhibit_all_warnings!


############################################################
### Apps and Containers for Testing
############################################################


target 'TestHost' do
 	pod 'QredoXDK', :path =>  'QredoXDK.framework.podspec'
end


############################################################
### Test Targets
############################################################


target 'QredoSDKTests' do
end

target 'LinguaFrancaTests' do
end

target 'QredoCryptoTests' do
end


############################################################
### Qredo Products
############################################################


target 'QredoXDK' do
    pod 'jetfire', :inhibit_warnings => true
    pod 'OpenSSL', '~> 1.0'
    pod 'libsodium', :inhibit_warnings => true
    pod 'ios-ntp', :inhibit_warnings => true
end


# target 'QredoXDK_Universal' do
# end


############################################################


post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
			config.build_settings['OTHER_CFLAGS'] = "$(inherited) -Qunused-arguments -Xanalyzer -analyzer-disable-all-checks"
        end
    end
end
