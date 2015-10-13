xcodeproj 'QredoSDK_pods.xcodeproj/'

source 'git@github.com:Qredo/qredo_cocoapods.git'
source 'https://github.com/CocoaPods/Specs.git'



target 'QredoSDK' do

    pod "PINCache"
    
#	pod "LinguaFranca", "~> 0.3"
#	pod "LinguaFranca", :git => "git@github.com:Qredo/LinguaFranca.git", :tag => "ios-0.3"
#	pod "LinguaFranca", :git => "git@github.com:Qredo/LinguaFranca.git", :branch => "feature/pods"


    # The QredoLibPaho dependency is only here for convenience during development. Relase builds
    # should not have it here.
    pod "QredoCommon", :path => "../qredo_ios_common/QredoCommon.podspec"
    pod "QredoCrypto", :path => "../qredo_ios_crypto/QredoCrypto.podspec"
    pod "LinguaFranca", :path => "../LinguaFranca/LinguaFranca.podspec"
#   pod "QredoLibPaho", :path => "../qredo_ios_libpaho/QredoLibPaho.podspec"
#   pod "SocketRocket", :path => "../SocketRocket/SocketRocket.podspec"

end

target 'CryptoTests' do
    pod "QredoCommon", :path => "../qredo_ios_common/QredoCommon.podspec"
    pod "QredoCrypto", :path => "../qredo_ios_crypto/QredoCrypto.podspec"
end

target 'LinguaFrancaTests' do
    pod "QredoCommon", :path => "../qredo_ios_common/QredoCommon.podspec"
    pod "QredoCrypto", :path => "../qredo_ios_crypto/QredoCrypto.podspec"
	pod "LinguaFranca", :path => "../LinguaFranca/LinguaFranca.podspec"
end

#target 'QredoSDKTests' do
#end

post_install do |installer_representation|
    
    puts "Processing post install steps"
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|

           # Enable treating warnings as errors (for all configurations)
            puts target.name + ": Treating warnings as errors"
            config.build_settings['GCC_TREAT_WARNINGS_AS_ERRORS'] = 'YES'

            if config.name == 'Debug'
                puts target.name + ": Enabling Qredo logging"
                definitions = '$(inherited)'
                definitions += ' QREDO_LOG_ERROR'
                definitions += ' QREDO_LOG_DEBUG'
                definitions += ' QREDO_LOG_INFO'
                definitions += ' QREDO_LOG_TRACE'
                config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = definitions
            end
       end

   end
    puts "Completed post install"
    
end

