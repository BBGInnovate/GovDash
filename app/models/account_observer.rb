# observe model related events
class AccountObserver < ActiveRecord::Observer
  def after_create(account)
    if account.media_type_name == 'FacebookAccount'
      conf = YAML::load_file(File.join(Rails.root.to_s, 'config/facebook.yml'))
      ['development','production'].each do |env|
        uri = URI.parse conf[env]['canvas_url']
        rec = ApiToken.find_or_create_by account_id: account.id, canvas_url: "#{uri.host}"
      end
    end
  end
  
  def after_destroy(account)
    account.api_tokens.each{|z| z.destroy}
  end
  
end

