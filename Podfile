xcodeproj 'QredoSDK_pods.xcodeproj/'

source 'https://github.com/CocoaPods/Specs.git'
source 'git@github.com:Qredo/qredo_cocoapods.git'

target 'QredoSDK' do
#	pod "LinguaFranca", "~> 0.3"
#	pod "LinguaFranca", :git => "git@github.com:Qredo/LinguaFranca.git", :tag => "ios-0.3"
#	pod "LinguaFranca", :git => "git@github.com:Qredo/LinguaFranca.git", :branch => "feature/pods"
	pod "LinguaFranca", :path => "../LinguaFranca/LinguaFranca.podspec"
end

target 'CryptoTests' do
	pod "LinguaFranca/Crypto", :path => "../LinguaFranca/LinguaFranca.podspec"
end

target 'LinguaFrancaTests' do
	pod "LinguaFranca", :path => "../LinguaFranca/LinguaFranca.podspec"
end

target 'QredoSDKTests' do
end

post_install do |installer_representation|
    installer_representation.project.targets.each do |target|
        target.build_configurations.each do |config|
            # Enable logging on Debug, and code coverage measurements
            if config.name == 'Debug'
                definitions = '$(inherited)'
                definitions += ' QREDO_LOG_ERROR'
                definitions += ' QREDO_LOG_DEBUG'
                definitions += ' QREDO_LOG_INFO'
                definitions += ' QREDO_LOG_TRACE'
                config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = definitions
                config.build_settings['GCC_GENERATE_TEST_COVERAGE_FILES'] = 'YES'
                config.build_settings['GCC_INSTRUMENT_PROGRAM_FLOW_ARCS'] = 'YES'
            end
        end
    end
end
