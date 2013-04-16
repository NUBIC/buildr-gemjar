buildr-gemjar
=============

`buildr-gemjar` is an extension for [buildr][] that makes it easy to
package gems and their dependencies into a jar so that [JRuby can
detect them on the classpath][gemjar].

[buildr]: http://buildr.apache.org/
[gemjar]: http://blog.nicksieger.com/articles/2009/01/10/jruby-1-1-6-gems-in-a-jar

Installing
----------

`buildr-gemjar` is distributed as a rubygem on
[rubygems.org][as-gem].  Install it as you would any other gem:

    $ gem install buildr-gemjar

[as-gem]: https://rubygems.org/gems/buildr-gemjar

Using
-----

`buildr-gemjar` provides a [package type][buildr-package] called
`:gemjar`.  Sample use:

    # buildfile
    require 'buildr-gemjar'

    define 'sinatra-gems' do
      project.version = '1.1.2'

      package(:gemjar).with_gem('sinatra', project.version)
    end

When you run `buildr package`, the result will be a JAR which contains
sinatra 1.1.2 and all its dependencies.

You can specify multiple gems:

    package(:gemjar).
      with_gem('activesupport', '2.3.10').
      with_gem('facets, '2.4.5')

You can specify additional sources on top of rubygems.org:

    package(:gemjar).
      add_source('http://myrepo.local/gems').
      with_gem('my-orm', '1.0.3')

You can also include a gem for which you have a `.gem` package:

    package(:gemjar).with_gem(:file => _('snapshot-gem-2.0.7.pre.gem'))

[buildr-package]: http://buildr.apache.org/packaging.html

### JARs embedded in gems

Many gems that are intended for use in JRuby embed one or more JARs
containing "native" java code. [jruby-openssl][] is a popular example
of this practice. If these jars are embedded as-is into the gemjar,
they won't be visible to ruby code.

To resolve this, `buildr-gemjar` will unpack any jar found under the
lib directory of any installed gem (including dependent gems) and
include its contents in the gemjar directly. You can control this
behavior for an individual gem with the `:unpack_jars` option to
`with_gems`. It can be set to one of the following values:

* an array of globs; e.g., `["lib/shared/**/*.jar"]`. Each glob will be
  applied at the root of the installed gem's contents and each match
  will be unpacked into the gemjar.
* `true`. Equivalent to `["lib/**/*.jar"]`. This is the default.
* `false`. Do not unpack any jars from this gem.

The default is `:unpack_jars => true`. Note that you can only apply
different unpack behavior for gems which are explicitly included via
`with_gem`. Any transitively installed gems will have the default
unpack behavior (i.e., unpack every JAR under lib) applied.

[jruby-openssl]: https://rubygems.org/gems/jruby-openssl

Caveats
-------

It's important that the name of your JAR not be the same as anything
you will `require` from it.  E.g., in the sample above, if the JAR
were named `sinatra.jar`, it would not be possible to `require
"sinatra"` from it.  (This is a general JRuby requirement, not
something that's specific to this tool.)

Embedded JARs will not have any of their metadata (manifests, META-INF
service registrations, etc.) preserved if they are unpacked.

Compatibility
-------------

`buildr-gemjar` is tested with buildr 1.4.11 on Ruby 1.9.3 and JRuby 1.7.2. It's
expected that it will work with any fairly recent version of buildr.

It requires RubyGems 1.5.0 or later. This means that it won't work with JRuby
before 1.6.1. Several of the early revisions of JRuby in the 1.6 line had a
severe issue installing certain gems; to be safe, use 1.6.5 or later.

It's been tested on OS X and Linux; it may or may not work on Windows.

Future work
-----------

* Remember requested gems so that rebuilds can automatically happen on
  configuration changes.  (Workaround: build clean.)
* Use [bundler][] to get a coherent list of dependencies across
  several gems.  (It would already do this, except that bundler
  doesn't support sourcing a gem from a `.gem` file, which is a more
  important feature.)
* Improve performance.  Currently a new JVM is spun up to do each gem
  install, which can be slow if there are a lot of gems.  However, the
  install process needs to change the environment for rubygems so I'm
  not sure this can be avoided.
* Support Windows.

[bundler]: http://gembundler.com/

Contact
-------

For bugs and feature requests, please use the [github issue
tracker][issues].  For other questions, please use the [buildr users
mailing list][buildrusers] or e-mail [me][] directly.

[issues]: https://github.com/NUBIC/buildr-gemjar/issues
[buildrusers]: http://buildr.apache.org/mailing_lists.html
[me]: mailto:rhett@detailedbalance.net

About
-----

Copyright 2011, Rhett Sutphin.

`buildr-gemjar` was built at [NUBIC][].

[NUBIC]: http://www.nucats.northwestern.edu/centers/nubic
