# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains module used to handle fallbacks.

# This class handles basic initial settings of I18n.
class I18n::Init

  # This module handles fallbacks.
  module Fallbacks

    # @override fallback
    #   Returns known fallbacks.
    #   
    #   @return [Hash{Symbol => Array<Symbol>}] fallbacks map
    # 
    # @override fallback(fallback_map)
    #   Adds fallback(s) to memorized fallbacks. If fallbacks for the given language exist
    #   it will replace them.
    #   
    #   @param fallback_map [Hash{Symbol,String => Symbol,String,Array<Symbol,String>}] fallbacks map
    #   @return [Hash{Symbol => Array<Symbol>}] current fallbacks map
    def fallback(fallback_map = nil)
      return @fallbacks if fallback_map.nil?
      @fallbacks.merge!(normalize(fallback_map))
    end
    alias_method :fallbacks, :fallback

    # Sets or unsets the flag that causes +default_fallback_locale+
    # to be used as fallback(s) for any language.
    # 
    # @param v [Boolean,Object] value 
    # @return [Boolean] current state
    def fallbacks_use_default=(v)
      @fallbacks_use_default = !!v
    end

    # Sets the flag that causes +default_fallback_locale+
    # to be used as fallback(s) for any language.
    # 
    # @return [Boolean] +true+
    def fallbacks_use_default!
      self.fallbacks_use_default = true
    end

    # Returns +true+ if +fallbacks_use_default+ flag is set.
    # 
    # @return [Boolean] current state of +fallbacks_use_default+
    def fallbacks_use_default?
      @fallbacks_use_default
    end

    # @override fallbacks_use_default(v)
    #   Sets or unsets the flag that causes +default_fallback_locale+
    #   to be used as fallback(s) for any language.
    #   
    #   @param v [Boolean,Object] value 
    #   @return [Boolean] current state
    # 
    # @override fallbacks_use_default
    #   Returns +true+ if +fallbacks_use_default+ flag is set.
    #   
    #   @return [Boolean] current state
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

    # @override default_fallback_locale(code)
    #   Sets default fallback locale.
    #   
    #   @param code [Symbol,String,Array<Symbol,String>] locale code(s)
    #   @return [Array<Symbol>] current fallback locale(s)
    # 
    # @override default_fallback_locale
    #   Gets current fallback locale(s) setting.
    #   
    #   @return [String] locale code  
    def default_fallback_locale(code = nil)
      return (self.default_fallback_locale = code) unless code.nil?
      return @default_fallback_locale if @default_fallback_locale.present?
      if default_fallbacks_from_file.present?
        @default_fallback_locale = default_fallbacks_from_file
        s_title = "settings file"
      end
      if @default_fallback_locale.blank? && default_fallbacks_from_framework.present?
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

    # @override default_fallback_locale(code)
    #   Sets default fallback locale.
    #   
    #   @param code [Symbol,String,Array<Symbol,String>] locale code(s)
    #   @return [Array<Symbol>] current fallback locale(s)
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

    def list_fallbacks
      lj = fallbacks.keys.max_by(&:length).length
      fallbacks.keys.sort.each_with_object([]) do |f,o|
        o << "- #{f.to_s.ljust(lj)} -> #{I18n.fallbacks[f].join(' -> ')}"
      end.join(",\n  ")
    end

    private

    # Read fallbacks from a configuration file.
    def fallbacks_from_file
      @fallbacks_from_file ||= normalize(settings['fallbacks'] || {})
    end

    # Read default fallbacks from a configuration file.
    def default_fallbacks_from_file
      settings['default_fallbacks'].presence || []
    end

    # Read fallbacks from a framework settings.
    def fallbacks_from_framework
      fb = @framework_conf[:fallbacks]
      case framework
      when :Rails
        return normalize(fb) if fb.is_a?(Hash)
      end
      {}
    end

    # Read default fallbacks from a configuration file.
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

    # Reverse-merges fallbacks from the given source.
    def merge_fallbacks(source, title)
      @fallbacks_merged =
        (source.present? ? source.merge(@fallbacks_merged) : @fallbacks_merged).tap do |r|
          p_debug "   - from #{title} (sourced #{r.count - @fallbacks_merged.count} entries)"
        end
    end

    # Returns merged fallbacks.
    def fallbacks_merged
      @fallbacks_merged.nil? or return @fallbacks_merged
      @fallbacks_merged = {}
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
      @fallbacks = fallbacks_merged
      if @fallbacks_use_default
        I18n.fallbacks = I18n::Locale::Fallbacks.new(default_fallback_locale)
        p_debug "default fallback locale will be used"
      else
        I18n.fallbacks = I18n::Locale::Fallbacks.new
      end
      @fallbacks.each_pair do |code, entries|
        next if entries.blank?
        entries = entries.dup
        entries.delete(code)
        I18n.fallbacks.map(code => entries)
        p_debug " - #{code} -> #{entries.join(' -> ')}"
      end
    end

    # Resets buffers.
    def reset_buffers
      p_debug "resetting buffers"
      @fallbacks_use_default    = true
      @default_fallback_locale  = nil
      @fallbacks                = {}
      super if defined?(super)
    end

    # Invalidates cached settings based on configuration file contents.
    def invalidate_caches
      p_debug "invalidating caches"
      @fallbacks_merged     = nil
      @fallbacks_from_file  = nil
      super if defined?(super)
    end

    # Gathers framework configuration for later use.
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
