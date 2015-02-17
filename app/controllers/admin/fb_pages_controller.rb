require 'json'
# require 'dhtml_confirm'
# require Rails.root.to_s + '/vendor/plugins/active_scaffold/lib/active_scaffold/data_structures/action_link'

class Admin::FbPagesController < Admin::BaseController
  skip_before_filter :authenticate_user!
  skip_before_filter :is_service_chief?
  
  respond_to :html, :json
  
  active_scaffold :fb_page do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    config.list.sorting = {:post_created_time => :desc}
    
    config.columns = FbPage.columns.map{|a| a.name}
    config.create.columns.exclude :id
    config.update.columns.exclude :id, :post_created_time

    config.actions.exclude :create, :search, :delete
    config.list.per_page = 100

  end
    
end
