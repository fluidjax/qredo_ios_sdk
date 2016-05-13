Pod::Spec.new do |s|
  s.name = 'QredoXDK'
  s.version = '0.99'
  s.platform = :ios
  s.ios.deployment_target = '8.0'
  s.ios.vendored_frameworks = 'QredoXDK.framework'
  s.requires_arc = true
  
  s.summary      = 'Qredo SDK'
  s.author = {
     'Chris Morris' => 'cmorris@qredo.com'
   }
  s.homepage     = "http:qredo.com"
  s.license 	 = ''
  s.source       = { :git => "", :tag => "0.1.0" }
  
  
  
end
