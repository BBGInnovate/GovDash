require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, :assets, Rails.env)

module Radd
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.autoload_paths += %W(#{config.root}/lib)
    
    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    config.to_prepare do
      DeviseController.respond_to :html, :json
    end

    config.active_record.schema_format = :ruby

    I18n.config.enforce_available_locales = false
    
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.perform_deliveries = false
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.default_url_options = {:host => 'localhost' }
=begin 
    config.action_mailer.smtp_settings = {:address => "email-smtp.us-east-1.amazonaws.com",
    :port=>587,
    :domain=>'amazonaws.com',
    :authentication => :login,
    :user_name=> '',
    :password=> '',
    :enable_starttls_auto=>true}
=end
   
    config.active_record.observers = :error_log_observer,:account_observer
=begin  
  IAM User Name : oddidev.bbg
  When you are in the sandbox, your sending quota is 200 messages per 24-hour period and
  your maximum sending rate is one message per second. 
  To increase your sending limits, you need to request production access. 
  For more information, see Requesting Production Access to Amazon SES. 
  After you request production access and start sending emails, 
  you can increase your sending limits further by following the guidance in 
  the Increasing Your Amazon SES Sending Limits section.
  Email messages are charged at $0.10 per thousand
=end
  end
end
