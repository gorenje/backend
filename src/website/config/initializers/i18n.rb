require 'i18n'

I18n.load_path += Dir[File.join('config', 'locales', '*')]
I18n.default_locale = :en
