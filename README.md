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

Caveats
-------

It's important that the name of your JAR not be the same as anything
you will `require` from it.  E.g., in the sample above, if the JAR
were named `sinatra.jar`, it would not be possible to `require
"sinatra"` from it.
