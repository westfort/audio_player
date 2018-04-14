#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'audioplayer'
  s.version          = '0.0.1'
  s.summary          = 'An audio player for the Flutter framework'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'http://www.westfort.co'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'West Fort' => 'w@westfort.co' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  
  s.ios.deployment_target = '8.0'
end

