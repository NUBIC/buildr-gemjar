puts "Loaded #{__FILE__}"

require 'buildr/java/packaging'

module BuildrGemjar
  class GemjarTask < Buildr::Packaging::Java::JarTask
    def with_gem(*args)
      if args.first.respond_to?(:has_key?)
        gems << FileSourcedGem.new(args.first[:file])
      else
        gems << NamedGem.new(args[0], args[1])
      end
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

    private

    class FileSourcedGem
      attr_accessor :filename

      def initialize(filename)
        @filename = filename
      end

      def kind; :file; end
    end

    class NamedGem
      attr_accessor :name, :version

      def initialize(name, version)
        @name = name
        @version = version
      end

      def kind; :named; end
    end
  end

  include Extension

  def package_as_gemjar(filename)
    GemjarTask.define_task(filename)
  end
end

class Buildr::Project
  include BuildrGemjar
end
