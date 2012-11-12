I18n Init for Rails
=======================

**i18n-init version `1.0`** (`Flow`)

* https://rubygems.org/gems/i18n-init
* https://github.com/siefca/i18n-init/tree
* pw@gnu.org


Summary
-------

It's for relax and aesthetics.

I18n Init allows you to quickly initialize locale settings in popular frameworks
or your own program. No huge `locale.rb` initializer, no constants in the code,
just create translations and use them.

Why?
----

To clean up and automate things like:

* 
* setting fallback rules,
* loading translations files,
* setting the default locale and the language name,
* creating list of available languages and their locale codes,


Usage
-----


* See [whole documentation](http://rubydoc.info/gems/i18n-init/) to browse all documents.

Requirements
------------

* [activemodel](https://rubygems.org/gems/activemodel)
* [rake](https://rubygems.org/gems/rake)
* [rubygems](http://docs.rubygems.org/)
* [bundler](http://gembundler.com/)

Download
--------

### Source code ###

* https://github.com/siefca/i18n-init/tree
* `git clone git://github.com/siefca/i18n-init.git`

### Gem ###

* https://rubygems.org/gems/i18n-init

Installation
------------

```ruby
gem install i18n-init
```

Specs
-----

You can run RSpec examples both with

* `bundle exec rake spec` or just `bundle exec rake`
* run a test file directly, e.g. `ruby -S rspec spec/i18n-init_spec.rb -Ispec:lib`

Common rake tasks
-----------------

* `bundle exec rake bundler:gemfile` – regenerate the `Gemfile`
* `bundle exec rake docs` – render the documentation (output in the subdirectory directory `doc`)
* `bundle exec rake gem:spec` – builds static gemspec file (`i18n-init.gemspec`)
* `bundle exec rake gem` – builds package (output in the subdirectory `pkg`)
* `bundle exec rake spec` – performs spec. tests
* `bundle exec rake Manifest.txt` – regenerates the `Manifest.txt` file
* `bundle exec rake ChangeLog` – regenerates the `ChangeLog` file

Credits
-------

* [iConsulting](http://www.iconsulting.pl/) supports Free Software and has contributed to this library by paying for my food during the coding.

Like my work?
-------------

You can send me some bitcoins if you would like to support me:

* `13wZbBjs6yQQuAb3zjfHubQSyer2cLAYzH`

Or you can endorse my skills on LinkedIn or Coderwall:

* [pl.linkedin.com/in/pwilk](http://www.linkedin.com/profile/view?id=4251568#profile-skills)

* [![endorse](http://api.coderwall.com/siefca/endorsecount.png)](http://coderwall.com/siefca)

License
-------

Copyright (c) 2012 by Paweł Wilk.

i18n-init is copyrighted software owned by Paweł Wilk (pw@gnu.org).
You may redistribute and/or modify this software as long as you
comply with either the terms of the LGPL (see [LGPL-LICENSE](http://rubydoc.info/gems/i18n-init/file/docs/LGPL-LICENSE)),
or Ruby's license (see [COPYING](http://rubydoc.info/gems/i18n-init/file/docs/COPYING)).

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE.
