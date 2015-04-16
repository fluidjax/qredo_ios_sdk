xcodeproj 'QredoSDK_pods.xcodeproj/', 'TestCoverage' => :debug

source 'https://github.com/CocoaPods/Specs.git'
source 'git@github.com:Qredo/qredo_cocoapods.git'

target 'QredoSDK' do
    
#	pod "LinguaFranca", "~> 0.3"
#	pod "LinguaFranca", :git => "git@github.com:Qredo/LinguaFranca.git", :tag => "ios-0.3"
#	pod "LinguaFranca", :git => "git@github.com:Qredo/LinguaFranca.git", :branch => "feature/pods"
	pod "LinguaFranca", :path => "../LinguaFranca/LinguaFranca.podspec"
    
    # The QredoLibPaho dependency is only here for convenience during development. Relase builds
    # should not have it here.
    pod "QredoLibPaho", :path => "../qredo_ios_libpaho/QredoLibPaho.podspec"
    
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
    puts "Processing post install steps"
    installer_representation.project.targets.each do |target|
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
            
            if config.name == 'TestCoverage'
                puts target.name + ": Enabling Qredo logging"
                definitions = '$(inherited)'
                definitions += ' QREDO_LOG_ERROR'
                definitions += ' QREDO_LOG_DEBUG'
                definitions += ' QREDO_LOG_INFO'
                definitions += ' QREDO_LOG_TRACE'
                puts target.name + ": Enabling code coverage"
                config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = definitions
                config.build_settings['GCC_GENERATE_TEST_COVERAGE_FILES'] = 'YES'
                config.build_settings['GCC_INSTRUMENT_PROGRAM_FLOW_ARCS'] = 'YES'
            end
        end

        puts target.name + ": Adding clean profiler files shell script phase to target "
        newPhase = target.new_shell_script_build_phase("Run Script (Remove .gcda Profiler Files)");
        newPhase.shell_script = %q{echo "Cleaning Profiler Information"
cd "${OBJECT_FILE_DIR_normal}/${CURRENT_ARCH}"
# Delete *.gcda files in the current target
rm -f *.gcda}
        
        # Move the new build phase to position 0 (must occur early on in the build)
        target.build_phases.move(newPhase, 0)
    end
    puts "Completed post install"
end

