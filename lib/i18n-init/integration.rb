# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains +init+ and +init!+ module methods for I18n.

# @abstract This namespace is shared with I18n.
module I18n

  extend Module.new {
    # Define methods that delegate to init object.
    %w(init! debug! initialized? rtl_locales print_info info).each do |method|
      module_eval <<-DELEGATORS, __FILE__, __LINE__ + 1
        def #{method}
          init.#{method}
        end
      DELEGATORS
    end

    def language
      init.language(false)
    end

    def default_language
      init.default_language(false)
    end

    def available_languages
      init.available_languages(false)
    end

    def locale_to_language(code)
      init.resolve_code(code)
    end

    def language_to_locale(name)
      init.resolve_name(name)
    end

    # Basic settings object for I18n quick setup.
    # 
    # @return [Init] settings object
    def init(&block)
      block_given? ? Init.instance.config(&block) : Init.instance
    end

    # Returns +true+ if locale is included in available locales.
    # 
    # @return [Boolean] +true+ if available, +false+ otherwise
    def locale_available?(locale_code)
      I18n.available_locales.include?(locale_code.to_sym)
    end
    alias_method :available_locale?, :locale_available?

    # Returns +true+ if locale is a default locale.
    # 
    # @return [Boolean] +true+ if locale is a default locale, +false+ otherwise
    def locale_default?(locale_code)
      I18n.default_locale.to_sym == locale_code.to_sym
    end
    alias_method :default_locale?, :locale_default?
  }
end
