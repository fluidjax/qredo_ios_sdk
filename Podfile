xcodeproj 'QredoSDK.xcodeproj/'

source 'git@github.com:Qredo/qredo_cocoapods.git'
source 'https://github.com/CocoaPods/Specs.git'

target 'QredoSDK' do

    pod 'PINCache'
    pod 'SocketRocket', '~> 0.2.0-qredo'
    pod 'OpenSSL', '~> 1.0'

end

target 'QredoSDKTests' do

    pod 'PINCache'

end

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
