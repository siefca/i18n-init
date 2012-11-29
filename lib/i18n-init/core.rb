# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
#
# This file contains I18n::Init class.

require 'singleton'

require_relative './debug'
require_relative './confblock'
require_relative './paths'
require_relative './settings'
require_relative './resolver'
require_relative './fallbacks'
require_relative './locales'
require_relative './backends'

# This class handles basic settings of I18n.
class I18n::Init
  include Singleton
  include ConfBlock
  include Fallbacks
  include Locales
  include Resolver
  include Backends
  include Settings
  include Paths
  include Debug

  # Known top-level constants that indicate poular frameworks.
  KNOWN_FRAMEWORKS = [ :Rails, :Padrino, :Sinatra, :Merb ]

  # Delegate methods to configuration block.
  configuration_block_delegate  :p_debug, :p_debug_once, :framework, :environment, :initialized?, :bundled_settings_file,
                                :add_backend, :default_locale, :default_locale=, :default_language, :language_name,
                                :locale=, :locale, :available_locale, :available_locales, :available_locales=,
                                :available_locale=, :available_locale_codes, :delete_language, :delete_locale,
                                :fallback, :fallbacks, :fallback=, :fallbacks=, :fallbacks_use_default, 
                                :fallbacks_use_default!, :fallbacks_use_default?, :fallbacks_use_default=,
                                :default_fallback=, :default_fallbacks=, :default_fallback, :default_fallbacks,
                                :rtl_languages, :rtl_languages=, :root_path, :root_path=, :config_file, :config_file=,
                                :default_load_path,     :default_load_path=,        :resolve_code, :resolve_name,
                                :ignore_settings_file!, :ignore_bundled_settings!,  :ignore_framework_settings!,
                                :ignore_settings_file?, :ignore_bundled_settings?,  :ignore_framework_settings?,
                                :ignore_settings_file=, :ignore_bundled_settings=,  :ignore_framework_settings=,
                                :ignore_settings_file,  :ignore_bundled_settings,   :ignore_framework_settings

  # Initializes instance and creates singleton methods that call
  # public instance methods of the same names.
  # 
  # @return [Init] self
  def initialize
    @debug = true
    p_debug "hello world!"
    reset_buffers
    gather_framework_info
  end

  # Evaluates a block tapped to {I18n::Init} if block is given.
  # return [Init] self
  def config(&block)
    @conf_block_used = true
    block_given? or return configuration_block
    p_debug "evaluating configuration block"
    block.arity == 0 or return configuration_block.tap(&block)
    configuration_block.module_eval(&block)
  end

  # Initializes I18n Init.
  # 
  # @return [nil]
  def load!(cfile = nil)
    if framework == :Rails && @initialization_delayed
      @delayed_load_arg = cfile
      p_debug "delaying initialization"
    else
      p_debug "initializing I18n"
      super if defined?(super)
      invalidate_caches
      @initialized = true
    end
    nil
  end
  alias_method :commit!,  :load!
  alias_method :init!,    :load!

  # Initializes I18n Init unless already initialized.
  # 
  # @return [nil]
  def delayed_load!
    @initialization_delayed = false
    p_debug "performing delayed initialization"
    load!(@delayed_load_arg) unless initialized?
    nil
  end

  # Returns true if initialization is completed.
  # 
  # @return [Boolean] +true+ if initialized, +false+ otherwise
  def initialized?
    @initialized
  end

  # Clears internal data.
  # 
  # @return [nil]
  def reset!
    reset_buffers
    nil
  end

  # Guesses known framework name.
  # 
  # @return [Symbol] framework name
  def framework
    @framework ||= KNOWN_FRAMEWORKS.find { |fr| Kernel.const_defined?(fr) } || :unknown
  end

  # Gets some info about I18n settings.
  # 
  # @return [String] information about I18n settings.
  def info
    i18n_info
  end

  # Prints info.
  # 
  # @return [void]
  def print_info
    puts info
  end

  # Gets framework environment.
  # 
  # @return [Symbol] envoronment name
  def environment
    @environment.present? and return @environment
    p_debug "reading environment"
    case framework
    when :Rails
      @environment = Rails.env
    when :Merb
      @environment = Merb.environment
    when :Padrino, :Sinatra
      if framework == :Padrino && defined?(Padrino::Application.settings) &&
         Padrino::Application.settings.respond_to?(:environment)
        @environment = Padrino::Application.settings.environment
      elsif defined?(Sinatra::Base.settings) && Sinatra::Base.settings.respond_to?(:environment)
        @environment = Sinatra::Base.settings.environment
      end
    end
    @environment   = @environment.presence
    @environment ||= ENV['RACK_ENV'].presence || ENV['ENV'].presence || ENV['ENVIRONMENT'].presence
    @environment ||= 'production'  if ENV.has_key?('production')
    @environment ||= 'development' if ENV.has_key?('development')
    @environment ||= 'test'        if ENV.has_key?('test')
    @environment   = @environment.presence
    @environment &&= @environment.to_s.downcase
  end

  # Tells if configuration block has been used.
  # 
  # @return [Boolean] +true+ if used, +false+ otherwise
  def configuration_block_used?
    @conf_block_used
  end

  private

  # Gets a list of backend modules.
  def backend_modules_list
    I18n.backend.class.included_modules.
      map     { |m| m.to_s                                }.
      select  { |m| m[0..12] == "I18n::Backend"           }.
      map     { |m| m.split(':').last                     }.
      reject  { |m| ['Base','Implementation'].include?(m) }.
      join(', ')
  end

  # Resets buffers.
  def reset_buffers
    p_debug "resetting buffers"
    @framework              = nil
    @initialized            = false
    @initialization_delayed = true
    @delayed_load_arg       = nil
    @environment            = nil
    @conf_block_used        = false
    super if defined?(super)
    invalidate_caches
    nil
  end

  # Invalidates cached settings based on configuration file contents.
  def invalidate_caches
    p_debug "invalidating caches"
    super if defined?(super)
    nil
  end

  # Memorizes framework-related configuration in early stage of initialization.
  def gather_framework_info
    super if defined?(super)
  end

  # Gets some info about I18n settings.
  def i18n_info
    <<-INFO
I18n info 
---------

I18n is #{initialized? ? "initialized" : "not initialized"}.
Framework is #{framework}. Environment is #{environment || 'not set'}.
I18n Init configuration block has #{configuration_block_used? ? "" : "not "}been used.

Configuration file:     #{config_file}
Bundled settings file:  #{bundled_settings_file}

Main backend:  #{I18n.backend.class.name}
Used backends: #{backend_modules_list}

Current locale: #{I18n.locale} (#{I18n.language}), fallbacks: #{I18n.fallbacks[I18n.locale].join(" -> ")}
Default locale: #{I18n.default_locale} (#{I18n.default_language}), fallbacks: #{I18n.fallbacks[I18n.default_locale].join(" -> ")}

Default fallbacks: #{I18n.fallbacks.defaults.join(' -> ')}

Available locales:
  #{list_available_locales(false)}.

Available fallbacks:
  #{list_fallbacks}.

INFO
  end

end # class I18n::Init
