Pod::Spec.new do |spec|

  spec.name         = "ForageSDK"
  spec.version      = "0.1.0"
  spec.summary      = "ForageSDK"
  spec.description  = "The ForageSDK process Electronic Benefits Transfer (EBT) payments in your e-commerce application."
  spec.homepage     = "https://github.com/teamforage/forage-ios-sdk"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Tiago Oliveira" => "tiago.oliveira@symphony.is" }
  spec.platform     = :ios, "11.0"
  spec.source       = { :git => "https://github.com/teamforage/forage-ios-sdk.git", :tag => "0.1.0" }
  spec.source_files = "Sources/ForageSDK/**/*.swift"
  spec.dependency 'VGSCollectSDK', '~> 1.11.2'
  
  spec.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0' }
  spec.swift_versions = '5.0'

end
