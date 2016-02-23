Pod::Spec.new do |s|
  s.name = 'QredoXDK'
  s.version = '0.2'
  s.platform = :ios
  s.ios.deployment_target = '8.0'
 # s.source_files = 'QredoXDK.framework'
  s.ios.vendored_frameworks = 'QredoXDK.framework'
  s.requires_arc = true
end
