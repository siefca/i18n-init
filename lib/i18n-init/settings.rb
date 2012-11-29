# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: (c) 2012 by Paweł Wilk
# License::   This program is licensed under the terms of {file:LGPL-LICENSE GNU Lesser General Public License} or {file:COPYING Ruby License}.
# 
# This file contains module used to handle settings.

# This class handles basic initial settings of I18n.
class I18n::Init

  # This module handles settings.
  module Settings

    # Loads settings if needed and returns settings hash.
    # Uses environment section if environment is set and a corresponding section
    # is present in YAML file.
    # 
    # @return [Hash] settings
    def settings
      @settings ||= yaml_load(config_file).tap do |s|
        if s.is_a?(Hash) && environment.present? && s.has_key?(environment)
          p_debug "switching to environment section: #{environment}"
          break s[environment]
        end
      end || {}
    end

    # Loads bundled settings (if needed) and returns settings hash.
    # 
    # @return [Hash] settings
    def settings_bundled
      return @settings_bundled unless @settings_bundled.blank?
      @settings_bundled = yaml_load(bundled_settings_file)
    end

    def settings_framework
      if ignore_framework_settings?
        p_debug_once "ignoring framework settings"
        return {}
      end
      @framework_conf ||= {}
    end
    private

    # Loads settings from YAML file.
    def yaml_load(fname)
      return {} unless File.exists?(fname)
      p_debug "reading settings from file: #{fname}"
      File.open(fname).tap { |f| return YAML::load(f).tap{ f.close } || {} }
    end

    # Invalidates cached settings based on configuration file contents.
    def invalidate_caches
      @settings = nil
      @settings_bundled = nil
      super if defined?(super)
    end

  end # module Settings

end # class I18n::Init
