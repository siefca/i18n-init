# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains module used to handle settings.

# This class handles basic initial settings of I18n.
class I18n::Init

  # This module handles reading settings from files and framework configurations.
  module Settings
    include ConfigurationBlocks

    configuration_methods :ignore_settings_file!, :ignore_bundled_settings!,  :ignore_framework_settings!,
                          :ignore_settings_file?, :ignore_bundled_settings?,  :ignore_framework_settings?,
                          :ignore_settings_file=, :ignore_bundled_settings=,  :ignore_framework_settings=,
                          :ignore_settings_file,  :ignore_bundled_settings,   :ignore_framework_settings

    # Loads settings from file and returns settings hash.
    # Uses environment section if environment is set and a corresponding section
    # is present in YAML file.
    # 
    # @return [Hash] settings
    def settings
      if ignore_settings_file?
        p_debug_once "ignoring settings file"
        return {}
      end
      @settings ||= yaml_load(config_file).tap do |s|
        if s.is_a?(Hash) && environment.present? && s.has_key?(environment)
          p_debug "switching to environment section: #{environment}"
          break s[environment]
        end
        caches_dirty!
      end || {}
    end

    # Loads bundled settings (if needed) and returns settings hash.
    # 
    # @return [Hash] settings
    def settings_bundled
      if ignore_bundled_settings?
        p_debug_once "ignoring bundled settings"
        return {}
      end
      return @settings_bundled unless @settings_bundled.blank?
      @settings_bundled = yaml_load(bundled_settings_file).tap { caches_dirty! }
    end

    # Gets memorized I18n settings obtained from framework configuration.
    # 
    # @return [Hash] settings
    def settings_framework
      if ignore_framework_settings?
        p_debug_once "ignoring framework settings"
        return {}
      end
      framework_conf
    end

    # Sets a flag that if +true+ causes settings file to be ignored.
    # 
    # @param v [Boolean] flag status
    # @return [Boolean] current status
    def ignore_settings_file=(v)
      @ignore_settings_file = !!v
    end

    # Sets a flag that if +true+ causes bundled settings file to be ignored.
    # 
    # @param v [Boolean] flag status
    # @return [Boolean] current status
    def ignore_bundled_settings=(v)
      @ignore_bundled_settings = !!v
    end

    # Sets a flag that if +true+ causes framework settings to be ignored.
    # 
    # @param v [Boolean] flag status
    # @return [Boolean] current status
    def ignore_framework_settings=(v)
      @ignore_framework_settings = !!v
    end

    # Tests if settings file is ignored.
    # 
    # @return [Boolean] +true+ if ignored, +false+ otherwise
    def ignore_settings_file?
      @ignore_settings_file
    end

    # Tests if budled settings file is ignored.
    # 
    # @return [Boolean] +true+ if ignored, +false+ otherwise
    def ignore_bundled_settings?
      @ignore_bundled_settings
    end

    # Tests if framework settings are ignored.
    # 
    # @return [Boolean] +true+ if ignored, +false+ otherwise
    def ignore_framework_settings?
      @ignore_framework_settings
    end

    # Sets a flag that causes settings from file to be ignored.
    # 
    # @return [Boolean] +true+
    def ignore_settings_file!
      self.ignore_settings_file = true
    end

    # Sets a flag that causes settings from bundled file to be ignored.
    # 
    # @return [Boolean] +true+
    def ignore_bundled_settings!
      self.ignore_bundled_settings = true
    end

    # Sets a flag that causes framework settings to be ignored.
    # 
    # @return [Boolean] +true+
    def ignore_framework_settings!
      self.ignore_framework_settings = true
    end

    # @override ignore_settings_file
    #   Gets current status of settings file ignorance flag.
    #   @return [Boolean] +true+ if settings from file are ignored, +false+ otherwise
    # @override ignore_settings_file(v)
    #   Sets a flag that causes settings read from file to be ignored.
    #   @param v [Boolean] flag status
    #   @return [Boolean] current flag status
    def ignore_settings_file(*args)
      case args.count
      when 0
        ignore_settings_file?
      when 1
        self.ignore_settings_file = args.first
      else
        raise ArgumentError, "wrong number of arguments (#{args.count} for 1)"
      end
    end

    # @override ignore_bundled_settings
    #   Gets current status of bundled settings ignorance flag.
    #   @return [Boolean] +true+ if settings from bundled file are ignored, +false+ otherwise
    # @override ignore_bundled_settings(v)
    #   Sets a flag that causes bundled settings to be ignored.
    #   @param v [Boolean] flag status
    #   @return [Boolean] current flag status
    def ignore_bundled_settings(*args)
      case args.count
      when 0
        ignore_bundled_settings?
      when 1
        self.ignore_bundled_settings = args.first
      else
        raise ArgumentError, "wrong number of arguments (#{args.count} for 1)"
      end
    end

    # @override ignore_framework_settings
    #   Gets current status of framework settings ignorance flag.
    #   @return [Boolean] +true+ if settings from framework file are ignored, +false+ otherwise
    # @override ignore_framework_settings(v)
    #   Sets a flag that causes framework settings to be ignored.
    #   @param v [Boolean] flag status
    #   @return [Boolean] current flag status
    def ignore_framework_settings(*args)
      case args.count
      when 0
        ignore_framework_settings?
      when 1
        self.ignore_framework_settings = args.first
      else
        raise ArgumentError, "wrong number of arguments (#{args.count} for 1)"
      end
    end

    private

    # Loads settings from YAML file.
    def yaml_load(fname)
      return {} unless File.exists?(fname)
      p_debug "reading settings from file: #{fname}"
      File.open(fname).tap { |f| return YAML::load(f).tap{ f.close } || {} }
    end

    # Memorizes framework-related configuration in early stage of initialization.
    def framework_conf
      return @framework_conf if @framework_conf
      p_debug "gathering framework info"
      @framework_conf = {}
      super if defined?(super)
      @framework_conf
    end

    # Invalidates cached settings based on configuration file contents.
    def invalidate_caches
      @settings = nil
      @settings_bundled = nil
      super if defined?(super)
    end

    # Resets buffers.
    def reset_buffers
      @ignore_settings_file       = false
      @ignore_bundled_settings    = false
      @ignore_framework_settings  = false
      @framework_conf             = nil
      super if defined?(super)
    end

    # Gets some info about settings used.
    def settings_info
      [].tap do |r|
        unless ignore_framework_settings? || framework == :unknown
          r << "#{framework} configuration#{' (empty)' if settings_framework.blank?}"
        end
        unless ignore_settings_file? || config_file.blank?
          rr = ""
          rr << config_file.basename.to_s
          if settings.blank?
            rr << " (empty)"
          elsif settings['i18n-init-bundled']
            rr << " (bundled)"
          end
          r << rr
        end
        if configuration_block_used?
          r << "configuration block"
        end
      end.join(', ')
    end

  end # module Settings

end # class I18n::Init
