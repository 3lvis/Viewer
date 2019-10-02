Pod::Spec.new do |s|
  s.name             = "Viewer"
  s.summary          = "Image viewer (or Lightbox) with support for local and remote videos and images"
  s.version          = "4.1.0"
  s.homepage         = "https://github.com/3lvis/Viewer"
  s.license          = 'MIT'
  s.author           = { "Elvis Nuñez" => "elvisnunez@me.com" }
  s.source           = { :git => "https://github.com/3lvis/Viewer.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/3lvis'
  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'
  s.requires_arc = true
  s.source_files = 'Source'
  s.resources = "Source/*.xcassets"
  s.frameworks = 'UIKit'
end
