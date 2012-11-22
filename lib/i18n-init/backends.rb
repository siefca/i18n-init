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
        b_name = b_name.to_s
        name_f = b_name
        b_name = I18n::Backend.const_get(b_name)
      end
      require "i18n/backend/#{name_f}" rescue nil
      I18n::Backend::Simple.send(:include, b_name)
      nil
    end
    alias_method :add_backend=, :add_backend
    alias_method :new_backend=, :add_backend

  end # module Backends
end # class I18n::Init
