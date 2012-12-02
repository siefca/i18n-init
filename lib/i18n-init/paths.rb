# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains module used to find and set paths.

# This class handles basic initial settings of I18n.
class I18n::Init

  # This module handles pathnames.
  module Paths
    include ConfigurationBlocks

    DEFAULT_CONFIG_FILE   = 'locale.yml'
    BUNDLED_SETTINGS_DIR  = 'skel'

    configuration_methods :root_path, :root_path=, :config_file, :config_file=,
                          :default_load_path, :default_load_path=,
                          :bundled_settings_file, :bundled_settings_dir

    # Returns framework's root path.
    # 
    # @return [String] path
    def root_path(name = nil)
      return (self.root_path = name) unless name.nil?
      @root_path or self.root_path = guess_root_path
    end

    # Sets root path.
    # 
    # @return [Pathname] pathname
    def root_path=(name)
      invalidate_caches
      @root_path = name.blank? ? nil : Pathname(name.to_s)
    end

    # Returns the config file path.
    # 
    # @return [String] path
    def config_file(name = nil)
      return (self.config_file = name) unless name.nil?
      @config_file or self.config_file = guess_config_file
    end

    # Sets the config file path.
    # 
    # @param name [String,Pathname] path
    def config_file=(name)
      invalidate_caches
      @config_file = name.blank? ? nil : Pathname(name.to_s)
    end

    # Reads the default load path.
    # 
    # @return [Pathname] path
    def default_load_path(name = nil)
      return (self.default_load_path = name) unless name.nil?
      @default_load_path ||= guess_load_path
    end
    alias_method :load_path, :default_load_path

    # Sets the default load path.
    # 
    # @return [Pathname] pathname
    def default_load_path=(name)
      @default_load_path = Pathname(name)
    end
    alias_method :load_path=, :default_load_path=

    # Gets the pathname of bundled settings file.
    # 
    # @return [Pathname] pathname
    def bundled_settings_file
      bundled_settings_dir_realpath.join(bundled_settings_filename)
    end

    # Returns a path to the irectory containing bundled settings file.
    # 
    # @return [Pathname] pathname
    def bundled_settings_dir
      Pathname(__FILE__).dirname.join('..', BUNDLED_SETTINGS_DIR)
    end

    # Returns a basename of a bundled settings file.
    # 
    # @return [Pathname] pathname
    def bundled_settings_filename
      DEFAULT_CONFIG_FILE
    end

    # Loads locale configuration from YAML files.
    # 
    # @return [nil]
    def load!(cfile = nil)
      self.config_file = cfile if cfile.present?
      super if defined?(super)
      I18n.load_path.concat Dir.glob(default_load_path)
    end

    private

    # Returns a path to the irectory containing bundled settings file.
    def bundled_settings_dir_realpath
      bundled_settings_dir.tap do |f|
        return f.executable? ? f.realpath : f.cleanpath
      end
    end

    # Guesses root path.
    def guess_root_path
      # Try framework-specific paths
      case framework
      when :Sinatra, :Padrino
        if framework == :Padrino
          return Pathname(Padrino.root) if Padrino.root.present?
          if Padrino.respond_to?(:settings) && Padrino.settings.respond_to?(:root)
            return Pathname(Padrino.settings.root)
          end
        end
        if defined?(Sinatra::Base.settings)
          if Sinatra::Base.settings.respond_to?(:root)
            Sinatra::Base.settings.root.tap do |r|
              return Pathname(r) if r.present?
            end
          elsif Sinatra::Base.settings.respond_to?(:app_file)
            Sinatra::Base.settings.app_file.tap do |r|
              return Pathname(r).dirname if r.present?
            end
          end
        end
      when :Merb
        return Pathname(Merb.root) if Merb.root.present?
      when :Rails
        return Rails.root if Rails.root.present?
      end
      # Try to localize root path by searching for known files
      Pathname(__FILE__).dirname.tap do |r|
        [ ['.'], ['..'], ['..', '..'], ['..', '..', '..'] ].each do |prefix|
          if ['app', 'config', 'dist', 'Gemfile'].any? { |d| File.exists?(r.join(*prefix, d)) }
            return r.join(*prefix)
          end
        end
        # Use current directory
        return r
      end
    end

    # Guesses configuration file path.
    def guess_config_file
      fname = bundled_settings_filename
      # Try framework-specific paths
      case framework
      when :Padrino, :Sinatra
        ['config', 'app', '.'].each do |dir|
          root_path.join(dir, fname).tap do |r|
            return r if File.readable?(r)
          end
        end
      when :Rails
        root_path.join('config', fname).tap do |r|
          return r if File.readable?(r)
        end
      when :Merb
        [ ['config'], ['conf'],
          ['dist', 'conf'],
          ['dist', 'config']
        ].each do |dirs|
          root_path.join(*dirs, fname).tap do |r|
            return r if File.readable?(r)
          end
        end
      end
      # Search known locations
      [ ['app', 'conf'],  ['app', 'config'],
        ['dist', 'conf'], ['dist', 'config'],
        ['config'], ['conf'], ['app'], ['.']
      ].each do |dirs|
        root_path.join(*dirs, fname).tap do |r|
          return r if File.readable?(r)
        end
      end
      # Return bundled settings
      bundled_settings_dir_realpath.join(fname).tap do |r|
        return r if File.exists?(r)
      end
      # Return root path + config file
      root_path.join(fname)
    end

    # Guesses load path.
    def guess_load_path
      globber = [ '**', '*.{rb,yml}' ]
      # Try framework-specific paths
      case framework
      when :Padrino, :Sinatra
        if defined?(Sinatra::Base.settings.locales)
          Sinatra::Base.settings.locales.tap do |r|
            if (r.is_a?(String) || r.is_a?(Pathname)) && File.exists?(r)
              Pathname(r).tap do |r|
                return (File.directory?(r) ? r : r.dirname).join(*globber)
              end
            end
          end
        end
        if framework == :Padrino
          [ ['app', 'locale'], ['app', 'locales'] ].each do |dirs|
            root_path.join(*dirs).tap do |r|
              if File.directory?(r)
                return r.join(*globber)
              end
            end
          end
        end
      when :Rails
        if File.directory?(root_path.join('config', 'locales'))
          return root_path.join('config', 'locales', *globber)
        end
      when :Merb
        if File.directory?(root_path.join('app', 'i18n'))
          return root_path.join('app', 'i18n', *globber)
        end
      end
      # Try other known locations
      [ ['config', 'locales'],  ['config', 'locale'],
        ['app', 'locale'],      ['app', 'locales'],
        ['app', 'i18n'],        ['app', 'l10n'],
        ['config', 'i18n'],     ['config', 'l10n'],
        ['i18n'], ['l10n'],     ['locale'], ['locales'],
        ['dist', 'conf', 'locale'],
        ['dist', 'conf', 'locales'],
        ['dist', 'conf', 'i18n'],
        ['dist', 'conf', 'l10n'],
        ['vendor', 'conf', 'locale'],
      ].each do |dirs|
        root_path.join(*dirs).tap do |r|
          if File.directory?(r)
            return r.join(*globber)
          end
        end
      end
      # Try config directory
      config_file.dirname.tap do |r|
        if File.directory?(r) && r.realpath != bundled_settings_dir_realpath
          return r.join(*globber)
        end
      end
      # Default to current directory and YAML files only
      root_path.join('*.yml')
    end

    # Resets buffers.
    def reset_buffers
      @default_load_path  = nil
      @config_file        = nil
      @root_path          = nil
      super if defined?(super)
    end

  end # module Paths

end # class I18n::Init
