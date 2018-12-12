Pod::Spec.new do |s|
  s.name         = "SheetPresentation"
  s.version      = "1.0.0"
  s.summary      = "A Modal Presentation Controller that adapts to content size, traits changing and keyboard visibility"
  s.homepage     = "https://github.com/mrdepth/SheetPresentation"
  s.license      = "MIT"
  s.author       = { "Shimanski Artem" => "shimanski.artem@gmail.com" }
  s.source       = { :git => "https://github.com/mrdepth/SheetPresentation.git", :branch => "master" }
  s.source_files = "Source/*.swift"
  s.platform     = :ios
  s.ios.deployment_target = "9.0"
  s.swift_version = "4.2"
end
