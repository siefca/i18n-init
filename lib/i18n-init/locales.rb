# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains module used to find and set paths.

# This class handles basic initial settings of I18n.
class I18n::Init

  # This module handles locales.
  module Locales
    include ConfigurationBlocks

    DEFAULT_LOCALE_RESCUE       = :en
    DEFAULT_LOCALE_NAME_RESCUE  = 'English'

    configuration_methods :locale=, :locale, :available_locale, :available_locales, :available_locales=,
                          :available_locale=, :available_locale_codes, :delete_language, :delete_locale,
                          :default_locale, :default_locale=, :default_language, :language_name,
                          :rtl_languages, :rtl_languages=

    # @override default_locale
    #   Gets the default locale.
    #   
    #   @return [Symbol] default locale
    # 
    # @override default_locale(locale_code)
    #   Sets the default locale.
    #   
    #   @note It will also set default locale name (language name) if it
    #    will find it in available languages and it hasn't been set already.
    #   
    #   @param locale_code [String,Symbol] locale
    #   @return [void]
    def default_locale(locale_code = nil)
      return (self.default_locale = locale_code) unless locale_code.nil?
      @default_locale_code
    end

    # Sets the default locale.
    # 
    # @param locale_code [String,Symbol] locale
    # @return [void]
    def default_locale=(locale_code)
      locale_code = { locale_code => nil } unless locale_code.is_a?(Hash)
      locale_code.each_pair do |code, name|
        @default_locale_code = code.blank? ? nil : code.to_sym
        @default_locale_name = name.blank? ? @available_languages[code.to_sym].presence : name.to_s
      end
      @default_locale_code
    end

    # Gets the language name of a default locale.
    # 
    # @param internal [Boolean] optional argument; if +false+ then external resolver is used on +I18n.default_locale+,
    #  if +true+ (default) then memorized value of the default locale name is returned.
    # @return [String] language name
    def default_language(internal = true)
      internal ? @default_locale_name : resolve_code(I18n.default_locale)
    end
    alias_method :default_language_name, :default_language

    # Gets the language name of current locale.
    #
    # @param internal [Boolean] optional argument; if +false+ then external resolver is used on +I18n.locale+,
    #  if +true+ (default) then memorized value of the locale name is returned.
    # @return [String] language name
    def language_name(internal = true)
      resolve_code(internal ? locale : I18n.locale)
    end
    alias_method :language, :language_name

    # Sets the initial locale that will be set on load.
    # 
    # @param locale_code [String,Symbol] locale
    # @return [Symbol] locale
    def locale=(locale_code)
      @locale = locale_code.present? ? locale_code.to_sym : nil
    end

    # @override locale
    #   Gets the initial locale that will be set on load.
    #   
    #   @param locale_code [String,Symbol] locale
    #   @return [Symbl] locale
    # 
    # @override locale(locale_code)
    #   Sets the initial locale that will be set on load.
    #   
    #   @param locale_code [String,Symbol] locale
    #   @return [Symbl] locale
    def locale(locale_code = nil)
      return (self.locale = locale_code) unless locale_code.nil?
      @locale
    end

    # fixme: override
    # Adds available language to available languages.
    # @param locale_code [String,Symbol] locale code (e.g. +:pl+)
    # @param language_name [String,Symbol] name of a language in its native language
    # @return [String,Hash] added language name or a hash of added languages
    def available_locale(*args)
      return @available_languages.keys if args.empty?
      args.each do |arg|
        next if arg.blank?
        unless arg.is_a?(Hash)
          arg = Array(arg).each_with_object({}){ |k,o| o[k] = nil }
        end
        arg.each_pair do |code, name|
          name = name.to_s unless name.nil?
          @available_languages[code.to_sym] = name
        end
      end
      nil
    end
    alias_method :available_locales,  :available_locale
    alias_method :available_language, :available_locale

    # Gets duplicate of available languages hash.
    def available_languages(internal = true)
      return @available_languages.dup if internal
      I18n.available_locales.each_with_object({}) do |l,o|
        l = l.to_sym
        o[l] = @available_languages[l]
      end
    end

    # Adds locale to available locales.
    # 
    # @return [nil]
    def available_locale=(arg)
      available_locales(arg)
    end
    alias_method :available_locales=, :available_locale=

    def rtl_languages=(languages)
      @rtl_languages = Array(languages)
    end

    def rtl_languages(languages = nil)
      return (self.rtl_languages = languages) unless languages.nil?
      @rtl_languages
    end

    # Gets the array containing strings of available locale codes.
    # 
    # @return [Array<String>] available locale codes
    def available_locale_codes
      available_locales.map { |l| l.to_s }
    end

    # Removes lanuage from available languages hash.
    # 
    # @param locale_code [String,Symbol] locale code (e.g. +:pl+)
    # @return [String] deleted language name
    def delete_language(locale_code)
      @available_languages.delete(locale_code.to_sym)
    end
    alias_method :delete_locale, :delete_language

    # Loads locale configuration from YAML files.
    # 
    # @return [nil]
    def load!(cfile = nil)

      setup_available_locales
      setup_default_locale
      setup_rtl_locale

      super if defined?(super)

      I18n.available_locales  = available_locales
      I18n.default_locale     = default_locale
      I18n.locale             = available_locales.include?(locale) ? locale : default_locale
    end

    # Lists available locales as a string.
    # 
    # @return []
    def list_available_locales(internal = true)
      src = internal ? available_locales : I18n.available_locales
      lj = src.max_by(&:length).length
      src.sort.each_with_object([]) do |c,o|
        o << "- #{c.to_s.ljust(lj)} (#{resolve_code(c)})"
      end.join(",\n  ")
    end

    private

    def normalize_available_locales(l)
      unless l.is_a?(Hash)
        l = Array(l).each_with_object({}){ |k,o| o[k] = nil }
      end
      l.each_with_object({}) do |(code, name), o|
        name = name.to_s unless name.nil?
        o[code.to_sym] = name
      end
    end

    def merge_available_locales(src, title)
      p_debug " - merging available locales from #{title}"
      @merged_available_languages = normalize_available_locales(src).merge(@merged_available_languages)
    end

    # Sets up available locales.
    def setup_available_locales
      p_debug "setting up available locales"
      from_framework  = settings_framework[:available_locales] || []
      from_file       = settings['available'] || []
      merge_available_locales(from_framework, "framework")
      merge_available_locales(from_file, "settings file")
      merge_available_locales(available_languages, "block")
      p_debug "fixing missing locale names"
      @merged_available_languages.each_pair do |code, name|
        name = resolve_code(code) if name.blank?
        @available_languages[code] = name.to_s
      end
      nil
    end

    # Sets up RTL locales.
    def setup_rtl_locale
      p_debug "setting up RTL locales"
      if settings['rtl'].present?
        @rtl_languages.concat(settings['rtl']).uniq!
      end
      nil
    end

    # Sets up default locale.
    def setup_default_locale
      p_debug "setting up default locale"
      if @default_locale_code.present?
        p_debug " - got default locale code: #{@default_locale_code}"
        @default_locale_name ||= @available_languages[@default_locale_code].presence
        @default_locale_name ||= @default_locale_code.to_s
      else # default locale code is missing
        p_debug " - default locale code is missing"
        @default_locale_code   = settings['default'].presence
        @default_locale_code &&= @default_locale_code
        if @default_locale_code.present? # default locale code given in file
          p_debug " - got default locale code from configuration file: #{@default_locale_code}"
          @default_locale_name ||=  @available_languages[@default_locale_code].presence
          @default_locale_name ||= @default_locale_code.to_s
        else # default locale not found in file and not given
          @default_locale_code ||= settings_framework[:default_locale]
          if @default_locale_code.present?
            @default_locale_code = @default_locale_code.to_s.to_sym
            p_debug " - default locale found in framework configuration"
            @default_locale_name ||= @available_languages[@default_locale_code].presence
          else
            p_debug " - default locale code is missing (not found in file and not given)"
            if @available_languages.present? && @available_languages.first.is_a?(Array) && @available_languages.first.count == 2
              @default_locale_code = @available_languages.first[0]
              @default_locale_name = @available_languages.first[1]
            end
            if @default_locale_code.blank?
              p_debug " - default locale code cannot be deduced, using defaults"
              @default_locale_code = DEFAULT_LOCALE_RESCUE
              @default_locale_name = DEFAULT_LOCALE_NAME_RESCUE
            else
              p_debug " - default locale code is present but name is empty"
              @default_locale_code = @default_locale_code.to_sym
            end
          end
        end
      end
      nil
    end

    # Resets buffers.
    def reset_buffers
      @available_languages  = {}
      @available_filter     = []
      @rtl_languages        = []
      @locale               = nil
      @default_locale_code  = nil
      @default_locale_name  = nil
      super if defined?(super)
    end

    # Invalidates caches.
    def invalidate_caches
      @merged_available_languages = {}
    end

    # Gathers framework configuration for later use.
    def gather_framework_info
      case framework
      when :Rails
        if Rails.configuration.respond_to?(:i18n)
          Rails.configuration.i18n.tap do |c|
            @framework_conf[:default_locale]    = c.default_locale
            @framework_conf[:available_locales] = c.available_locales
          end
        end
      end
      super if defined?(super)
    end

  end # module Locales
end # class I18n::Init
