# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
#
# This file contains I18n::Init::Block module used to dynamically create anonymous proxy modules.

require 'singleton'

# This class handles basic initial settings of I18n.
class I18n::Init

  # This module installs configuration block processing module
  # and its proxy methods.
  module ConfBlock

    # @private
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Returns configuration module.
    # 
    # @return [Module] anonymous module with proxy module methods
    def configuration_block
      self.class.conf_module
    end

    def configuration_block_delegated
      self.class.configuration_block_delegated
    end

    # This module contains methods that will extend the class.
    module ClassMethods

      # This method creates and returns anonymous module containing
      # delegators that point to methods from a class this module is included in.
      # 
      # @return [Module] anonymous module with proxy module methods
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

      # This is DSL method intended to be used in a class to indicate which methods
      # should be delegated from anonymous proxy module available when {conf_module} class method
      # is called.
      # 
      # @param methods [Array<Symbol>] list of method names
      # @return [nil]
      def configuration_block_delegate(*methods)
        @cf_block_delegators ||= []
        @cf_block_delegators.concat(methods)
        nil
      end
      alias_method :configuration_method, :configuration_block_delegate
      alias_method :settings_method,      :configuration_block_delegate

      def configuration_block_delegated
        @cf_block_delegators.dup
      end

    end # module ClassMethods

  end # module ConfBlock
end # class I18n::Init
