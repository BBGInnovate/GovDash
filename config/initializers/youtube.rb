YoutubeConf = 
  YAML.load_file("#{Rails.root}/config/youtube.yml")[Rails.env].symbolize_keys

Yt.configure do |config|
  config.api_key = YoutubeConf[:api_key]
  config.log_level = :debug
end

