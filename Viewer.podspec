Pod::Spec.new do |s|
  s.name             = "Viewer"
  s.summary          = "Image viewer (or Lightbox) with support for local and remote videos and images"
  s.version          = "2.1.0"
  s.homepage         = "https://github.com/bakkenbaeck/Viewer"
  s.license          = 'MIT'
  s.author           = { "Bakken & Bæck AS" => "post@bakkenbaeck.com" }
  s.source           = { :git => "https://github.com/bakkenbaeck/Viewer.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/bakkenbaeck'
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  s.requires_arc = true
  s.source_files = 'Source'
  s.frameworks = 'UIKit'
end
