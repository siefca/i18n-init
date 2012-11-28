# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
#
# This file contains I18n::Init::Block module.

require 'singleton'

# This class handles basic initial settings of I18n.
class I18n::Init

  # This module installs configuration block processing module
  # and its proxy method.
  module ConfBlock

    def self.included(base)
      base.extend(ClassMethods)
    end

    def conf_block
      self.class.conf_module
    end

    module ClassMethods
      def conf_module
        @conf_module ||= Module.new.tap do |cm|
          instance.p_debug "creating anonymous proxy module for evaluating configuration block"
          delegators = @cf_block_delegators.uniq
          instance.p_debug " - installing delegators"
          base = self.instance
          cm.extend Module.new {
            delegators.each do |method|
              module_eval do
                define_method(method) do |*args|
                  base.public_send(method, *args)
                end
              end
            end
          }
        end
      end

      def configuration_block_delegate(*methods)
        @cf_block_delegators ||= []
        @cf_block_delegators.concat(methods)
      end
    end # module ClassMethods

  end # module ConfBlock
end # class I18n::Init
