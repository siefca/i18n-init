# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
#
# This file contains I18n::Init class.

require 'pathname'
require 'singleton'

# This class handles basic settings for I18n.
class I18n::Init
  include Singleton

  DEFAULT_CONFIG_FILE         = 'locale.yml'
  DEFAULT_LOCALE_RESCUE       = 'en'
  DEFAULT_LOCALE_NAME_RESCUE  = 'English'

  attr_reader :rtl_languages
  attr_reader :available_locales
  attr_reader :available_languages
  attr_writer :default_fallback_locale

  attr_accessor :default_locale
  attr_accessor :default_locale_name

  alias_method :default_locale_code,  :default_locale
  alias_method :default_locale_code=, :default_locale=
  alias_method :default_language,     :default_locale_name
  alias_method :default_language=,    :default_locale_name=
  alias_method :load_path,            :default_load_path
  alias_method :load_path=,           :default_load_path=

  # Initializes instance and creates singleton methods that call
  # public instance methods of the same names.
  # @return [Init] self
  def initialize
    reset_buffers
    install_class_methods
  end

  # Returns framework's root path.
  # @return [String] path
  def root_path
    @root_path ||= guess_root_path
  end

  # Sets root path.
  # @return [Pathname] pathname
  def root_path=(name)
    @root_path = Pathname(name)
  end

  # Returns config file path.
  # @return [String] path
  def config_file
    @config_file ||= guess_config_file
  end

  def config_file=(name)
    @config_file = Pathname(name)
  end

  # Reads the default load path.
  # @return [Pathname] path
  def default_load_path
    @default_load_path ||= guess_load_path
  end

  # Sets the default load path.
  # @return [Pathname] pathname
  def default_load_path=(name)
    @default_load_path = Pathname(name)
  end

  # Evaluates a block tapped to {I18n::Init} object.
  # return [Init] self
  def config(&block)
    block_given? or return enum_for(__method__)
    tap(&block)
  end

  # Includes backend of a given name to simple backend.
  # @param name [String, Symbol, Module] name of a backend from +I18n::Backend+ or backend module object.
  # @return [void]
  def add_backend(b_name)
    if b_name.is_a?(Module)
      name_f = b_name.name.split(':').last.downcase
    else
      b_name = b_name.to_s
      name_f = b_name
      b_name = I18n::Backend.const_get(b_name)
    end
    require "i18n/backend/#{name_f}" rescue nil
    I18n::Backend::Simple.send(:include, b_name)
  end
  alias_method :add_backend=, :add_backend
  alias_method :new_backend=, :add_backend

  # Gets default fallback locale.
  # @return [String] locale code  
  def default_fallback_locale
    @default_fallback_locale ||= default_locale
  end

  # Gets language names as a hash ready to use by forms.
  # @return [Hash{Symbol,String}] locale codes and names
  def languages_for_forms
    @languages_for_forms ||= available_languages.map{ |name, code| [code, name] }.sort_by{ |c| c.first.downcase }
  end

  # Loads locale configuration from YAML files.
  def load!(cfile = nil)
    self.config_file = cfile if cfile.present?
    if File.exists?(config_file)
      settings  = YAML::load(File.open(config_file))
      available = settings['available'] || {}
      d = settings['default']
      unless @default_locale.present?
        @default_locale   = d.presence if d.present? && available.present? && available.key?(d.to_s)
        @default_locale ||= available.keys.first.to_s.presence
        unless @default_locale.present?
          @default_locale = DEFAULT_LOCALE_RESCUE
          @default_locale_name = DEFAULT_LOCALE_NAME_RESCUE
        end
      end
      unless @default_locale_name.present?
        @default_locale_name   = available[@default_locale].presence
        @default_locale_name ||= available.first[1].to_s.presence
        @default_locale_name ||= DEFAULT_LOCALE_NAME_RESCUE
      end
      @available_languages  = available.presence || { default_locale.to_s => default_locale_name.to_s }
      @available_locales    = available_languages.keys.map { |l| l.to_s }
      @rtl_languages        = settings['rtl']
    else
      unless @default_locale.present?
        @default_locale      = DEFAULT_LOCALE_RESCUE
        @default_locale_name = DEFAULT_LOCALE_NAME_RESCUE
      end
      @default_locale_name.present? or @default_locale_name = DEFAULT_LOCALE_NAME_RESCUE
      @available_languages  = { default_locale.to_s => default_locale_name.to_s }
      @available_locales    = available_languages.keys.map { |l| l.to_s }
      @rtl_languages        = []
    end

    I18n.default_locale = default_locale
    I18n.load_path.concat Dir.glob(default_load_path)

    if I18n.respond_to?(:fallbacks)
      language_codes_map = settings['fallbacks'].presence || {}
      att = [default_fallback_locale.to_sym, default_locale.to_sym]
      available_locales.each do |c|
        default_entry = att.dup.unshift(c.to_sym)
        cmap = language_codes_map[c] || []
        cmap = [ cmap ] unless cmap.is_a?(Array)
        I18n.fallbacks.map(c => cmap + default_entry)
        I18n.fallbacks[c] # pro-forma query
      end
    end
  end
  alias_method :commit!, :load!

  # Enables debugging of translation lookups.
  def debug!
    I18n::Backend::Simple.class_eval do
      def lookup(locale, key, scope = [], options = {})
        init_translations unless initialized?
        keys = I18n.normalize_keys(locale, key, scope, options[:separator])
        puts "I18N keys: #{keys}"
        keys.inject(translations) do |result, _key|
          _key = _key.to_sym
          return nil unless result.is_a?(Hash) && result.key?(_key)
          result = result[_key]
          result = resolve(locale, _key, result, options.merge(:scope => nil)) if result.is_a?(Symbol)
          puts "\t\t => " + result + "\n" if result.is_a?(String)
          result
        end
      end
    end
  end

  # Guesses known framework name.
  # @return [Symbol] framework name
  def framework
    @framework ||= [ :Rails, :Padrino, :Sinatra, :Merb, :NilClass ].find do |fr|
      Kernel.const_defined?(fr)
    end
  end

  private

  # Resets buffers.
  def reset_buffers
    @config_file              = nil
    @available_languages      = nil
    @available_locales        = nil
    @rtl_languages            = nil
    @default_locale           = nil
    @default_locale_name      = nil
    @default_fallback_locale  = nil
    @default_load_path        = nil
    @languages_for_forms      = nil
    @config_file              = nil
    @root_path                = nil
    @framework                = nil
  end

  # Creates instance method wrappers in a singleton class.
  def install_class_methods
    public_methods(false).each do |meth|
      sk = self.class.singleton_class
      next if sk.method_defined?(meth)
      self.class.singleton_class.class_eval do
        define_method(meth) do |*args, &block|
          instance.public_send(meth, *args, &block) 
        end
      end
    end
  end

  # Guesses root path.
  def guess_root_path
    # Try framework-specific paths
    case framework
    when :Sinatra, :Padrino
      if framework == :Padrino && Padrino.root.present?
        return Pathname(Padrino.root)
      end
      if defined?(Sinatra::Base.settings)
        if Sinatra::Base.settings.respond_to?(:root)
          r = Sinatra::Base.settings.root.presence
          r and return Pathname(r)
        elsif Sinatra::Base.settings.respond_to?(:app_file)
          r = Sinatra::Base.settings.app_file.presence
          r and return Pathname(r).dirname
        end
      end
    when :Merb
      return Pathname(Merb.root) if Merb.root.present?
    when :Rails
      return Rails.root if Rails.root.present?
    end
    # Try to localize root path by searching for known files
    r = Pathname(__FILE__).dirname
    [ ['.'], ['..'], ['..', '..'], ['..', '..', '..'] ].each do |prefix|
      if ['app', 'config', 'dist', 'Gemfile'].any? { |d| File.exists?(r.join(*prefix, d)) }
        return r.join(*prefix)
      end
    end
    r
  end

  # Guesses configuration file path.
  def guess_config_file
    fname = DEFAULT_CONFIG_FILE
    # Try framework-specific paths
    case framework
    when :Padrino, :Sinatra
      ['config', 'app', '.'].each do |dir|
        r = root_path.join(dir, fname)
        return r if File.exists?(r)
      end
    when :Rails
      r = root_path.join('config', fname)
      return r if File.exists?(r)
    when :Merb
      [ ['config'], ['conf'],
        ['dist', 'conf'],
        ['dist', 'config']
      ].each do |dirs|
        r = root_path.join(*dirs, fname)
        return r if File.exists?(r)
      end
    end
    [ ['app', 'conf'],  ['app', 'config'],
      ['dist', 'conf'], ['dist', 'config'],
      ['config'], ['conf'], ['app'], ['.']
    ].each do |dirs|
      r = root_path.join(*dirs, fname)
      return r if File.exists?(r)
    end
    root_path.join(fname)
  end

  # Guesses load path.
  def guess_load_path
    globber = [ '**', '*.{rb,yml}' ]
    # Try framework-specific paths
    case framework
    when :Padrino, :Sinatra
      if defined?(Sinatra::Base.settings.locales)
        r = Sinatra::Base.settings.locales
        if (r.is_a?(String) || r.is_a?(Pathname)) && File.exists?(r)
          r = Pathname(r).dirname unless File.directory?(r)
          return Pathname(r).join(*globber) if File.directory?(r)
        end
      end
      if framework == :Padrino
        [ ['app', 'locale'], ['app', 'locales'] ].each do |dirs|
          r = root_path.join(*dirs)
          return r.join(*globber) if File.directory?(r)
        end
      end
    when :Rails
      if File.directory?(root_path.join('config', 'locales'))
        return root_path.join('config', 'locales', *globber)
      end
    when :Merb
      if File.directory?(root_path.join('app', 'i18n'))
        return root_path.join('app', 'i18n', *globber)
      end
    end
    # Try config directory
    r = config_file.dirname
    # Try other known locations
    return r.join(*globber) if File.directory?(r) 
    [ ['config', 'locales'],  ['config', 'locale'],
      ['app', 'locale'],      ['app', 'locales'],
      ['app', 'i18n'],        ['app', 'l10n'],
      ['config', 'i18n'],     ['config', 'l10n'],
      ['i18n'], ['l10n'],     ['locale'], ['locales'],
      ['dist', 'conf', 'locale'],
      ['dist', 'conf', 'locales'],
      ['dist', 'conf', 'i18n'],
      ['dist', 'conf', 'l10n'],
    ].each do |dirs|
      r = root_path.join(*dirs)
      return r.join(*globber) if File.directory?(r)
    end
    # Default to current directory an YML files
    root_path.join('*.yml')
  end
end # class I18n::Init