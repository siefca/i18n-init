# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
#
# This file contains I18n::Init class.

require 'pathname'
require 'singleton'

require_relative './paths'
require_relative './settings'
require_relative './resolver'
require_relative './fallbacks'
require_relative './locales'
require_relative './backends'

# This class handles basic settings of I18n.
class I18n::Init
  include Singleton
  include Paths
  include Settings
  include Resolver
  include Locales
  include Fallbacks
  include Backends

  # Initializes instance and creates singleton methods that call
  # public instance methods of the same names.
  # 
  # @return [Init] self
  def initialize
    reset_buffers
  end

  # Evaluates a block tapped to {I18n::Init} if block is given.
  # return [Init] self
  def config(&block)
    block_given? or return self
    block.arity == 0 or return tap(&block)
    instance_eval(&block)
  end

  # Loads locale configuration from YAML files.
  # 
  # @return [nil]
  def load!(cfile = nil)
    super if defined?(super)
    @initialized = true
    nil
  end
  alias_method :commit!,  :load!
  alias_method :init!,    :load!

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
    @framework ||= [ :Rails, :Padrino, :Sinatra, :Merb, :NilClass ].find do |fr|
      Kernel.const_defined?(fr)
    end
  end

  def list_available_with_names
    available_languages.each_with_object do |code, name, o|
      available_languages[code.to_s]
    end
  end

  # Enables debugging of translation lookups.
  # 
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

    # Gets some info about I18n settings.
    def info
      <<-INFO
  I18n info 
  ----------

  I18n is #{initialized? ? "initialized" : "not initialized"}.

  current locale:           #{I18n.locale} (#{I18n.language})
  current locale fallbacks: #{I18n.fallbacks[I18n.locale].join(" -> ")}

  default locale:           #{I18n.default_locale} (#{I18n.default_language})
  default locale fallbacks: #{I18n.fallbacks[I18n.default_locale].join(" -> ")}

  default fallback locale:  #{default_fallback_locale} (#{resolve_code(default_fallback_locale)})

  available locales:        #{available_languages.each_with_object([]) { |(c,n),o|  o << "#{c} (#{n})" }.join(", ")}

  INFO
    end

  private

  # Resets buffers.
  def reset_buffers
    @framework    = nil
    @initialized  = false
    super if defined?(super)
    invalidate_caches
    nil
  end

  # Invalidates cached settings based on configuration file contents.
  def invalidate_caches
    super if defined?(super)
    nil
  end

end # class I18n::Init
