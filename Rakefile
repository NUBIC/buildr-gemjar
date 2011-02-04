require 'bundler'
require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec'

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/**/*_spec.rb"
end

namespace :ci do
  ENV["CI_REPORTS"] = "reports/spec-xml"

  desc "Run specs for CI"
  task :spec => ['ci:setup:rspec', 'rake:spec']
end
