class ApiToken < ActiveRecord::Base
  
  belongs_to :facebook_account, :foreign_key=>'account_id'
  belongs_to :twitter_account, :foreign_key=>'account_id'
  
  def graph_api(access_token=nil)
    access_token = access_token || page_access_token || user_access_token
    @graph_api = Koala::Facebook::API.new(access_token)
  end
  
  def exchange_page_access_token(access_token=nil)
    token = access_token || user_access_token
    begin
      page_token = graph_api(access_token).graph_call("v2.0/#{self.facebook_account.send(:obj_name)}?fields=access_token&access_token=#{token}")
      if page_token['access_token']
        self.update_attribute :page_access_token, page_token['access_token']
      else
        self.update_attribute :user_access_token, access_token if access_token
        logger.info "ApiToken: #{self.canvas_url} : #{self.facebook_account.object_name} : no page_token['access_token']"
      end
    rescue Exception=>error
      logger.error error.message
    end
  end
  
  def token?
    !!page_access_token
  end
  
  def debug_token
    if token?
      'never'
    else
      'N/A'
    end
=begin    
    token = self.page_access_token # || self.user_access_token
    if token
      end_point = "v2.1/debug_token?input_token=#{token}&access_token=#{token}"
      re = graph_api.graph_call end_point
      expiry = re['data']['expires_at']
      if expiry == 0
        'never'
      else
        expiry = (Time.at(expiry) - Time.zone.now) / 3600 
        "in about #{exp.to} hours"
      end
    else
      'N/A'
    end
=end
  end
  
  def self.populate
    options = []

    opt = {platform: 'Facebook', 
           api_user_email: 'odditech@bbg.gov',
           canvas_url: 'ads.localhost.com'}
    #       client_id: '518623351606222',
    #       client_secret: '88ff19899a43c5ec997039975e251427'}
    
    options << opt

    opt = {platform: 'Facebook', 
           api_user_email: 'ads@bbg.gov',
           canvas_url: 'ads.localhost.com'}
    
    options << opt
    opt = {platform: 'Facebook', 
           api_user_email: 'oddidev@bbg.gov',
           canvas_url: 'smdata.bbg.gov'}
           
           # client_id: '762515890447080',
           # client_secret: 'f89517ad8f0118032e3323da04a11249'}
    options << opt
    
    accounts = FacebookAccount.all
    accounts.each do | account |
      options.each do |op|
        op[:account_id] = account.id
        if !!account.page_access_token
          # op[:page_access_token] = account.page_access_token
        else
          op.delete :page_access_token
        end
        rec = self.find_or_create_by op
        if account.page_access_token
        #  rec.update_attribute :page_access_token,account.page_access_token
        end
      end
    end

  end
  
end
