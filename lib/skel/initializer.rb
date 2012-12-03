# I18n initialization

if defined?(I18n.init)

  # Uncomment the line below to early enable debugging of I18n lookups and initialization process.
  # (Alternatively you can set I18N_DEBUG environment variable.)

  #I18n.init.debug!

  # I18n configuration block.
  # Use it if the static configuration file config/locale.yml doesn't give you enough power.
  # 
  # Settings placed here will:
  # * override I18n configuration settings from Rails configuration,
  # * override I18n configuration settings from locale.yml file.
  # 
  # If the config/locale.yml file is missing then bundled locale.yml will be used. 
  # Settings that are collections will not be overridden but merged (backends, fallbacks, avaliable_locales).
  # 
  # (See I18n::Init documentation for information about all possible configuration keywords.)

  #I18n.init do
    # add_backend :Fallbacks
    # add_backend :Pluralization
    # available_locales :de, :en, :fr, :pl
    # default_locale    :en
    # default_fallback  :en
  #end

end
