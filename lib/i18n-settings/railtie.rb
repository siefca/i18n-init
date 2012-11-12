# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file loads I18n Init goodies into Rails.

require 'i18n-init'
require 'rails'

# @abstract This namespace is shared with I18n.
module I18n
  class Init
    # This class is a glue that allows us to integrate with Rails.
    class Railtie < ::Rails::Railtie

      config.after_initialize do
        ::Rails.configuration.locale_init = I18n.init
      end

    end # class Railtie
  end # class Init
end # module I18n
