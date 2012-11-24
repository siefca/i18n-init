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
        fallbacks_use_default?
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
      return @default_fallback_locale if @default_fallback_locale.present?
      if default_fallbacks_from_framework.present?
        @default_fallback_locale = default_fallbacks_from_framework
        s_title = "framework settings"
      end
      if @default_fallback_locale.blank? && default_locale.present?
        @default_fallback_locale = Array(default_locale)
        s_title = "default locale"
      end
      if @default_fallback_locale.blank?
        @default_fallback_locale = []
        s_title = nil
      end
      if s_title 
        p_debug "default fallback locale#{@default_fallback_locale.count == 1 ? ' is' : 's are'} " <<
                "#{@default_fallback_locale.join(', ')} (based on #{s_title})"
      else
        p_debug "cannot determine default fallback locale"
      end
      @default_fallback_locale
    end
    alias_method :default_fallback_locales, :default_fallback_locale
    alias_method :default_fallback,         :default_fallback_locale
    alias_method :default_fallbacks,        :default_fallback_locale

    def default_fallback_locale=(code)
      if code.is_a?(Array)
        @default_fallback_locale = code.compact.map{|c| c.to_s.to_sym}
      else
        @default_fallback_locale = Array(code.to_s.to_sym)
      end
    end

    # Loads locale configuration from YAML files.
    # 
    # @return [nil]
    def load!(cfile = nil)
      setup_fallbacks
      super if defined?(super)
    end

    private

    def fallbacks_from_file
      normalize(settings['fallbacks'] || {})
    end

    def fallbacks_from_framework
      fb = @framework_conf[:fallbacks]
      case framework
      when :Rails
        return normalize(fb) if fb.is_a?(Hash)
      end
      {}
    end

    def default_fallbacks_from_framework
      fb = @framework_conf[:fallbacks]
      case framework
      when :Rails
        return (fb.blank? || fb == true || fb.is_a?(Hash)) ? [] : Array(fb)
      end
      I18n.fallbacks.defaults
    end

    def normalize(src = {})
      src.each_with_object({}) do |(k,v),o|
        o[k.to_sym] = Array(v).map{ |l| l.to_sym if l.present? }.compact
      end
    end

    def merge_fallbacks(source, title)
      @fallbacks_merged =
        (source.present? ? source.merge(@fallbacks_merged) : @fallbacks_merged).tap do |r|
          p_debug "   - from #{title} (sourced #{r.count - @fallbacks_merged.count} entries)"
        end
    end

    def fallbacks_merged
      @fallbacks_merged.present? and return @fallbacks_merged
      p_debug " - merging known sources"
      merge_fallbacks(@fallbacks, "configuration block")
      merge_fallbacks(fallbacks_from_file, "configuration file")
      merge_fallbacks(fallbacks_from_framework, "framework settings")
      @fallbacks_merged
    end

    # Sets up fallbacks.
    def setup_fallbacks
      return nil unless I18n.respond_to?(:fallbacks)
      return nil if framework == :Rails && Rails.configuration.i18n.fallbacks == false
      p_debug "setting up fallbacks"
      merged = fallbacks_merged
      if @fallbacks_use_default
        I18n.fallbacks = I18n::Locale::Fallbacks.new(default_fallback_locale)
        p_debug "default fallback locale will be used"
      else
        I18n.fallbacks = I18n::Locale::Fallbacks.new
      end
      available_locales.each_pair do |locale, language|
        locale = locale.to_sym
        merged[locale].tap do |entries|
          I18n.fallbacks.tap do |f|
            if entries.present?
              entries = entries.dup
              entries.delete(locale)
              f.map(locale => entries)
              p_debug " - #{locale} -> #{entries.join(' -> ')}"
            end
          end
        end
      end
    end

    # Resets buffers.
    def reset_buffers
      p_debug "resetting buffers"
      @fallbacks_use_default    = true
      @default_fallback_locale  = nil
      @fallbacks                = {}
      @fallbacks_merged         = {}
      super if defined?(super)
    end

    def gather_framework_info
      case framework
      when :Rails
        if Rails.configuration.respond_to?(:i18n)
          Rails.configuration.i18n.tap do |c|
            @framework_conf[:fallbacks]       = c.fallbacks
            @framework_conf[:load_path]       = c.load_path
            @framework_conf[:default_locale]  = c.default_locale
          end
        end
      end
      super if defined?(super)
    end

  end # module Fallbacks
end # class I18n::Init
