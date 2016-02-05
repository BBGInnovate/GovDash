unless defined? YoutubeConf
  YoutubeConf = Rails.application.config_for("youtube").symbolize_keys
end

Yt.configure do |config|
  config.api_key = YoutubeConf[:api_key]
  config.log_level = :debug
end

