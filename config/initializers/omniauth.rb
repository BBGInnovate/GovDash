unless defined? YoutubeConf
  YoutubeConf = Rails.application.config_for("youtube").symbolize_keys
end

conf_file='client_secrets.json'
GoogleClient = Google::APIClient::ClientSecrets.load "config/#{conf_file}"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, GoogleClient.client_id, GoogleClient.client_secret, {
    :scope => YoutubeConf[:scope],
    :prompt => "select_account",
    :approval_prompt => 'auto',
    :image_aspect_ratio => "square",
    :image_size => 50,
    :include_granted_scopes => false,
    :access_type => 'offline'
  }
end
