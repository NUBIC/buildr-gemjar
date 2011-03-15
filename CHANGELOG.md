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
