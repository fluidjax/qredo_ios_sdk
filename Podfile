xcodeproj 'QredoSDK.xcodeproj/'

platform :ios, '9.1'

inhibit_all_warnings!

target 'QredoSDKTests' do
    
    pod 'libsodium', :path => 'libsodium.podspec'

end

target 'LinguaFrancaTests' do
    
    pod 'SocketRocket'

end

target 'QredoCryptoTests' do

    pod 'OpenSSL', '~> 1.0'

end

target 'QredoXDK' do
    pod 'PINCache'
    pod 'SocketRocket'
    pod 'OpenSSL', '~> 1.0'
    pod 'libsodium', :path => 'libsodium.podspec'
    
end

post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        end
    end
end
