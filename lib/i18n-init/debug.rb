# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains module used to setup debugging.

# This class handles basic initial settings of I18n.
class I18n::Init

  # This module handles debugging.
  module Debug

    # Initializes I18n Init.
    # 
    # @return [nil]
    def load!(cfile = nil)
      debug! if Rails.env.development? && ENV['I18N_DEBUG']
      super if defined?(super)
    end

    # Prints out debug message to stderr if debug mode is enabled.
    def p_debug(*messages)
      messages.each { |m| STDERR.puts("I18n Init #{(calling_owner(3)+':').ljust(12)} #{m}") } if @debug
      nil
    end

    # Enables debugging of translation lookups and I18n initialization.
    # 
    # @return [nil]
    def debug!
      return nil if @debug
      I18n::Backend::Simple.class_eval do
        def lookup(locale, key, scope = [], options = {})
          init_translations unless initialized?
          keys = I18n.normalizetr_keys(locale, key, scope, options[:separator])
          STDERR.puts "I18N keys: #{keys}"
          keys.inject(translations) do |result, tr_key|
            tr_key = tr_key.to_sym
            return nil unless result.is_a?(Hash) && result.key?(tr_key)
            result = result[tr_key]
            result = resolve(locale, tr_key, result, options.merge(:scope => nil)) if result.is_a?(Symbol)
            puts STDERR, "\t\t => " + result + "\n" if result.is_a?(String)
            result
          end
        end
      end
      @debug = true
      p_debug "enabling debug"
      nil
    end
    alias_method :enable_debug, :debug!

    private

    # Resets buffers.
    def reset_buffers
      @debug ||= false
      super if defined?(super)
    end

    def calling_owner(level = 1)
      caller[level].split('/').last.split('.').first.capitalize
    end

  end # module Debug
end # class I18N::Init
