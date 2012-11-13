# encoding: utf-8
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains +init+ and +init!+ module methods for I18n.

# @abstract This namespace is shared with I18n.
module I18n
  # Basic settings object for I18n quick setup.
  # @return [Init] settings object
  def init(&block)
    block_given? ? Init.instance.config(&block) : Init.instance  
  end
  module_function :init

  # Initializes I18n with prepared settings.
  def init!
    init.load!
  end
  module_function :init!

  # Enables debugging of I18n lookups.
  def debug!
    init.debug!
  end
  module_function :debug!

  # Returns available languages hash.
  # @return [Hash{String => String}] available language codes and their names.
  def available_languages
    init.available_languages
  end
  module_function :available_languages

  def available_locales
    init.available_locales
  end
  module_function :available_locales
 
end
