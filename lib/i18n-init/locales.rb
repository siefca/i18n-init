# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains module used to find and set paths.

# This class handles basic initial settings of I18n.
class I18n::Init

  # This module handles locales.
  module Locales

    DEFAULT_LOCALE_RESCUE       = :en
    DEFAULT_LOCALE_NAME_RESCUE  = 'English'

    # Sets the default locale.
    # 
    # @note It will also set default locale name (language name) if it
    #  will find it in available languages and it hasn't been set already.
    # 
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
    # 
    # @param internal [Boolean] optional argument; if +false+ then external resolver is used on +I18n.default_locale+,
    #  if +true+ (default) then memorized value of the default locale name is returned.
    # @return [String] language name
    def default_language(internal = true)
      internal ? @default_locale_name : resolve_code(I18n.default_locale)
    end
    alias_method :default_language_name, :default_language

    # Gets the language name of current locale.
    def language_name(internal = true)
      resolve_code(internal ? locale : I18n.locale)
    end
    alias_method :language, :language_name

    # Sets the initial locale that will be set on load.
    # 
    # @param locale_code [String,Symbol] locale
    # @return [Symbl] locale
    def locale=(locale_code)
      @locale = locale_code.to_sym
    end

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
          @available_filter.concat(Array(arg).map(&:to_s))
        end
      end # args.each
      nil
    end
    alias_method :available_locales,  :available_locale
    alias_method :available_language, :available_locale
    alias_method :pick_locales,       :available_locale
    alias_method :pick_locale,        :available_locale

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

    def rtl_languages=(languages)
      @rtl_languages = languages
    end

    def rtl_languages(languages = nil)
      return (self.rtl_languages = languages) unless languages.nil?
      @rtl_languages ||= []
    end

    # Gets the array containing strings of available locale codes.
    # 
    # @return [Array<String>] available locale codes
    def available_locale_codes
      available_locales.keys.map { |l| l.to_s }
    end

    # Removes lanuage from available languags hash.
    # 
    # @param locale_code [String,Symbol] locale code (e.g. +:pl+)
    # @return [String] deleted language name
    def delete_language(locale_code)
      @available_locales.delete(locale_code.to_s)
    end
    alias_method :delete_locale,  :delete_language
    alias_method :del_language,   :delete_language
    alias_method :del_locale,     :delete_language

    # Loads locale configuration from YAML files.
    # 
    # @return [nil]
    def load!(cfile = nil)

      setup_available_locales
      setup_default_locale
      setup_rtl_locale
      remove_unwanted_locales
      fix_missing_locale_names

      super if defined?(super)

      I18n.available_locales  = available_locales.keys
      I18n.default_locale     = default_locale
      I18n.locale             = available_locales.key?(locale.to_s) ? locale : default_locale
    end

    # Lists available locales as a string.
    # 
    # @return []
    def list_available_locales
      lj = available_locales.keys.max_by(&:length).length
      Hash[available_languages.sort].each_with_object([]) do |(c,n),o|
        o << "- #{c.to_s.ljust(lj)} (#{n})"
      end.join(",\n  ")
    end

    private

    # Sets up available locales.
    def setup_available_locales
      from_file = settings['available'] || {}
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
      p_debug "fixing missing locale names"
      @available_locales.each_pair do |code, name|
        if name.blank?
          @available_locales[code] = resolve_code(code)
        end
      end
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
        @default_locale_name ||= @available_locales[@default_locale_code.to_s].presence
        @default_locale_name ||= @default_locale_code.to_s
      else # default locale code is missing
        p_debug " - default locale code is missing"
        @default_locale_code   = settings['default'].presence
        @default_locale_code &&= @default_locale_code.to_sym
        if @default_locale_code.present? # default locale code given in file
          p_debug " - got default locale code from configuration file: #{@default_locale_code}"
          @default_locale_name ||=  @available_locales[@default_locale_code.to_s].presence
          @default_locale_name ||= @default_locale_code.to_s
        else # default locale not found in file and not given
          @default_locale_code ||= @framework_conf[:default_locale]
          if @default_locale_code.present?
            @default_locale_code = @default_locale_code.to_s.to_sym
            p_debug " - default locale found in framework configuration"
            @default_locale_name ||= @available_locales[@default_locale_code.to_s].presence
          else
            p_debug " - default locale code is missing (not found in file and not given)"
            if @available_locales.present? && @available_locales.first.is_a?(Array) && @available_locales.first.count == 2
              @default_locale_code = @available_locales.first[0]
              @default_locale_name = @available_locales.first[1]
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
      p_debug "resetting buffers"
      @available_locales        = {}
      @available_filter         = []
      @rtl_languages            = []
      @locale                   = nil
      @default_locale_code      = nil
      @default_locale_name      = nil
    # Gathers framework configuration for later use.
    def gather_framework_info
      p_debug "reading framework configuration"
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
