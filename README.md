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
no constants in your code, no arrays of languages and locale names. The whole
configuration is in `locale.yml` settings file.

What?
-----

I18n Init is able to set up and provide the following information:

* languages supported by application
* languages with reversed writing order (right-to-left)
* default locale
* locale fallbacks
* default locale fallbacks
* pathname of default directory containing translation files

Conventions
-----------

To work properly I18n Init needs a configuration file (`locale.yml`). It will look for it
in a standard location of your framework and in other known locations. If the file cannot
be found then the bundled settings will be loaded (containing huge defaults).

I18n Init is designed to nicely initialize things, not to change them at runtime.
That's why there are two phases of work:

1. **configuration**
  * Gathers the I18n configuration from your framework settings.
  * Gathers the I18n configuration from `locale.yml` (or bundled settings if file is missing).
  * Gathers the I18n configuration from the configuration block.

2. **initialization** (invoked by `I18n.init!`)
  * Loads settings from configuration sources.
  * Sets up backends, available locales, default locale, locale names and fallbacks (if in use).
  * Loads translations using the default translations directory of your framework
    or the given directory.

### Available locales ###

Available locales are the locales that your application supports. I18n Init allows you to add or remove them
and assign the language names to them. You can use these names to present a list of languages that user can
choose from.




The available locales are also internally used when generating fallbacks. These are automatically created only for
available locales. However, all the translations are loaded and can be used, regardless of available locales.
You can configure fallbacks on your own for locales that aren't officially available but somehow
are in use and need fallbacks. I18n Init won't destroy fallbacks that you've set manually, it just add new or redefine
existing.

Installation
------------

### Rails ###

0. Add `i18n-init` to the `Gemfile` and execute: `bundle install`.
1. Go to your application root directory and execure: `rails g i18n_init:install`
2. View and customize the contents of:
  * `config/locale.yml`
  * `config/initializers/locale.rb` (not needed in most cases)

### Other frameworks and programs ###

0. Install I18n Init:
  * manually: `gem install i18n-init`
  * or add it to the `Gemfile` and execute: `bundle install`.
1. Create the locale settings file called `locale.yml` and place it in the configuration directory of your application.
  * to copy the example file: `ruby -r i18n-init -e I18n.init.print_example_settings > locale.yml`
2. Create initializer in your application:
  * create a configuration block in the initializer (optional)
  * put **`I18n.init!`** after a block (mandatory).

Usage
-----

### Configuration file ###

The `locale.yml` configuration file contains basic I18n settings. Its contents may look like this:

```yaml
default: "en"

available:
  - de
  - en
  - pl

fallbacks:
  en-shaw:
    - :en
    - :en-GB
    - :en-US

default_fallbacks:
  - :en

names:
  de: "Deutsch"
  en: "English"
  pl: "polski"

rtl:
  - :ar
  - :ms
```

To view the example settings file, execute:
`ruby -r i18n-init -e I18n.init.print_example_settings`

It has the following sections:

* <b>`default`</b>           – default locale code (initializes `I18n.default_locale`)
* <b>`initial`</b>           – initial locale code (initializes `I18n.locale`)
* <b>`backends`</b>          – backends to enable (impacts `I18n.backend`)
* <b>`available`</b>         – locales that your application can handle (initializes `I18n.available_locales`)
* <b>`fallbacks`</b>         – fallbacks that are used (initializes `I18n.fallbacks`)
* <b>`default_fallbacks`</b> – (initializes `I18n.fallbacks.defaults`)
* <b>`rtl`</b>               – right-to-left languages (initializes `I18n.rtl_locales`)
* <b>`names`</b>             – language names assigned to locales

Available locales section (`available`) can also contain associations. If it's done that way, the given
language names will override certain mappings from `names` section. Of course, the primary function of `available`
section won't change – the given locales will be added to available locales list. Example:

```yaml
default: "en"

available:
  pl: 'polski'  # name overridden
  de: ''        # name taken from 'names' or from bundled config
  en:           # name taken from 'names' or from bundled config
```

How can it be helpful? When you don't want to maintain `names` but have to assign language names to locales on your own. 
Then just remove the `names` section from your `locale.yml` file and assign new names in `available` section. Don't
worry, any missing language name will be resolved using bundled configuration.

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
