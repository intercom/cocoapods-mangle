Pod::Spec.new do |s|
  s.name             = 'ManglePod'
  s.version          = '1.0.0'
  s.homepage         = 'https://github.com/intercom/cocoapods-mangle'
  s.summary          = 'A sample pod for integration.'
  s.license          = 'Apache'
  s.author           = { 'James Treanor' => 'james@intercom.io' }
  s.source           = { git: 'git@github.com:intercom/cocoapods-mangle.git' }
  s.platform         = :ios, '8.0'
  s.requires_arc     = true
  s.source_files     = 'Source/**/*.{h,m}'
end
