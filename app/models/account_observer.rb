# observe model related events
class AccountObserver < ActiveRecord::Observer
  def after_create(account)
    # not in use
    if account.media_type_name == '__FacebookAccount'
      conf = YAML::load_file(File.join(Rails.root.to_s, 'config/facebook.yml'))
      ['development','production'].each do |env|
        uri = URI.parse conf[env]['canvas_url']
        rec = AppToken.find_or_create_by account_id: account.id, canvas_url: "#{uri.host}"
      end
    end
  end
  
  def after_destroy(account)
    # account.app_token.each{|z| z.destroy}
  end
  
end

