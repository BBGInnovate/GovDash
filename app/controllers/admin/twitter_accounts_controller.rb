require 'json'

class Admin::TwitterAccountsController < Admin::AccountsController
  active_scaffold :twitter_account do |config|
    config.actions = [:list, :show, :update]
    
    config.update.refresh_list = true
   
    config.columns = Account.columns.map{|a| a.name} | [:regions,:countries]
    config.list.columns.exclude :name,:is_active,:user_access_token,:page_access_token,  :description,:account_type_id,
       :client_id, :client_secret,:canvas_url,:created_at,
       :updated_at,:page_admin,:contact,
       :sc_segment_id
  
    config.update.columns.exclude :id

  end
end
