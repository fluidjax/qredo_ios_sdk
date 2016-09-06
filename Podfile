xcodeproj 'QredoSDK.xcodeproj/'

platform :ios, '8.0'

inhibit_all_warnings!


target 'TestHost' do
    pod 'jetfire'
    pod 'OpenSSL', '~> 1.0'
    pod 'libsodium', :inhibit_warnings => true
end

target 'QredoSDKTests' do
  pod 'libsodium', :inhibit_warnings => true

end

target 'LinguaFrancaTests' do
   pod 'libsodium', :inhibit_warnings => true
   pod 'jetfire'

end

target 'QredoCryptoTests' do
   pod 'libsodium', :inhibit_warnings => true
    pod 'OpenSSL', '~> 1.0'


end

target 'QredoXDK' do
    pod 'jetfire'
    pod 'OpenSSL', '~> 1.0'
    pod 'libsodium', :inhibit_warnings => true
    pod 'ios-ntp'
end


target 'QredoXDK_Universal' do
    pod 'jetfire'
    pod 'OpenSSL', '~> 1.0'
    pod 'libsodium', :inhibit_warnings => true
    pod 'ios-ntp'
end


post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        end
    end
end
