require 'buildr/java/packaging'
require 'pathname'

module BuildrGemjar
  class GemjarTask < Buildr::Packaging::Java::JarTask
    DEFAULT_UNPACK_GLOBS = ['lib/**/*.jar']

    def initialize(*args)
      super
      @target = Pathname.new File.expand_path("../gem_home", self.to_s)
      # It doesn't seem like this should be necessary or useful --
      # the directory is also created by a task dependency.
      # However, if it isn't here, the file gem dependency is not
      # correctly taken into account.  (Try commenting it out and
      # running the specs.)
      @target.mkpath

      clean
      include(@target.to_s, :as => '.')
      enhance do
        install_gems
        unpack_jars
      end
    end

    def with_gem(*args)
      options = args.last.respond_to?(:has_key?) ? args.pop : {}

      new_gem =
        if options.has_key?(:file)
          FileSourcedGem.new(options[:file])
        else
          NamedGem.new(args[0], args[1])
        end

      new_gem.unpack_globs = determine_unpack_globs(options[:unpack_jars])

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
          "--clear-sources",
          sources.collect { |s| ["--source", "'#{s}'"] },
          "--no-ri",
          "--no-rdoc",
          gem.install_command_elements
        ].flatten.join(" ")

        trace cmd
        out = %x[#{cmd} 2>&1]
        trace out
        if $? != 0
          fail "gem invocation failed:\n#{out}"
        elsif out =~ /ERROR/
          fail out.split("\n").grep(/ERROR/).join("\n")
        end
      end
    end

    def determine_unpack_globs(unpack_jars_option)
      unpack_jars_option = true if unpack_jars_option.nil?

      case unpack_jars_option
      when true
        DEFAULT_UNPACK_GLOBS
      when false
        []
      else
        [*unpack_jars_option]
      end
    end

    def unpack_jars
      all_gem_roots = (gem_home + 'gems').children
      requested_gem_roots = gems.collect { |gem| gem.install_root(gem_home) }.compact
      other_gem_roots = all_gem_roots - requested_gem_roots

      FileUtils.cd gem_home do
        other_gem_roots.each do |root|
          unpack_gem_jars(root, DEFAULT_UNPACK_GLOBS)
        end
        gems.each do |gem|
          unpack_gem_jars(gem.install_root(gem_home), gem.unpack_globs)
        end
      end
    end

    def unpack_gem_jars(installed_root, jar_globs)
      jar_globs.each do |glob|
        Dir[installed_root + glob].each do |jar|
          trace "Unpacking #{jar}"
          cmd = [
            'jar',
            'xf',
            jar
          ].join(' ')
          trace cmd
          out = %x[#{cmd} 2>&1]
          if $? != 0
            fail "jar extraction failed:\n#{out}"
          else
            trace out
          end
          FileUtils.rm_rf 'META-INF'
        end
      end
    end

    module GemProperties
      attr_accessor :unpack_globs

      ##
      # If the gem is installed in the given gem home, this method
      # gives the path to its expanded root under `{gem_home}/gems`.
      def install_root(gem_home)
        (gem_home + 'gems').children.detect { |p| p.to_s =~ /#{name}-#{version}/ }
      end
    end

    class FileSourcedGem
      include GemProperties

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

      def name
        spec.name
      end

      def version
        spec.version
      end

      def spec
        require 'rubygems/specification'

        @spec ||= YAML.load(`tar xOf '#{filename}' metadata.gz | gunzip`)
      end
      private :spec
    end

    class NamedGem
      include GemProperties

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
      "1.7.0"
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
        directory pkg.gem_home.to_s
        pkg.enhance [pkg.gem_home.to_s, jruby]
        BuildrGemjar.jruby_complete_jar = jruby.to_s
      end
    end
  end
end

class Buildr::Project
  include BuildrGemjar
end
