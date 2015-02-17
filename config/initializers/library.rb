require 'authentication'

EMAIL_SETTINGS = YAML::load(
  File.open("#{Rails.root.to_s}/config/email.yml")
  )[Rails.env]
unless EMAIL_SETTINGS.nil?
  ActionMailer::Base.smtp_settings = 
     EMAIL_SETTINGS
end

