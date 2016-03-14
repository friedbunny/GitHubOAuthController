
Pod::Spec.new do |s|

  s.name         = "GitHubOAuthController"
  s.version      = "0.3.0"
  s.summary      = "Simple GitHub OAuth Controller"

  s.homepage     = "https://github.com/friedbunny/GitHubOAuthController"

  s.license      = { :type => "MIT", :file => "LICENSE" }
 
  s.author             = { "dkhamsing" => "dkhamsing8@gmail.com" }
  s.social_media_url   = "http://twitter.com/dkhamsing" 

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/friedbunny/GitHubOAuthController.git", :commit => "bac12464008222e796aeed624c62b84d054f25f3" }
 
  s.source_files  = "GitHubOAuthController/*"
   
  s.requires_arc = true

  s.default_subspec = 'Plain'

  s.subspec 'Plain' do |plain|
  # Default: don't include any subspec
  end

  s.subspec '1Password' do |onepassword|
	onepassword.xcconfig = { 'OTHER_CFLAGS' => '$(inherited) -GITHUB_OAUTH_ENABLE_1PASSWORD' }
	onepassword.dependency '1PasswordExtension', '~> 1.8'
  end

end
