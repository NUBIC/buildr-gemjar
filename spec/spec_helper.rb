require 'rspec'
require File.expand_path("../../vendor/buildr/spec/spec_helpers.rb", __FILE__)
require 'zip/zip'
require 'rubygems/user_interaction'

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'buildr-gemjar'

require File.expand_path("../repo_builder.rb", __FILE__)

::RSpec.configure do |config|
  config.include BuildrGemjar::Spec::RepoBuilder

  config.before(:all) do
    @original_gem_ui = Gem::DefaultUserInteraction.ui
    Gem::DefaultUserInteraction.ui = Gem::SilentUI.new

    Buildr.repositories.remote << "http://repo1.maven.org/maven2"
  end

  config.after(:all) do
    Gem::DefaultUserInteraction.ui = @original_gem_ui
  end
end

::RSpec::Matchers.define :be_a_jar_containing do |*contents|
  match do |filename|
    @missing = []
    Zip::ZipFile.open(filename) do |zip|
      contents.each do |expected|
        unless zip.find_entry(expected)
          @missing << expected
        end
      end
    end
    @missing.empty?
  end

  failure_message_for_should do |filename|
    "should result in a jar containing #{@missing.inspect}; #{filename} doesn't."
  end
end
