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

    describe ':unpack_jars' do
      shared_examples_for 'a gem with unpack behavior' do
        let(:gem) {
          a = args
          define('foo', :version => '1.0') {
            package(:gemjar).with_gem(*a)
          }
          actual_gems.first
        }

        it 'defaults to true' do
          gem.unpack_globs.should == ['lib/**/*.jar']
        end

        it 'interprets true as "lib/**/*.jar"' do
          args.last[:unpack_jars] = true
          gem.unpack_globs.should == ['lib/**/*.jar']
        end

        it 'interprets false as no globs' do
          args.last[:unpack_jars] = false
          gem.unpack_globs.should == []
        end

        it 'passes through an array' do
          expected = %w(lib/shared/*.jar ext/**/*.jar)
          args.last[:unpack_jars] = expected

          gem.unpack_globs.should == expected
        end

        it 'wraps a single value into an array' do
          expected = 'ext/**/*.jar'
          args.last[:unpack_jars] = expected

          gem.unpack_globs.should == [expected]
        end
      end

      describe 'with a named gem' do
        let(:args) { ['jruby-openssl', '0.7.5', {}] }

        it_behaves_like 'a gem with unpack behavior'
      end

      describe 'with a file-sourced gem' do
        let(:args) { [{ :file => 'snapshot.gem' }] }

        it_behaves_like 'a gem with unpack behavior'
      end
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

  describe "name" do
    it "uses 'jar' as the extension" do
      define('foo', :version => '1.0') { package(:gemjar) }
      project('foo').package(:gemjar).to_s.should =~ /\.jar/
    end
  end

  describe "execution" do
    before(:all) do
      create_repo
    end

    after(:all) do
      rm_repo
    end

    def test_package(invoke=true)
      r = repo_path
      define('foo', :version => '2.0') { |project|
        yield package(:gemjar).clear_sources.add_source("file://#{r}")
      }
      @pkg = projects.first.packages.first
      @pkg.invoke if invoke
      @pkg.to_s
    end

    it "includes the explicitly requested gem" do
      test_package { |p| p.with_gem("c") }.
        should be_a_jar_containing("specifications/c-2.3.2.gemspec")
    end

    it "fails if the gem isn't available" do
      lambda {
        test_package { |p| p.with_gem("y") }
      }.should raise_error(/could not find.*gem.*y/i)
    end

    it "includes the specific version requested" do
      test_package { |p| p.with_gem("b", "1.1") }.
        should be_a_jar_containing("specifications/b-1.1.gemspec")
    end

    it "fails if the version requested isn't available" do
      lambda {
        test_package { |p| p.with_gem("b", "> 2") }
      }.should raise_error(/could not find.*gem.*b.*\> 2/i)
    end

    it "includes dependencies of the requested gem" do
      test_package { |p| p.with_gem("c") }.
        should be_a_jar_containing("specifications/a-1.0.gemspec")
    end

    it "includes the java variant of the gem when applicable" do
      test_package { |p| p.with_gem("jr") }.
        should be_a_jar_containing("specifications/jr-1.0-java.gemspec")
    end

    it "includes more than one explicitly prequested gem" do
      test_package { |p| p.with_gem("b").with_gem("c") }.
        should be_a_jar_containing("specifications/b-1.2.gemspec", "specifications/c-2.3.2.gemspec")
    end

    it "includes a gem from a file" do
      create_gem "f", "2.3", :path => tmp("other")
      test_package { |p| p.with_gem(:file => tmp("other", "f-2.3.gem")) }.
        should be_a_jar_containing("specifications/f-2.3.gemspec")
    end

    it "fails usefully when a specified file isn't available" do
      lambda {
        test_package { |p| p.with_gem(:file => "z-4.5.gem") }
      }.should raise_error(/could not find.*gem.*z-4.5.gem/i)
    end

    it "usually only builds the jar once" do
      create_gem "f", "2.3", :path => tmp("other")
      path = test_package(false) { |p| p.with_gem(:file => tmp("other", "f-2.3.gem")) }

      mkdir_p File.dirname(path)
      touch path
      stat = File.stat(path)

      sleep 5
      @pkg.invoke
      File.stat(path).mtime.should == stat.mtime
    end

    it "rebuilds the jar if the source file changes" do
      create_gem "f", "2.3", :path => tmp("other")
      path = test_package(false) { |p| p.with_gem(:file => tmp("other", "f-2.3.gem")) }

      mkdir_p File.dirname(path)
      touch path
      stat = File.stat(path)

      sleep 4
      touch tmp("other", "f-2.3.gem")
      @pkg.invoke
      File.stat(path).mtime.should_not == stat.mtime
    end

    it "successfully repackages after a clean" do
      path = test_package(false) { |p| p.with_gem('a') }

      project('foo').clean.invoke
      @pkg.invoke

      File.exist?(path).should be_true
    end

    def manifest_text_from(jarfile)
      require 'zip/zipfilesystem'

      Zip::ZipFile.open(jarfile) do |zfs|
        zfs.file.read('META-INF/MANIFEST.MF')
      end
    end

    it 'includes directly specified manifest properties' do
      actual = test_package { |p|
        p.with_gem('a').with :manifest => { 'Bundle-SymbolicName' => 'foo-bar' }
      }

      manifest_text_from(actual).should include("Bundle-SymbolicName: foo-bar")
    end

    describe "with gems in GEM_PATH" do
      before do
        gem_path_entry = tmp('gem_path')
        system("GEM_HOME='#{gem_path_entry}' gem install --source 'file://#{repo_path}' --no-rdoc --no-ri -q a > '#{tmp('install_out')}'")
        ENV['GEM_PATH'] = gem_path_entry.to_s
      end

      it "installs all dependencies, including ones in the GEM_PATH" do
        test_package { |p| p.with_gem("c") }.
          should be_a_jar_containing("specifications/a-1.0.gemspec")
      end
    end

    describe 'with jars to unpack' do
      shared_examples_for 'a gem including jars' do
        let(:pkg) { test_package { |p| p.with_gem(*args).with :manifest => { 'Foo' => 'Bar' } } }

        it 'unpacks jars under lib by default' do
          pkg.should be_a_jar_containing('org/example/jr/lib.properties')
        end

        it 'does not unpack other jars by default' do
          pkg.should_not be_a_jar_containing('org/example/jr/ext.properties')
        end

        describe 'with a glob' do
          before do
            args.last[:unpack_jars] = 'ext/**/*.jar'
          end

          it 'unpacks the requested jars' do
            pkg.should be_a_jar_containing('org/example/jr/ext.properties')
          end

          it 'does not unpack other jars' do
            pkg.should_not be_a_jar_containing('org/example/jr/lib.properties')
          end
        end

        it 'unpacks everything for each glob' do
          args.last[:unpack_jars] = ['ext/**/*.jar', 'lib/*.jar']
          pkg.should be_a_jar_containing(
            'org/example/jr/ext.properties', 'org/example/jr/lib.properties')
        end

        it 'unpacks nothing when :unpack_jars is false' do
          args.last[:unpack_jars] = false
          pkg.should_not be_a_jar_containing('org')
        end

        it 'does not include the manifest from unpacked jars' do
          manifest_text_from(pkg).should_not include('Main-Class')
        end
      end

      describe 'a named gem' do
        let(:args) { ['jr', '1.0', {}] }

        it_behaves_like 'a gem including jars'
      end

      describe 'a file-sourced gem' do
        let(:args) { [{ :file => (repo_path + 'gems' + 'jr-1.0-java.gem').to_s}] }

        it_behaves_like 'a gem including jars'
      end

      describe 'with jars in dependencies' do
        let(:pkg) { test_package { |p| p.with_gem('jr-user') } }

        it 'unpacks jars under lib' do
          pkg.should be_a_jar_containing('org/example/jr/lib.properties')
        end

        it 'does not unpack other jars' do
          pkg.should_not be_a_jar_containing('org/example/jr/ext.properties')
        end
      end
    end
  end
end

