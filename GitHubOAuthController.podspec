
Pod::Spec.new do |s|

  s.name         = "GitHubOAuthController"
  s.version      = "0.3.1"
  s.summary      = "Simple GitHub OAuth Controller"

  s.homepage     = "https://github.com/friedbunny/GitHubOAuthController"

  s.license      = { :type => "MIT", :file => "LICENSE" }
 
  s.author             = { "dkhamsing" => "dkhamsing8@gmail.com" }
  s.social_media_url   = "http://twitter.com/dkhamsing" 

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/friedbunny/GitHubOAuthController.git", :tag => "0.3.1" }
 
  s.source_files  = "GitHubOAuthController/*"
   
  s.requires_arc = true

  s.default_subspec = '1Password'

  s.subspec '1Password' do |onepassword|
  onepassword.xcconfig = { 'OTHER_CFLAGS' => '-DGITHUB_OAUTH_ENABLE_1PASSWORD' }
  onepassword.dependency '1PasswordExtension', '~> 1.8'
  end

end
