# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains Rails generator used to generate locale settings file and locale settings initializer.

require 'bundler'
require 'tempfile'
require 'rails/generators'
require 'rails/generators/base'

require 'i18n-init'

# This module contains Rails generators.
module I18nInit
  module Generators
    class InstallGenerator < Rails::Generators::Base

      desc "Installs I18n Init default configuration files"
      source_root I18n.init.bundled_settings_dir

      def copy_initializers
        copy_file           initializer_file_src, initializer_file_dst
        copy_settings_file  settings_file_src,    settings_file_dst 
      end

      private

      def copy_settings_file(src_name, dst_name)
        tmp_name = File.basename(src_name.to_s)
        src_name = File.expand_path(find_in_source_paths(src_name.to_s))
        templ = Tempfile.open(tmp_name)
        templ.write File.read(src_name)
        templ.close
        gsub_file templ.path, %r|# Marker that tells the engine that this file is bundled with the .*|, '',  :verbose => false
        gsub_file templ.path, %r|i18n-init-bundled: true|, '', :verbose => false
        copy_file templ.path, dst_name
        templ.close unless templ.closed?
        templ.unlink
      end

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
end # module I18nInit
