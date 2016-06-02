Pod::Spec.new do |s|
  s.name         = "ViewPagerController"
  s.version      = "1.2.0"
  s.summary      = "Infinite menu & view paging Controller. written in Swift."
  s.homepage     = "https://github.com/xxxAIRINxxx/ViewPagerController"
  s.license      = 'MIT'
  s.author       = { "Airin" => "xl1138@gmail.com" }
  s.source       = { :git => "https://github.com/xxxAIRINxxx/ViewPagerController.git", :tag => s.version.to_s }

  s.requires_arc = true
  s.platform     = :ios, '8.0'

  s.source_files = 'Sources/*.swift'
end
