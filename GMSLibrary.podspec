Pod::Spec.new do |s|
  s.name             = "GMSLibrary"
  s.version          = "8.5.1.003"
  s.homepage         = "https://bitbucket.org/genesysdevfoundry/gms-sample-ios"
  s.summary          = "Genesys Mobile Services (GMS) Client Library"
  s.description      = <<-DESC
                        A Swift Client SDK for Genesys Mobile Services 8.5.1 on Genesys PureEngage (Premise)."
                       DESC
  s.license          = "MIT"
  s.author           = { "Cindy Wong" => "cindy.wong@genesys.com" }
  s.source           = { :git => "https://bitbucket.org/genesysdevfoundry/gms-sample-ios.git", :tag => s.version.to_s }
  s.requires_arc = true
  s.ios.deployment_target = "10.0"
  s.source_files = 'GMSLibrary/Classes/**/*.swift'
  s.dependency 'Alamofire', '~> 4.8.0'
  s.dependency 'GFayeSwift', '~> 0.5.10'
  s.dependency 'PromisesSwift', '~> 1.2.8'
  s.swift_versions = [ "4.0", "4.2", "5.0" ]
  s.ios.framework = "UIKit"
end
