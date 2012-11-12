# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
#
# This file contains patches that add blank?, present? and presence methods to Object class if not defined before.

# @abstract
class Object
  unless method_defined?(:blank?)
    # @private
    def blank?; respond_to?(:empty?) ? empty? : !self end
  end
  unless method_defined?(:present?)
    # @private
    def present?; !blank? end
  end
  unless method_defined?(:presence)
    # @private
    def presence; self if present? end
  end
end
