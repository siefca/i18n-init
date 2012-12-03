# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.

require 'i18n'
require 'yaml'
require 'pathname'
require 'configuration-blocks'

require 'i18n-init/version'
require 'i18n-init/patches'
require 'i18n-init/core'
require 'i18n-init/integration'

if defined? ::Rails
  require 'i18n-init/railtie'
end
