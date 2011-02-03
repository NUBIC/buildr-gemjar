require File.expand_path("../spec_helper.rb", __FILE__)

describe ":gemjar packaging" do
  describe "#with_gem" do
    def actual_gems
      projects.first.packages.first.gems
    end

    it "accepts a gem name" do
      define('foo', :version => '1.0') {
        package(:gemjar).with_gem('shenandoah', '~> 0.1.0')
      }

      actual_gems.first.kind.should == :named
      actual_gems.first.name.should == 'shenandoah'
      actual_gems.first.version.should == '~> 0.1.0'
    end

    it "defaults the version to nil" do
      define('foo', :version => '1.0') {
        package(:gemjar).with_gem('shenandoah')
      }

      actual_gems.first.kind.should == :named
      actual_gems.first.name.should == 'shenandoah'
      actual_gems.first.version.should be_nil
    end

    it "accepts a filename" do
      define('foo', :version => '1.0') {
        package(:gemjar).with_gem(:file => 'foo/bcdatabase-1.0.3.pre.gem')
      }

      actual_gems.first.kind.should == :file
      actual_gems.first.filename.should == 'foo/bcdatabase-1.0.3.pre.gem'
    end

    it "can be invoked multiple times" do
      define('foo', :version => '1.0') {
        package(:gemjar).
          with_gem('ladle', '~> 0.2.0').
          with_gem(:file => 'target/just-built.gem').
          with_gem('schema_qualified_tables', '~> 1.0.0')
      }

      actual_gems.collect { |g| g.kind }.should == [:named, :file, :named]
    end
  end

  describe "sources" do
    def actual_sources
      projects.first.packages.first.sources
    end

    it "defaults to rubygems.org" do
      define('foo', :version => '1.0') {
        package(:gemjar)
      }

      actual_sources.should == %w(http://rubygems.org)
    end

    it "appends new sources while preserving the default" do
      define('foo', :version => '1.0') {
        package(:gemjar).
          add_source('http://archive.local/gems').
          with_gem('private-stuff')
      }

      actual_sources.should == %w(http://rubygems.org http://archive.local/gems)
    end

    it "can clear the default source" do
      define('foo', :version => '1.0') {
        package(:gemjar).clear_sources.add_source('http://archive.local/gems')
      }

      actual_sources.should == %w(http://archive.local/gems)
    end
  end
end

