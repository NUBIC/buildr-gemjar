require 'pathname'
require 'fileutils'

module BuildrGemjar
  module Spec
    ##
    # Based on the helpers in bundler's spec suite, though substantially simpler.
    module RepoBuilder
      include FileUtils

      def create_repo
        create_gem "a"
        create_gem "b", "1.1"
        create_gem "b", "1.2"
        create_gem "c", "2.3.2" do |s|
          s.add_dependency 'a'
        end

        create_gem "jr", "1.0" do |s|
          s.platform = 'ruby'
          s.add_dependency "c"
        end
        create_gem "jr", "1.0" do |s|
          s.platform = 'java'
          s.add_dependency "b"
          s.files = [
            create_jar('lib/jr.jar', %w(org/example/jr/lib.properties), 'org.example.jar.Main'),
            create_jar('ext/jr.jar', %w(org/example/jr/ext.properties))
          ]
        end

        create_gem 'jr-user' do |s|
          s.add_dependency 'jr'
        end

        `gem generate_index -q --directory '#{repo_path}'`
      end

      def create_gem(name, version='1.0', opts={})
        target = opts[:path] || repo_path.join("gems")
        mkdir_p target
        cd target do
          spec = Gem::Specification.new do |s|
            s.name    = name
            s.version = version
            s.summary = "A fake #{name}"
            s.authors = ['A. Tester']
          end
          yield spec if block_given?

          Gem.configuration.verbose = false
          Gem::Builder.new(spec).build
          Gem.configuration.verbose = true

          spec.files.each do |f|
            rm_rf f
          end
        end
      end

      # main_class is an option because it's a cheap way to get
      # something specific to this jar into the manifest
      def create_jar(path, filenames, main_class=nil)
        mkdir File.dirname(path)

        staging = tmp('jar-staging')
        staging.mkpath
        filenames.each do |fn|
          pn = staging + fn
          pn.dirname.mkpath
          pn.open('w') { }
        end

        cmd = [
          'jar',
          main_class ? 'cfe' : 'cf',
          "'#{path}'",
          main_class,
          "-C",
          "'#{staging}'",
          '.'
        ].compact.join(' ')

        out = %x[#{cmd} 2>&1]
        fail "create_jar failed:\n#{out}" unless $? == 0

        staging.rmtree
        path
      end

      def tmp(*path)
        Pathname.new(File.expand_path("../../tmp", __FILE__)).join(*path)
      end

      def repo_path
        tmp("repo")
      end

      def rm_repo
        rm_r repo_path
      end
    end
  end
end
