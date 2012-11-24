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
  include Fallbacks
  include Locales
  include Resolver
  include Backends
  include Settings
  include Paths
  include Debug

  # Known top-level objects that 
  KNOWN_FRAMEWORKS = [ :Rails, :Padrino, :Sinatra, :Merb ]

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
    block_given? or return self
    p_debug "evaluating configuration block"
    block.arity == 0 or return tap(&block)
    instance_eval(&block)
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

  def list_available_with_names
    available_languages.each_with_object do |code, name, o|
      available_languages[code.to_s]
    end
  end

  # Gets some info about I18n settings.
  def info
    <<-INFO
I18n info 
---------

I18n is #{initialized? ? "initialized" : "not initialized"}.
Framework is #{framework}.

Main backend: #{I18n.backend.class.name}
Used backends: #{backend_modules_list}

Current locale: #{I18n.locale} (#{I18n.language}), fallbacks: #{I18n.fallbacks[I18n.locale].join(" -> ")}
Default locale: #{I18n.default_locale} (#{I18n.default_language}), fallbacks: #{I18n.fallbacks[I18n.default_locale].join(" -> ")}

Default fallbacks: #{I18n.fallbacks.defaults.join(' -> ')}

Available locales: #{available_languages.each_with_object([]) { |(c,n),o|  o << "#{c} (#{n})" }.join(", ")}


  INFO
  end

  # Prints info.
  def print_info
    puts info
  end

  private

  def backend_modules_list
    I18n.backend.class.included_modules.
      map     { |m| m.to_s                      }.
      select  { |m| m[0..12] == "I18n::Backend" }.
      map     { |m| m.split(':').last           }.join(', ')
  end

  # Resets buffers.
  def reset_buffers
    p_debug "resetting buffers"
    @framework              = nil
    @initialized            = false
    @initialization_delayed = true
    @delayed_load_arg       = nil
    super if defined?(super)
    invalidate_caches
    nil
  end

  # Invalidates cached settings based on configuration file contents.
  def invalidate_caches
    p_debug "invalidating caches"
    @framework_conf = {}
    super if defined?(super)
    nil
  end

  # Memorizes framework-related configuration in early stage of initialization.
  def gather_framework_info
    super if defined?(super)
  end

end # class I18n::Init
