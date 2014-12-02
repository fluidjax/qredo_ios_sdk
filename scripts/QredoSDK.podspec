Pod::Spec.new do |s|
  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.name         = "QredoSDK"
  s.version      = "0.1"
  s.summary      = "Qredo SDK library"

  s.description  = <<-DESC
  					Vault, Rendezvous, Conversations
                   DESC

  s.homepage     = "http://qredo.com/"

  s.license      = "Commercial"
  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.author             = "Qredo"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.platform     = :ios
  s.platform     = :ios, "8.0"

  s.ios.deployment_target = "8.0"


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source_files  = "include/**/*.{h}"

  s.public_header_files = "include/*.h"
  s.vendored_library = "libqredosdk.a"

  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.requires_arc = true
end
