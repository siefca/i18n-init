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
  DEFAULT_LOCALE_RESCUE       = :en
  DEFAULT_LOCALE_NAME_RESCUE  = 'English'

  attr_reader :locale
  attr_reader :settings
  attr_reader :rtl_languages
  attr_reader :default_locale_code
  attr_reader :default_locale_name
  attr_reader :fallbacks_use_default

  attr_writer :default_fallback_locale

  # Initializes instance and creates singleton methods that call
  # public instance methods of the same names.
  # @return [Init] self
  def initialize
    reset_buffers
    install_class_methods
    install_setters
  end

  # Returns framework's root path.
  # @return [String] path
  def root_path
    @root_path.nil? or return @root_path
    invalidate_caches
    @root_path = guess_root_path
  end

  # Sets root path.
  # @return [Pathname] pathname
  def root_path=(name)
    invalidate_caches
    @root_path = name.blank? ? nil : Pathname(name.to_s)
  end

  # Returns the config file path.
  # @return [String] path
  def config_file
    @config_file.nil? or return @config_file
    invalidate_caches
    @config_file = guess_config_file
  end

  # Sets the config file path.
  # @param name [String,Pathname] path
  def config_file=(name)
    invalidate_caches
    @config_file = name.blank? ? nil : Pathname(name.to_s)
  end

  # Sets the default locale.
  # @note It will also set default locale name (language name) if it
  #  will find it in available languages and it hasn't been set already.
  # @param locale_code [String,Symbol] locale
  # @return [void]
  def default_locale(locale_code = nil)
    return @default_locale_code if locale_code.nil?
    return nil if locale_code.blank?
    locale_code = { locale_code => nil } unless locale_code.is_a?(Hash)
    locale_code.each_pair do |code, name|
      @default_locale_code = code.to_sym
      @default_locale_name = name.blank? ? @available_locales[code.to_s].presence : name.to_s
    end
    nil
  end

  # Sets the default locale.
  def default_locale=(locale_code)
    default_locale(locale_code)
  end

  # Gets the language name of a default locale.
  def default_language_name
    resolve_code(I18n.default_locale)
  end
  alias_method :default_language, :default_language_name

  # Gets the language name of current locale.
  def language_name
    resolve_code(I18n.locale)
  end
  alias_method :language, :language_name

  # Sets the initial locale that will be set on load.
  # @param locale_code [String,Symbol] locale
  # @return [Symbl] locale
  def locale=(locale_code)
    @locale = locale_code.to_sym
  end

  # fixme: override
  # Adds available language to available languages.
  # @param locale_code [String,Symbol] locale code (e.g. +:pl+)
  # @param language_name [String,Symbol] name of a language in its native language
  # @return [String,Hash] added language name or a hash of added languages
  def available_locale(*args)
    return @available_locales if args.empty?
    args.each do |arg|
      if arg.is_a?(Hash)
        arg.each_pair do |code, name|
          if @available_locales.key?(code.to_s)
            @available_locales[code.to_s] = name.to_s if name.present?
          else
            @available_locales[code.to_s] = name.to_s.presence
          end
        end
      else
        arg = [ arg ] unless arg.is_a?(Array)
        @available_filter.concat(arg.map(&:to_s))
      end
    end # args.each
    nil
  end
  alias_method :available_locales,  :available_locale
  alias_method :available_language, :available_locale

  # Gets available languages hash
  def available_languages
    I18n.available_locales.each_with_object({}) do |code, o|
      o[code.to_s] = available_locales[code.to_s]
    end
  end

  # Gets names of available languages.
  def available_language_names
    I18n.available_locales.map do |code|
      available_locales[code.to_s].presence || code.to_s
    end
  end

  # Adds locale to available locales.
  # 
  # @return [nil]
  def available_locales=(arg)
    return available_locales(*arg) if arg.is_a?(Array)
    available_locales(arg)
  end

  # Reads the default load path.
  # @return [Pathname] path
  def default_load_path
    @default_load_path ||= guess_load_path
  end
  alias_method :load_path, :default_load_path

  # Sets the default load path.
  # @return [Pathname] pathname
  def default_load_path=(name)
    @default_load_path = Pathname(name)
  end
  alias_method :load_path=, :default_load_path=

  # Evaluates a block tapped to {I18n::Init} if block is given.
  # return [Init] self
  def config(&block)
    block_given? or return self
    block.arity == 0 or return tap(&block)
    instance_eval(&block)
  end

  # Includes backend of a given name to simple backend.
  # @param name [String, Symbol, Module] name of a backend from +I18n::Backend+ or backend module object.
  # @return [nil]
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
    nil
  end
  alias_method :add_backend=, :add_backend
  alias_method :new_backend=, :add_backend

  # Gets default fallback locale.
  # @return [String] locale code  
  def default_fallback_locale
    @default_fallback_locale ||= default_locale
  end

  # Gets the array containing strings of available locale codes.
  # @return [Array<String>] available locale codes
  def available_locale_codes
    available_locales.keys.map { |l| l.to_s }
  end

  # Removes lanuage from available languags hash.
  # @param locale_code [String,Symbol] locale code (e.g. +:pl+)
  # @return [String] deleted language name
  def delete_language(locale_code)
    @available_locales.delete(locale_code.to_s)
  end
  alias_method :delete_locale,  :delete_language
  alias_method :del_language,   :delete_language
  alias_method :del_locale,     :delete_language

  # Loads locale configuration from YAML files.
  # @return [nil]
  def load!(cfile = nil)
    self.config_file = cfile if cfile.present?

    setup_available_locales
    setup_default_locale
    setup_rtl_locale
    remove_unwanted_locales
    fix_missing_locale_names
    setup_fallbacks

    I18n.available_locales  = available_locales.keys
    I18n.default_locale     = default_locale
    I18n.locale             = available_locales.key?(locale.to_s) ? locale : default_locale
    I18n.load_path.concat Dir.glob(default_load_path)

    @initialized = true
    nil
  end
  alias_method :commit!,  :load!
  alias_method :init!,    :load!

  # Returns true if initialization has been done.
  # @return [Boolean] +true+ if initialized, +false+ otherwise
  def initialized?
    @initialized
  end

  # Clears internal data.
  # @return [nil]
  def reset!
    reset_buffers
  end

  # Enables debugging of translation lookups.
  # @return [nil]
  def debug!
    I18n::Backend::Simple.class_eval do
      def lookup(locale, key, scope = [], options = {})
        init_translations unless initialized?
        keys = I18n.normalizetr_keys(locale, key, scope, options[:separator])
        puts "I18N keys: #{keys}"
        keys.inject(translations) do |result, tr_key|
          tr_key = tr_key.to_sym
          return nil unless result.is_a?(Hash) && result.key?(tr_key)
          result = result[tr_key]
          result = resolve(locale, tr_key, result, options.merge(:scope => nil)) if result.is_a?(Symbol)
          puts "\t\t => " + result + "\n" if result.is_a?(String)
          result
        end
      end
    end
    nil
  end
  alias_method :enable_debug, :debug!

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
    @settings                 = {}
    @available_locales        = {}
    @available_filter         = []
    @rtl_languages            = []
    @fallbacks_use_default    = true
    @resolver_cache           = nil
    @resolver_cache_rev       = nil
    @locale                   = nil
    @default_locale_code      = nil
    @default_locale_name      = nil
    @default_fallback_locale  = nil
    @default_load_path        = nil
    @config_file              = nil
    @root_path                = nil
    @framework                = nil
    @initialized              = false
    nil
  end

  # Invalidates cached settings based on configuration file contents.
  def invalidate_caches
    @settings = nil
    @resolver_cache = nil
    @resolver_cache_rev = nil
  end

  # Loads settings from YAML file.
  def yaml_load(fname)
    return {} unless File.exists?(fname)
    f = File.open(fname)
    r = YAML::load(f)
    f.close
    r.nil? ? {} : r
  end

  # Loads settings if needed and returns settings hash.
  def _settings
    return @settings unless @settings.blank?
    @settings = yaml_load(config_file)
  end

  def _settings_bundled
    return @settings_bundled unless @settings_bundled.blank?
    f = Pathname(__FILE__).dirname.join('..', 'example_settings', DEFAULT_CONFIG_FILE)
    @settings_bundled = yaml_load(f)
  end

  # Returns resolver.
  def resolver
    return @resolver_cache unless @resolver_cache.blank?
    @resolver_cache = {}
    sources = []
    sources << (_settings_bundled['available'] || {}) unless _settings['i18n-init-bundled']
    sources << (_settings['available'] || {})
    sources << available_locales
    sources.each_with_object(@resolver_cache) do |src, r|
      src.each_pair do |code, name|
        unless name.blank?
          r[code.to_s] = name.to_s
        end
      end
    end
  end

  # Returns reverse resolver.
  def resolver_rev
    @resolver_cache_rev ||= @resolver_cache.invert
  end

  # Resolves locale code.
  def resolve_code(code)
    code.blank? ? nil : (resolver[code.to_s].presence || code.to_s)
  end

  # Resolves name.
  def resolve_name(name)
    name.blank? ? nil : (resolver_rev[name.to_s].presence || name.to_s)
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
    nil
  end

  # Installs setting aliases for setters.
  def install_setters
    meths = public_methods(false).map(&:to_s).grep(/\=\z/)
    self.class.class_eval do
      meths.each do |writer|
        reader = writer.chop
        if method_defined?(reader)
          if instance_method(reader).arity == 0
            reader_orig = "#{reader}_without_rw"
            alias_method(reader_orig, reader)
            define_method(reader) do |*args|
              args.blank? and return public_send(reader_orig)
              args.count > 1 and raise ArgumentError, "wrong number of arguments (#{args.count} for 0..1)"
              public_send(writer, args.first)
            end
          end
        else
          alias_method(reader, writer)
        end
      end
    end
    nil
  end

  # Sets up available locales.
  def setup_available_locales
    from_file = _settings['available'] || {}
    from_file.each_pair do |code, name|
      code = code.to_s
      if @available_locales.key?(code)
        if @available_locales[code].blank? && name.present?
          @available_locales[code] = name.to_s
        end
      else
        @available_locales[code] = name.to_s
      end
    end
    nil
  end

  # Removes unwanted locales if filter is present.
  def remove_unwanted_locales
    if @available_filter.present?
      @available_locales = @available_filter.each_with_object({}) do |code, o|
        o[code] = @available_locales[code]
      end
    end
    if @available_locales[@default_locale_code.to_s].blank?
      @available_locales[@default_locale_code.to_s] = @default_locale_name
    end
  end

  # Fixes missing locale names.
  def fix_missing_locale_names
    @available_locales.each_pair do |code, name|
      if name.blank?
        @available_locales[code] = resolve_code(code)
      end
    end
  end

  # Sets up RTL locales.
  def setup_rtl_locale
    if _settings['rtl'].present?
      @rtl_languages.concat(_settings['rtl']).uniq!
    end
    nil
  end

  # Sets up default locale.
  def setup_default_locale
    if @default_locale_code.present?
      @default_locale_name ||= @available_locales[@default_locale_code.to_s].presence
      @default_locale_name ||= @default_locale_code.to_s
    else # default locale code is missing
      @default_locale_code   = _settings['default'].presence
      @default_locale_code &&= @default_locale_code.to_sym
      if @default_locale_code.present? # default locale code given in file
        @default_locale_name ||=  @available_locales[@default_locale_code.to_s].presence
        @default_locale_name ||= @default_locale_code.to_s
      else # default locale not found in file and not given
        if @available_locales.present? && @available_locales.first.is_a?(Array) && @available_locales.first.count == 2
          @default_locale_code = @available_locales.first[0]
          @default_locale_name = @available_locales.first[1]
        end
        if @default_locale_code.blank?
          @default_locale_code = DEFAULT_LOCALE_RESCUE
          @default_locale_name = DEFAULT_LOCALE_NAME_RESCUE
        else
          @default_locale_code = @default_locale_code.to_sym
        end
      end
    end
    nil
  end

  # Sets or unsets the flag that causes +default_fallback_locale+
  # and +default_locale+ to be added as fallbacks for any language.
  def fallbacks_use_default=(v)
    @fallbacks_use_default = !!v
  end

  # Sets up default locale.
  def setup_fallbacks
    if I18n.respond_to?(:fallbacks)
      language_codes_map = _settings['fallbacks'].presence || {}
      att = [default_fallback_locale.to_sym, default_locale.to_sym]
      available_locales.each_pair do |c, cname|
        default_entries = @fallbacks_use_default ? att.dup.unshift(c.to_sym) : []
        cmap = language_codes_map[c] || []
        cmap = [ cmap ] unless cmap.is_a?(Array)
        I18n.fallbacks.map(c => (cmap + default_entries).uniq!)
        I18n.fallbacks[c] # pro-forma query
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
        return r if File.readable?(r)
      end
    when :Rails
      r = root_path.join('config', fname)
      return r if File.readable?(r)
    when :Merb
      [ ['config'], ['conf'],
        ['dist', 'conf'],
        ['dist', 'config']
      ].each do |dirs|
        r = root_path.join(*dirs, fname)
        return r if File.readable?(r)
      end
    end
    # Search known locations
    [ ['app', 'conf'],  ['app', 'config'],
      ['dist', 'conf'], ['dist', 'config'],
      ['config'], ['conf'], ['app'], ['.']
    ].each do |dirs|
      r = root_path.join(*dirs, fname)
      return r if File.readable?(r)
    end
    # Return bundled settings
    r = Pathname(__FILE__).dirname.join('..', 'example_settings', fname)
    return r if File.exists?(r)
    # Return root path + config file
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
    # Try other known locations
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
    # Try config directory
    r = config_file.dirname
    if File.directory?(r) && r != 'example_settings'
      return r.join(*globber)
    end
    # Default to current directory and YAML files only
    root_path.join('*.yml')
  end
end # class I18n::Init
