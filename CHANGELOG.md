1.2.0
=====

- Add support for newer JRuby, buildr and rubygems. Drop support for RubyGems
  before 1.5.0 and JRuby before 1.6.5.

1.1.0
=====

- Added: JARs which are embedded in gems which are being packaged by
  buildr-gemjar can be unpacked into the result JAR. The default
  behavior is to unpack any JARs found under `lib` in the gem, but
  this can be changed with an option on `with_gem`. See the README for
  more details. (#4)

- Fixed: When invoking `gem install` check the exit status (in
  addition to scanning the output) to detect failures. (#2)

1.0.2
=====

- Fixed: gem dependencies which were installed in the ruby from which
  buildr was running would not be packaged. (Specifically, if they
  were available on the `GEM_PATH`.) (GH-1)

1.0.1
=====

- Fixed: `buildr clean package` would fail with a "do not know how to
  build task [...]/target/gem_home" message.

1.0.0
=====

- Initial version
