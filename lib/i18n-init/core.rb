# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
#
# This file contains I18n::Init class.

require 'singleton'

require_relative './debug'
require_relative './paths'
require_relative './settings'
require_relative './resolver'
require_relative './fallbacks'
require_relative './locales'
require_relative './backends'

# This class handles basic settings of I18n.
class I18n::Init

  include Singleton
  include ConfigurationBlocks
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
  configuration_methods :framework, :environment, :initialized?

  # Evaluates a block tapped to {I18n::Init} if block is given.
  # return [Init] self
  def config(&block)
    p_debug "evaluating configuration block"
    @conf_block_used = true
    configuration_block(&block)
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

  # Initializes engine.
  # 
  # @return [Init] self
  def initialize
    prepare!
  end

  private

  # Prepares engine.
  # 
  # @return [Init] self
  def prepare!
    p_debug "hello world!"
    reset_buffers
    self
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
    @caches_clean           = false
    super if defined?(super)
    invalidate_caches
    nil
  end

  # Invalidates cached settings based on configuration file contents.
  def invalidate_caches
    return nil if @caches_clean
    p_debug "invalidating caches"
    super if defined?(super)
    @caches_clean = true
    nil
  end

  # Marks internal caches as dirty.
  def caches_dirty!
    @caches_clean = false
  end

  # Gets some info about I18n settings.
  def i18n_info
    <<-INFO

I18n info 
---------

I18n is #{initialized? ? "initialized" : "not initialized"}. Framework is #{framework}. Environment is #{environment || 'not set'}.

Configuration file:     #{config_file}
Bundled settings file:  #{bundled_settings_file}

Sources of settings: #{settings_info}

Main backend:  #{I18n.backend.class.name}
Used backends: #{backend_modules_list}

Current locale: #{I18n.locale} (#{I18n.language}), fallbacks: #{fallbacks_list(I18n.locale)}
Default locale: #{I18n.default_locale} (#{I18n.default_language}), fallbacks: #{fallbacks_list(I18n.default_locale)}

Default fallbacks: #{default_fallbacks_list}

Available locales:
  #{list_available_locales(false)}.

Available fallbacks:
  #{list_fallbacks}.

INFO
  end
end # class I18n::Init
