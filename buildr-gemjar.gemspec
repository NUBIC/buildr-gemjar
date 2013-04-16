# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "buildr-gemjar/version"

Gem::Specification.new do |s|
  s.name        = "buildr-gemjar"
  s.version     = BuildrGemjar::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Rhett Sutphin"]
  s.email       = ["rhett@detailedbalance.net"]
  s.homepage    = "http://github.com/rsutphin/buildr-gemjar"
  s.summary     = %q{Provides buildr support for packaging gems in a JAR for JRuby}

  s.rubyforge_project = "buildr-gemjar"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Have to use buildr's version for its spec helper to work
  # s.add_development_dependency 'rspec', '~> 2.4'
  s.add_development_dependency 'braid', '~> 0.6'
  s.add_development_dependency "ci_reporter", "~> 1.6"

  # Deps for the vendored buildr that's used in testing
  s.add_development_dependency 'rake',                 '0.9.2.2'
  s.add_development_dependency 'builder',              '3.1.3'
  s.add_development_dependency 'net-ssh',              '2.6.0'
  s.add_development_dependency 'net-sftp',             '2.0.5'
  s.add_development_dependency 'rubyzip',              '0.9.9'
  s.add_development_dependency 'highline',             '1.6.2'
  s.add_development_dependency 'json_pure',            '1.7.5'
  s.add_development_dependency 'rubyforge',            '2.0.4'
  s.add_development_dependency 'hoe',                  '3.1.0'
  s.add_development_dependency 'rjb',                  '1.4.2' unless RUBY_PLATFORM =~ /java/
  s.add_development_dependency 'atoulme-Antwrap',      '~> 0.7.4'
  s.add_development_dependency 'diff-lcs',             '1.1.3'
  s.add_development_dependency 'rspec-expectations',   '2.11.3'
  s.add_development_dependency 'rspec-mocks',          '2.11.3'
  s.add_development_dependency 'rspec-core',           '2.11.1'
  s.add_development_dependency 'rspec',                '2.11.0'
  s.add_development_dependency 'xml-simple',           '1.1.1'
  s.add_development_dependency 'minitar',              '0.5.3'
  s.add_development_dependency 'jruby-openssl',        '~> 0.8.2' if RUBY_PLATFORM =~ /java/
  s.add_development_dependency 'bundler'
end
