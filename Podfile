xcodeproj 'QredoSDK.xcodeproj/'

platform :ios, '9.0'

target 'QredoSDK' do

    pod 'PINCache'
    pod 'SocketRocket'
    pod 'OpenSSL-for-iOS', '1.0.2.d.1'
    pod 'libsodium', :path => 'libsodium.podspec'

end

target 'QredoSDKTests' do

    pod 'PINCache'
    pod 'libsodium', :path => 'libsodium.podspec'

end

target 'ConversationCreateTests' do

    pod 'PINCache'
    pod 'SocketRocket'
    pod 'libsodium', :path => 'libsodium.podspec'

end

target 'ConversationRespondTests' do

    pod 'PINCache'
    pod 'SocketRocket'
    pod 'libsodium', :path => 'libsodium.podspec'

end

target 'Qredo' do

    pod 'libsodium', :path => 'libsodium.podspec'
    pod 'OpenSSL-for-iOS', '1.0.2.d.1'
    pod 'PINCache'
    pod 'SocketRocket'

end

post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        end
    end
end