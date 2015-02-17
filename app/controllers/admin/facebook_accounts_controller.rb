require 'json'

class Admin::FacebookAccountsController < Admin::AccountsController
  active_scaffold :facebook_account do |config|
    config.actions = [:list, :show, :update]
    config.update.refresh_list = true
   
    config.columns = Account.columns.map{|a| a.name} | [:regions,:countries]
    # config.columns = []
    config.list.columns.exclude :name,:is_active,:user_access_token,:page_access_token,  :description,:account_type_id,
       :client_id, :client_secret,:canvas_url,:created_at,
       :updated_at,:page_admin,:contact,:service_id,
       :sc_segment_id
    
    config.update.columns.exclude :id

  end
end
