# I18n initialization

if defined?(I18n.init)

  # I18n configuration block.
  # Use it if you need more power than static configuration defined in the locale.yml file.
  # 
  # Settings placed here will:
  # * override I18n configuration settings from Rails configuration,
  # * override I18n configuration settings from locale.yml file.
  # 
  # If the locale.yml file is missing then bundled locale.yml will be used. 
  # Settings that are collections will not be overriden but merged (backends, fallbacks, avaliable_locales).
  # 
  # See I18n::Init documentation for information about all possible keywords.

  I18n.init do
    # add_backend :Fallbacks
    # add_backend :Pluralization
    # available_locales :de, :en, :fr, :pl
    # default_locale    :en
    # default_fallback  :en
  end

end
