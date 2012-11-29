# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
#
# This file contains I18n::Init::Backends module.

# This class handles basic initial settings of I18n.
class I18n::Init

  # This module handles backends.
  module Backends

    # Includes backend of a given name to simple backend.
    # 
    # @param name [String, Symbol, Module] name of a backend from +I18n::Backend+ or backend module object.
    # @return [nil]
    def add_backend(b_name)
      if b_name.is_a?(Module)
        name_f = b_name.name.split(':').last.downcase
      else
        name_f = b_name.to_s
        b_name = I18n::Backend.const_get(name_f)
      end
      @backends[name_f] = b_name
      nil
    end
    alias_method :add_backend=, :add_backend
    alias_method :new_backend=, :add_backend

    # Initializes I18n Init.
    # 
    # @return [nil]
    def load!(cfile = nil)
      p_debug "loading backends [#{@backends.keys.map{|n|n.capitalize}.join(', ')}]"
      @backends = backends_merged
      @backends.each_pair do |b_name, b_module|
        unless I18n.backend.class.included_modules.include?(b_module)
          require "i18n/backend/#{b_name}" rescue nil
          I18n.backend.class.send(:include, b_module)
        end
      end
      super if defined?(super)
    end

    private

    def backends_merged
      @backends_merged ||= backends_from_file.merge(@backends).tap { p_debug "merging backends" }
    end

    def backends_from_file
      @backends_from_file ||= Array(settings['backends']).uniq.each_with_object({}) do |b_name, o|
        b_name = b_name.to_s
        o[b_name] = I18n::Backend.const_get(b_name)
      end 
    end

    # Resets buffers.
    def reset_buffers
      @backends = {}
      super if defined?(super)
    end

    # Invalidates cached settings based on configuration file contents.
    def invalidate_caches
      @backends_merged = nil
      @backends_from_file = nil
      super if defined?(super)
    end

  end # module Backends
end # class I18n::Init
