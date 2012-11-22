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
    def settings
      return @settings unless @settings.blank?
      @settings = yaml_load(config_file)
    end

    def settings_bundled
      return @settings_bundled unless @settings_bundled.blank?
      @settings_bundled = yaml_load(bundled_settings_file)
    end

    private

    # Loads settings from YAML file.
    def yaml_load(fname)
      return {} unless File.exists?(fname)
      File.open(fname).tap { |f| return YAML::load(f).tap{ f.close } || {} }
    end

    # Invalidates cached settings based on configuration file contents.
    def invalidate_caches
      @settings = nil
      super if defined?(super)
    end

  end # module Settings

end # class I18n::Init
