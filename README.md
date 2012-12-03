I18n quick initialization
=========================

**i18n-init version `1.0`** (`Flow`)

* https://rubygems.org/gems/i18n-init
* https://github.com/siefca/i18n-init/tree
* pw@gnu.org


Summary
-------

It's for relax and aesthetics.

I18n Init allows you to quickly initialize locale settings in popular frameworks
(Rails, Merb, Sinatra, Padrino) or in your own program. No big initializer,
no constants in your code. Just create translations and common settings
and initialize I18n.

Why?
----

To speed up and automate things.

What?
-----

I18n Init is able to set up and provide the following information:

* languages supported by application
* languages with reversed writing order (right-to-left)
* default locale
* locale fallbacks
* pathname of default directory containing translation files

Conventions
-----------

To work properly I18n Init needs a configuration file (`locale.yml`) and an initialization method call.
It will look for a configuration file in the standard location of your framework and in other locations
if the file cannot be found there. If that will fail it will load bundled `locale.yml` containing many
languages marked as available and some default fallbacks.

I18n Init is designed to nicely initialize things, not to change them at runtime.
That's why there are two phases of work:

1. **configuration** (uses block passed to `I18n.init`)
 
2. **initialization** (invoked by `I18n.init!`)
  * loads settings from `locale.yml` or other configuration file (if exists)
  * loads settings from configuration block given before
  * discovers available locales, default locale and fallbacks 
  * loads translations using the default translations directory of your framework or the given directory
  * configures fallbacks (if fallbacks are in use)

(If you really, really want to re-initialize things after everything was loaded and configured use `I18n.init.reset!`)

### Available locales ###

Available locales are the locales that your application supports. I18n Init allows you to add or remove them
and then use in your views and controllers, for example, to present a list of languages that your site supports.

The available locales are internally used when generating fallbacks. These are automatically created only for
available locales. However, all the translations are loaded and can be used, regardless of available locales.
You can configure fallbacks on your own for locales that aren't officially available but somehow
are in use and need fallbacks. I18n Init won't destroy fallbacks that you've set manually, it just add new or redefine
existing.

Usage
-----

1. Create the **locale settings file** called `locale.yml` and place it in the configuration directory of your web application (`config` in Rails) or your program.

2. Create initializer in your web application (`config/initializers/locale.rb` in Rails)
or in your program and put **`I18n.init!`** call there.

3. Optionally **create a configuration block** in the initializer above. Place it **before** `I18n.init!`.

In case of Rails 3 or higher you can use a generator which is shipped with this gem.
Just type **`rails g i18n-init`** to get the default files (initializer and configuration file).

### Configuration file ###

The `locale.yml` configuration file contains basic I18n settings. Its contents may look like this:

```yaml
default: "en"

available:
  de: "Deutsch"
  en: "English"
  pl: "polski"

fallbacks:
  en-shaw:
    - :en
    - :en-GB
    - :en-US
rtl:
  - :ar
  - :he
  - :ur
  - :ms
```

It has the following sections:

* `available` – languages (with their names) that your application supports
* `fallbacks` – fallbacks that are used when a translation is missing in primary language
* `rtl` – right-to-left languages

The `default` entry (present at the top of the example) should contain default locale code.
When `I18n.init!` is called, it is used to initialize its `default_locale`.
It will also be automatically added to all fallbacks as the last language.

### Configuration block ###

Configuration block is a block containing important settings for those who need to customize I18n initialization process.
Some settings from configuration block will **override** corresponding settings from configuration file (e.g. default locale
and language name).

The example block looks like:

```ruby
I18n.init do
  default_locale      :en => "English"
  available_locale    :fr => "français"
  available_locales   :de => "Deutsch", :pl => "Polski"
  available_locales   :fr, :pl, :en
  backend :Fallbacks
  backend :Pluralization
end

I18n.init!
```

The code above will:

* load data from the `locale.yml` file
* set default locale code to `en`
* set default locale name to `English`
* add `fr` to available locales with the assigned language name `français`
* add `de` to available locales with the assigned language name `Deutsch`
* add `pl` to available locales with the assigned language name `Polski`
* pick available locales `fr`, `pl` and `en` from all known available locales (loaded from file and added above)
* enable fallbacks backend
* enable pluralization backend

Below are the keywords you may use to set things up.

#### Files and directories ####

* `config_file` – configuration file path, including file name (if not set then `locale.yml` is searched in known locations)
* `default_load_path` – directory used to load translation files (if not set then guessed); may contain wildcards
* `root_path` – application's root path (if not set then guessed)

#### Backends ####

* `backend` (`new_backend`) – tells I18n Init to use some backend (symbol or module)

#### Locale codes and languages ####

* `available_locale code` – adds locale `code` to available locales (name is guessed or set to a string from `code`)
* `available_locale code, name` – adds locale `code` to available locales with language `name` assigned to it
* `available_locale code => name` – adds locale `code` to available locales with language `name` assigned to it
* `default_locale code`
* `default_locale_code`) – sets code of the default locale


* `default_language` (`default_locale_name`) – name of the default language (preferably in its own language)
* `default_fallback_locale` – sets the default locale used as a last part of fallbacks 
* `locale` – locale code to be set application-wide after initializing (must be in available locales)

#### Fallbacks ####

* `fallbacks_use_default` – when set to `false` it prevents engine from adding default locale

### Querying ###


See also
--------

* See [whole documentation](http://rubydoc.info/gems/i18n-init/) to browse all documents.

Requirements
------------

* [i18n](https://rubygems.org/gems/i18n)
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

Rails integration
-----------------

If you are using Rails then in your application directory:

```ruby
rails g i18n_init:install
```

After that customize contents of:

  * `config/locale.yml`
  * `config/initializers/locale.rb` (editing not needed in most cases)

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
