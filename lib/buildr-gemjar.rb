require 'buildr/java/packaging'

module BuildrGemjar
  class GemjarTask < Buildr::Packaging::Java::JarTask
    def initialize(*args)
      super
      @target = File.expand_path("../gem_home", self.to_s)
      # It doesn't seem like this should be necessary or useful --
      # the directory is also created by a task dependency.
      # However, if it isn't here, the file gem dependency is not
      # correctly taken into account.  (Try commenting it out and
      # running the specs.)
      mkdir_p @target

      clean
      include(@target, :as => '.')
      enhance do
        install_gems
      end
    end

    def with_gem(*args)
      new_gem =
        if args.first.respond_to?(:has_key?)
          FileSourcedGem.new(args.first[:file])
        else
          NamedGem.new(args[0], args[1])
        end
      gems << new_gem
      enhance new_gem.dependencies
      self
    end

    def clear_sources
      sources.clear
      self
    end

    def add_source(source)
      sources << source
      self
    end

    def gems
      @gems ||= []
    end

    def sources
      @sources ||= ['http://rubygems.org']
    end

    def gem_home
      @target
    end

    private

    def install_gems
      fail "No gems specified.  Did you call #with_gem?" if gems.empty?
      gems.each do |gem|
        cmd = [
          "GEM_PATH=''",
          "GEM_HOME='#{@target}'",
          "java",
          "-jar",
          BuildrGemjar.jruby_complete_jar,
          "-S",
          "gem",
          "install",
          # The behavior of --source changed between rubygems 1.3.6
          # and 1.5.0.  Previously, specifying source(s) overrode the
          # default source(s).  After, specifying source(s) adds onto
          # the default list.  To get the old behavior, you have to
          # include "--clear-sources".  This code wants the old
          # behavior, but no version of jruby-complete contains a
          # version of rubygems > 1.3.6, so it's not an issue today.
          # Later we'll probably have to do version sniffing or
          # something.
          # "--clear-sources",
          sources.collect { |s| ["--source", "'#{s}'"] },
          "--no-ri",
          "--no-rdoc",
          gem.install_command_elements
        ].flatten.join(" ")

        trace cmd
        out = %x[#{cmd} 2>&1]
        trace out
        if out =~ /ERROR/
          fail out.split("\n").grep(/ERROR/).join("\n")
        end
      end
    end

    class FileSourcedGem
      attr_accessor :filename

      def initialize(filename)
        @filename = filename
      end

      def kind; :file; end

      def install_command_elements
        [filename]
      end

      def dependencies
        [(filename if File.exist?(filename))].compact
      end
    end

    class NamedGem
      attr_accessor :name, :version

      def initialize(name, version)
        @name = name
        @version = version
      end

      def kind; :named; end

      def install_command_elements
        [name].tap do |elts|
          elts << "-v '#{version}'" if version
        end
      end

      def dependencies
        []
      end
    end
  end

  include Buildr::Extension

  def package_as_gemjar(filename)
    GemjarTask.define_task(filename)
  end

  def package_as_gemjar_spec(spec)
    spec.merge(:type => 'jar')
  end

  def self.jruby_version
    version = Buildr.settings.build['jruby'] ||
      (JRUBY_VERSION if Kernel.const_defined?(:JRUBY_VERSION)) ||
      "1.5.6"
  end

  def self.jruby_artifact
    "org.jruby:jruby-complete:jar:#{jruby_version}"
  end

  class << self
    attr_accessor :jruby_complete_jar
  end

  after_define do |project|
    jruby = project.artifact(BuildrGemjar.jruby_artifact)
    project.packages.each do |pkg|
      if pkg.is_a?(GemjarTask)
        directory pkg.gem_home
        pkg.enhance [pkg.gem_home, jruby]
        BuildrGemjar.jruby_complete_jar = jruby.to_s
      end
    end
  end
end

class Buildr::Project
  include BuildrGemjar
end
