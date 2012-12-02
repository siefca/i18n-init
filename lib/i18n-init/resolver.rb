# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
#
# This file contains I18n::Init::Resolver module.

# This class handles basic initial settings of I18n.
class I18n::Init

  # This module contains methods used to resolve locale names and locale codes.
  module Resolver
    include ConfigurationBlocks

    configuration_methods :resolve_code, :resolve_name

    # Resolves locale code.
    # 
    # @param [String,Symbol] locale code
    # @return [String] locale name
    def resolve_code(code)
      code.blank? ? nil : (resolver[code.to_sym].presence || code.to_s)
    end

    # Resolves name.
    # 
    # @param [String,Symbol] locale name
    # @return [String] locale code
    def resolve_name(name)
      name.blank? ? nil : (resolver_rev[name.to_s].presence || name.to_sym)
    end

    private

    # Returns resolver.
    def resolver
      @resolver_cache ||= {}.tap do |cache|
        p_debug "loading resolver data"
        [].tap do |srcs|
          srcs << locale_mappings_from_file(settings_bundled) unless settings['i18n-init-bundled']
          srcs << locale_mappings_from_file(settings)
          srcs << available_languages
          srcs.each do |src|
            src.each_pair do |code, name|
              cache[code] = name unless name.blank?
            end
          end
        end
      end
    end

    # Returns reverse resolver.
    def resolver_rev
      @resolver_cache_rev ||= @resolver_cache.invert
    end

    # Resets internal caches.
    def reset_resolver_caches
      p_debug "resetting resolver caches"
      @resolver_cache     = nil
      @resolver_cache_rev = nil
    end

    # Get locale mappings from settings file and return normalized version.
    def locale_mappings_from_file(settings_file)
      normalize_available_languages(settings_file['names'] || {})
    end

    # Normalizes available languages.
    def normalize_available_languages(input)
      input.each_with_object({}) do |(c,n), o|
        o[c.to_sym] = n.to_s unless c.blank?
      end
    end

    # Invalidates caches.
    def invalidate_caches
      reset_resolver_caches
      super if defined?(super)
    end

  end # module Resolver
end # class I18n::Init
  