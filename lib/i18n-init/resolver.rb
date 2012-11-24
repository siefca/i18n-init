# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
#
# This file contains I18n::Init::Resolver module.

# This class handles basic initial settings of I18n.
class I18n::Init

  # This module contains methods used to resolve locale names and locale codes.
  module Resolver

    # Resolves locale code.
    # 
    # @param [String,Symbol] locale code
    # @return [String] locale name
    def resolve_code(code)
      code.blank? ? nil : (resolver[code.to_s].presence || code.to_s)
    end

    # Resolves name.
    # 
    # @param [String,Symbol] locale name
    # @return [String] locale code
    def resolve_name(name)
      name.blank? ? nil : (resolver_rev[name.to_s].presence || name.to_s)
    end

    private

    # Returns resolver.
    def resolver
      @resolver_cache ||= {}.tap do |cache|
        p_debug "loading resolver data"
        [].tap do |srcs|
          srcs << (settings_bundled['available'] || {}) unless settings['i18n-init-bundled']
          srcs << (settings['available'] || {})
          srcs << available_locales
          srcs.each do |src|
            src.each_pair do |code, name|
              cache[code.to_s] = name.to_s unless name.blank?
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
      @resolver_cache     = nil
      @resolver_cache_rev = nil
    end

    # Invalidates caches.
    def invalidate_caches
      p_debug "invalidating caches"
      reset_resolver_caches
      super if defined?(super)
    end

  end # module Resolver
end # class I18n::Init
  