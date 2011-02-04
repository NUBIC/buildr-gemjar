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
        end

        `gem generate_index -q --directory '#{repo_path}'`
      end

      def create_gem(name, version='1.0', opts={})
        spec = Gem::Specification.new do |s|
          s.name    = name
          s.version = version
          s.summary = "A fake #{name}"
        end
        yield spec if block_given?

        target = opts[:path] || repo_path.join("gems")
        mkdir_p target
        cd target do
          Gem::Builder.new(spec).build
        end
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
