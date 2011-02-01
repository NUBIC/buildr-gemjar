# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "buildr-gemjar/version"

Gem::Specification.new do |s|
  s.name        = "buildr-gemjar"
  s.version     = Buildr::Gemjar::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Rhett Sutphin"]
  s.email       = ["rhett@detailedbalance.net"]
  s.homepage    = ""
  s.summary     = %q{Provides a buildr package type for packaging gems for JRuby}

  s.rubyforge_project = "buildr-gemjar"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
