class Admin::NetworksController < Admin::BaseController
  
  active_scaffold :network do |config|
    config.create.refresh_list = true
    config.update.refresh_list = true
    config.delete.refresh_list = true
    config.columns = [:id, :name, :description, :is_active,:created_at,:updated_at]
    config.create.columns.exclude :id
    config.update.columns.exclude :id
    # config.actions.exclude :search, :show
    config.list.per_page = 30
  end
  
  protected
   
end
