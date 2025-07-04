Pod::Spec.new do |spec|

  spec.name         = "ForageSDK"
  spec.version      = "4.5.0"
  spec.summary      = "ForageSDK"
  spec.description  = "The ForageSDK process Electronic Benefit Transfer (EBT) payments in your e-commerce application."
  spec.homepage     = "https://github.com/teamforage/forage-ios-sdk"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Rob Gormisky" => "rob@joinforage.com" }
  spec.platform     = :ios, "13.0"
  spec.readme       = "https://raw.githubusercontent.com/teamforage/forage-ios-sdk/main/README.md"
  spec.source       = { :git => "https://github.com/teamforage/forage-ios-sdk.git", :tag => "4.5.0" }
  spec.source_files = ["Sources/ForageSDK/**/*.swift", "DatadogPrivate-Objc/**/*.{h,m}"]
  spec.resource_bundles = {
    'ForageIcon' => ['Sources/Resources/*']
  }
  
  spec.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0' }
  spec.swift_versions = '5.0'

end
