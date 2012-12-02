# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains Rails generator used to generate locale settings file and locale settings initializer.

require 'bundler'
require 'rails/generators'
require 'rails/generators/base'

require 'i18n-init'

class I18n::Init
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Installs I18n Init default configuration files"
      source_root I18n.init.bundled_settings_dir
      
      def copy_initializers
        copy_file initializer_file_src, initializer_file_dst
        copy_file settings_file_src,    settings_file_dst
        gsub_file settings_file_dst,    %r|# Marker that tells engine that this file is bundled with the .*|, ''
        #gsub_file settings_file_dst,    %r|i18n-init-bundled: true|, ''
      end

      private

      def initializer_file_dst
        File.join("config", "initializers", "locale.rb")
      end

      def initializer_file_src
        "initializer.rb"
      end

      def settings_file_src
        I18n.init.bundled_settings_filename
      end

      def settings_file_dst
        File.join("config", settings_file_src)
      end

    end # class InstallGenerator
  end # module Generators
end # class I18n::Init
