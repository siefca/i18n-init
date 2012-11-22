# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains module used to handle fallbacks.

# This class handles basic initial settings of I18n.
class I18n::Init

  # This module handles fallbacks.
  module Fallbacks

    # Sets or unsets the flag that causes +default_fallback_locale+
    # and +default_locale+ to be added as fallbacks for any language.
    def fallbacks_use_default=(v)
      @fallbacks_use_default = !!v
    end

    def fallbacks_use_default!
      self.fallbacks_use_default = true
    end

    def fallbacks_use_default?
      @fallbacks_use_default
    end

    def fallbacks_use_default(*args)
      case args.count
      when 0
        return fallbacks_use_default?
      when 1
        self.fallbacks_use_default(args.first)
      else
        raise ArgumentError, "wrong number of arguments (#{args.count} for 1)"
      end
    end

    # Gets or sets default fallback locale.
    # 
    # @return [String] locale code  
    def default_fallback_locale(code = nil)
      return (self.default_fallback_locale = code) unless code.nil?
      @default_fallback_locale ||= default_locale
    end

    def default_fallback_locale=(code)
      @default_fallback_locale = code.to_sym
    end

    # Loads locale configuration from YAML files.
    # 
    # @return [nil]
    def load!(cfile = nil)
      setup_fallbacks
      super if defined?(super)
    end

    private

    # Sets up fallbacks.
    def setup_fallbacks
      if I18n.respond_to?(:fallbacks)
        language_codes_map = settings['fallbacks'].presence || {}
        att = [default_fallback_locale.to_sym, default_locale.to_sym]
        available_locales.each_pair do |c, cname|
          default_entries = @fallbacks_use_default ? att.dup.unshift(c.to_sym) : []
          cmap = language_codes_map[c] || []
          cmap = [ cmap ] unless cmap.is_a?(Array)
          I18n.fallbacks.map(c => (cmap + default_entries).uniq!)
        end
      end
    end

    # Resets buffers.
    def reset_buffers
      @fallbacks_use_default    = true
      @default_fallback_locale  = nil
      super if defined?(super)
    end

  end # module Fallbacks
end # class I18n::Init
