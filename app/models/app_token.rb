class AppToken < ActiveRecord::Base

  self.table_name = "app_tokens"

  def graph_api(access_token=nil)
    access_token = access_token || page_access_token || user_access_token
    @graph_api = Koala::Facebook::API.new(access_token)
  end
  
  def exchange_page_access_token(access_token)
    if !access_token
      raise "  AppToken#exchange_page_access_token access_token is null"
    end
    obj=FacebookAccount.where("is_active=1").last.send "object_name"
    page_token = graph_api(access_token).graph_call("v2.2/#{obj}?fields=access_token&access_token=#{access_token}")
    if page_token['access_token']
      self.page_access_token = page_token['access_token']
      self.save!
    else
      logger.info "  #{self.class.name} no page_access_token"
    end
  end
    
end
=begin 

  def token?
    !!page_access_token
  end
  
  def debug_token
    if token?
      'never'
    else
      'N/A'
    end
  end
=end

